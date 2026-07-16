using LinearAlgebra
using Statistics

"""
    SCMDiagnosticConfig

Configuration constants used by SCM diagnostic calculations.
"""
Base.@kwdef struct SCMDiagnosticConfig{T<:Real}
    g::T = 9.81
    kappa::T = 0.4
    rho_cp::T = 1200.0
    sigma_sb::T = 5.67e-8
    ri_eps::T = 1.0e-12
    monin_eps::T = 1.0e-10
    bl_threshold_fraction::T = 0.05
    delta_near_tol::T = 1.0e-4
    k_min_surf::T = 1.0e-3
    radiative_floor_margin_k::T = 20.0
end

"""Finite-volume mixing length used by the SCM closure."""
mixing_length(z::Real, l0::Real; kappa::Real=0.4) = (kappa * z) / (1.0 + (kappa * z) / l0)

"""
    compute_face_closure(U, V, theta, T_s, p; cfg=SCMDiagnosticConfig())

Compute face-resolved closure diagnostics from a single state snapshot.
Returns `Km`, `Kh`, `Delta`, `e_xi`, `shear2`, and `Ri_g` on interior faces.
"""
function compute_face_closure(U, V, theta, T_s, p; cfg=SCMDiagnosticConfig())
    N = p.N
    dz = p.dz
    z_faces = p.z_faces
    theta_a = p.theta_a
    delta = p.delta
    K_buoy = p.K_buoy
    beta = p.beta
    l0 = p.l_0
    eta = p.eta
    xi = p.xi
    Pr_t = 1.0

    Km = zeros(eltype(U), N - 1)
    Kh = zeros(eltype(U), N - 1)
    Delta = zeros(eltype(U), N - 1)
    e_xi = zeros(eltype(U), N - 1)
    shear2 = zeros(eltype(U), N - 1)
    Ri_g = zeros(eltype(U), N - 1)

    @inbounds for i in 1:(N - 1)
        dU_dz = (U[i + 1] - U[i]) / dz
        dV_dz = (V[i + 1] - V[i]) / dz
        dth_dz = (theta[i + 1] - theta[i]) / dz

        zf = z_faces[i + 1]
        ell = mixing_length(zf, l0; kappa=cfg.kappa)
        s2 = dU_dz^2 + dV_dz^2
        arg = clamp(beta * dth_dz * ell / theta_a, -40.0, 40.0)
        G = expm1(arg)

        delta_local = eta * (ell^2) * s2 - K_buoy * G
        Q = (l0 * delta_local)^2 - delta
        e_star = 0.5 * (Q + hypot(Q, xi))

        Km[i] = ell * sqrt(e_star + delta)
        Kh[i] = Km[i] / Pr_t
        Delta[i] = delta_local
        e_xi[i] = e_star
        shear2[i] = s2

        buoy = cfg.g * dth_dz / theta_a
        Ri_g[i] = buoy / max(s2, cfg.ri_eps)
    end

    return (Km=Km, Kh=Kh, Delta=Delta, e_xi=e_xi, shear2=shear2, Ri_g=Ri_g)
end

"""
    compute_snapshot_diagnostics(X, p; t=0.0, cfg=SCMDiagnosticConfig())

Compute publication-grade diagnostics for a single SCM snapshot.
"""
function compute_snapshot_diagnostics(X, p; t=0.0, cfg=SCMDiagnosticConfig())
    N = p.N
    dz = p.dz
    z_centers = p.z_centers
    T_s = X[1]
    U = @view X[2:(N + 1)]
    V = @view X[(N + 2):(2N + 1)]
    theta = @view X[(2N + 2):(3N + 1)]

    closure = compute_face_closure(U, V, theta, T_s, p; cfg=cfg)

    delta = p.delta
    l0 = p.l_0
    beta = p.beta
    theta_a = p.theta_a
    eta = p.eta
    K_buoy = p.K_buoy

    # Surface closure uses the same manifold relation as interior faces.
    dU_dz_surf = (U[1] - 0.0) / dz
    dV_dz_surf = (V[1] - 0.0) / dz
    dth_dz_surf = (theta[1] - T_s) / dz
    ell_surf = mixing_length(z_centers[1], l0; kappa=cfg.kappa)
    G_surf = expm1(clamp(beta * dth_dz_surf * ell_surf / theta_a, -40.0, 40.0))
    Delta_surf = eta * (ell_surf^2) * (dU_dz_surf^2 + dV_dz_surf^2) - K_buoy * G_surf
    Q_surf = (l0 * Delta_surf)^2 - delta
    e_surf = 0.5 * (Q_surf + hypot(Q_surf, p.xi))
    # Maintain a smooth background floor in surface exchange coefficients.
    K_m_surf = cfg.k_min_surf + ell_surf * sqrt(e_surf + delta)
    Pr_t = 1.0
    K_h_surf = K_m_surf / Pr_t

    flux_H_surf = K_h_surf * (theta[1] - T_s) / dz
    flux_U_surf = K_m_surf * (U[1] - 0.0) / dz
    flux_V_surf = K_m_surf * (V[1] - 0.0) / dz
    tau_mag = sqrt(flux_U_surf^2 + flux_V_surf^2)
    u_star = sqrt(max(tau_mag, 0.0))

    # Surface energy components.
    R_net = p.R_down - cfg.sigma_sb * (T_s^4)
    H = cfg.rho_cp * flux_H_surf
    G = p.lambda_s * (T_s - p.T_deep) / p.d_soil
    # H is positive downward toward the surface in this SCM, so it contributes
    # to warming the skin layer alongside positive net radiation.
    storage = R_net + H - G
    T_rad = (p.R_down / cfg.sigma_sb)^0.25
    below_radiative_floor = T_s < (T_rad - cfg.radiative_floor_margin_k)

    # Stability diagnostics.
    speed = sqrt.(U .^ 2 .+ V .^ 2)
    speed_sfc = speed[1]
    speed_geo = sqrt(p.Ug^2 + p.Vg^2)
    max_shear = sqrt(maximum(closure.shear2))

    monin_L = -(theta_a * u_star^3) / (cfg.kappa * cfg.g * (flux_H_surf + cfg.monin_eps))
    ri_min = minimum(closure.Ri_g)
    ri_max = maximum(closure.Ri_g)

    km_max = maximum(closure.Km)
    km_threshold = cfg.bl_threshold_fraction * km_max
    bl_idx = findfirst(x -> x < km_threshold, closure.Km)
    bl_depth = isnothing(bl_idx) ? z_centers[end] : z_centers[bl_idx]

    near_fold = abs(Delta_surf - sqrt(delta) / l0) <= cfg.delta_near_tol

    return (
        t=t,
        T_s=T_s,
        theta_surface=theta[1],
        sensible_heat_flux=H,
        ground_heat_flux=G,
        net_radiation=R_net,
        storage=storage,
        radiative_equilibrium_temperature=T_rad,
        below_radiative_floor=below_radiative_floor,
        u_star=u_star,
        boundary_layer_depth=bl_depth,
        ri_min=ri_min,
        ri_max=ri_max,
        monin_obukhov_length=monin_L,
        km_surface=K_m_surf,
        kh_surface=K_h_surf,
        max_shear=max_shear,
        surface_wind_speed=speed_sfc,
        geostrophic_wind=speed_geo,
        surface_delta=Delta_surf,
        surface_e_xi=e_surf,
        near_fold=near_fold,
        U=collect(U),
        V=collect(V),
        theta=collect(theta),
        Km_faces=closure.Km,
        Kh_faces=closure.Kh,
        Delta_faces=closure.Delta,
        e_xi_faces=closure.e_xi,
        shear2_faces=closure.shear2,
        Ri_faces=closure.Ri_g,
    )
end

"""
    compute_time_series_diagnostics(times, states, p; cfg=SCMDiagnosticConfig())

Compute the primary state-evolution diagnostics over a trajectory.
"""
function compute_time_series_diagnostics(times, states, p; cfg=SCMDiagnosticConfig())
    ns = length(states)
    ns == length(times) || error("times and states lengths must match")
    return [compute_snapshot_diagnostics(states[i], p; t=times[i], cfg=cfg) for i in 1:ns]
end

"""
    sample_profile_snapshots(time_series; every_seconds=1800.0)

Downsample diagnostic snapshots for publication profile panels.
"""
function sample_profile_snapshots(time_series; every_seconds=1800.0)
    isempty(time_series) && return NamedTuple[]
    out = NamedTuple[]
    t_next = time_series[1].t
    for row in time_series
        if row.t + 1.0e-9 >= t_next
            push!(out, row)
            t_next += every_seconds
        end
    end
    return out
end

"""
    build_hovmoller_payload(time_series, p)

Prepare arrays for time-height contour plotting.
"""
function build_hovmoller_payload(time_series, p)
    nt = length(time_series)
    nt == 0 && error("time_series cannot be empty")
    N = p.N

    U = zeros(Float64, nt, N)
    V = zeros(Float64, nt, N)
    wind = zeros(Float64, nt, N)
    theta = zeros(Float64, nt, N)

    nf = N - 1
    Km = zeros(Float64, nt, nf)
    Kh = zeros(Float64, nt, nf)
    shear = zeros(Float64, nt, nf)
    Ri = zeros(Float64, nt, nf)
    Delta = zeros(Float64, nt, nf)
    e_xi = zeros(Float64, nt, nf)

    t = zeros(Float64, nt)
    @inbounds for i in 1:nt
        row = time_series[i]
        t[i] = row.t
        U[i, :] .= row.U
        V[i, :] .= row.V
        wind[i, :] .= sqrt.(row.U .^ 2 .+ row.V .^ 2)
        theta[i, :] .= row.theta
        Km[i, :] .= row.Km_faces
        Kh[i, :] .= row.Kh_faces
        shear[i, :] .= sqrt.(max.(row.shear2_faces, 0.0))
        Ri[i, :] .= row.Ri_faces
        Delta[i, :] .= row.Delta_faces
        e_xi[i, :] .= row.e_xi_faces
    end

    return (
        t=t,
        z_centers=collect(p.z_centers),
        z_faces=collect(p.z_faces),
        U=U,
        V=V,
        wind=wind,
        theta=theta,
        Km=Km,
        Kh=Kh,
        shear=shear,
        Ri=Ri,
        Delta=Delta,
        e_xi=e_xi,
    )
end

"""
    compute_numerical_verification(time_series)

Compute numerical-integrity diagnostics from the sampled trajectory.
"""
function compute_numerical_verification(time_series)
    isempty(time_series) && error("time_series cannot be empty")

    km_mins = [minimum(row.Km_faces) for row in time_series]
    km_maxs = [maximum(row.Km_faces) for row in time_series]
    ri_mins = [row.ri_min for row in time_series]
    ri_maxs = [row.ri_max for row in time_series]
    closure_errors = [row.net_radiation + row.sensible_heat_flux - row.ground_heat_flux - row.storage for row in time_series]
    fold_hits = count(row -> row.near_fold, time_series)
    radiative_breach_hits = count(row -> row.below_radiative_floor, time_series)
    min_rad_margin = minimum([row.T_s - row.radiative_equilibrium_temperature for row in time_series])
    kh_surf_min = minimum([row.kh_surface for row in time_series])

    return (
        min_diffusivity=minimum(km_mins),
        max_diffusivity=maximum(km_maxs),
        min_ri=minimum(ri_mins),
        max_ri=maximum(ri_maxs),
        max_surface_energy_closure_error=maximum(abs.(closure_errors)),
        fold_near_fraction=fold_hits / length(time_series),
        radiative_floor_breach_fraction=radiative_breach_hits / length(time_series),
        min_surface_minus_radiative_equilibrium=min_rad_margin,
        min_surface_kh=kh_surf_min,
    )
end

"""
    publication_figure_manifest()

Recommended 8-figure manuscript set aligned with JAS-style SCM reporting.
"""
function publication_figure_manifest()
    return [
        "Time series of T_s, sensible heat flux, and friction velocity",
        "Time-height contour of wind speed with LLJ evolution",
        "Time-height contour of potential temperature and inversion growth",
        "Vertical profiles of U, theta, and Km at representative times",
        "Surface energy budget components (R_n, H, G, storage)",
        "Phase portrait on regularized manifold (Delta vs e_xi)",
        "Eddy diffusivity response (Km, Kh) versus stability/Richardson number",
        "Fold proximity diagnostics versus time",
    ]
end
