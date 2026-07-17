using LinearAlgebra
using Printf

struct SurfaceAnomalyException <: Exception
    t::Float64
    Ts::Float64
    reason::String
    state_summary::String
end

function Base.showerror(io::IO, e::SurfaceAnomalyException)
    print(io, "SurfaceAnomalyException: Simulation aborted at t = $(round(e.t / 3600.0, digits=2)) hours.\n")
    print(io, "  Surface Temperature (T_s) = $(round(e.Ts, digits=2)) K breached physical limits!\n")
    print(io, "  Reason: $(e.reason)\n")
    print(io, "  Column State at failure:\n$(e.state_summary)")
end

# Enforce preallocated workspace check at startup, not inside RHS loop
function _get_face_diffusivity_buffers(p, T)
    # We assume p has a workspace or direct fields.
    # If they are missing, we fail loudly *before* the solver runs.
    if hasproperty(p, :workspace)
        ws = p.workspace
        if eltype(ws.Km) === T && eltype(ws.Kh) === T
            return ws.Km, ws.Kh
        end
        # Jacobian autodiff may require Dual-valued temporaries; keep baseline
        # zero-allocation path for Float64 runtime via the branch above.
        return Vector{T}(undef, length(ws.Km)), Vector{T}(undef, length(ws.Kh))
    elseif hasproperty(p, :K_m_faces) && hasproperty(p, :K_h_faces)
        if eltype(p.K_m_faces) === T && eltype(p.K_h_faces) === T
            return p.K_m_faces, p.K_h_faces
        end
        return Vector{T}(undef, length(p.K_m_faces)), Vector{T}(undef, length(p.K_h_faces))
    else
        error("Performance Error: No preallocated face diffusivity buffers found in parameter struct 'p'. Please initialize p.workspace.Km and p.workspace.Kh.")
    end
end

function _effective_h_scale(p, U_ref::Real, V_ref::Real)
    T = promote_type(typeof(U_ref), typeof(V_ref), typeof(p.f))
    h_local = hasproperty(p, :h) ? convert(T, p.h) : convert(T, 100.0)
    use_nonlocal = hasproperty(p, :use_nonlocal_h) && p.use_nonlocal_h > 0.5
    if !use_nonlocal
        return h_local
    end

    weight = clamp(
        hasproperty(p, :nonlocal_h_weight) ? convert(T, p.nonlocal_h_weight) : convert(T, 0.5),
        zero(T),
        one(T),
    )
    h_min = hasproperty(p, :nonlocal_h_min) ? convert(T, p.nonlocal_h_min) : convert(T, 20.0)
    h_max = hasproperty(p, :nonlocal_h_max) ? convert(T, p.nonlocal_h_max) : convert(T, 400.0)
    u_floor = hasproperty(p, :nonlocal_velocity_floor) ? convert(T, p.nonlocal_velocity_floor) : convert(T, 0.1)
    f_floor = hasproperty(p, :nonlocal_f_floor) ? convert(T, p.nonlocal_f_floor) : convert(T, 1.0e-5)

    speed = max(sqrt(U_ref * U_ref + V_ref * V_ref), u_floor)
    f_eff = max(abs(convert(T, p.f)), f_floor)
    h_nonlocal = clamp(speed / f_eff, h_min, h_max)
    return (one(T) - weight) * h_local + weight * h_nonlocal
end

"""
    scm_gspt_tendencies!(dX, X, p, t)

In-place ODE RHS function for a vertically resolved Single Column Model (SCM).
Optimized for zero-allocation and maximum SIMD vectorization.
"""
function scm_gspt_tendencies!(dX, X, p, t)
    # 1. Unpack Parameters (Avoid dynamic dispatch by using typed fields where possible)
    N = p.N
    dz = p.dz
    z_centers = p.z_centers
    z_faces = p.z_faces

    # Physical Constants
    f = p.f
    Ug = p.Ug
    Vg = p.Vg
    theta_a = p.theta_a
    T_deep = p.T_deep

    # GSPT Turbulence Internals
    δ = p.delta
    K_buoy = p.K_buoy
    β = p.beta
    l_0 = p.l_0
    η = p.eta
    ξ = p.xi
    kappa = 0.4
    Pr_t = 1.0

    # Land Surface Properties
    C_skin = p.C_skin
    R_down = p.R_down
    sigma_SB = 5.67e-8
    rho_cp = 1200.0
    lambda_s = p.lambda_s
    d_soil = p.d_soil
    K_min_surf = hasproperty(p, :k_min_surf) ? p.k_min_surf : 1.0e-3
    Ts_min = hasproperty(p, :ts_min) ? p.ts_min : 180.0
    Ts_max = hasproperty(p, :ts_max) ? p.ts_max : 350.0

    # Extract optional BC configuration once (avoid hasproperty checks in hot code)
    # Ideally, define these strictly on p's type so they resolve at compile time.
    theta_top_bc = p.theta_top_bc # Expecting a Symbol: :neumann, :dirichlet, or :relaxation
    theta_top_ref = p.theta_top
    lambda_top = p.lambda_top

    # 2. Extract State Views (Zero-Allocation)
    T_s = X[1]
    U = @view X[2:(N+1)]
    V = @view X[(N+2):(2N+1)]
    theta = @view X[(2N+2):(3N+1)]

    dU = @view dX[2:(N+1)]
    dV = @view dX[(N+2):(2N+1)]
    dtheta = @view dX[(2N+2):(3N+1)]

    # 3. Retrieve preallocated buffers (zero-allocation)
    K_m_faces, K_h_faces = _get_face_diffusivity_buffers(p, eltype(U))

    # 4. Turbulence Closure Loop
    @inbounds @simd for i in 1:(N-1)
        # Spatial gradients across interior interfaces
        dU_dz = (U[i+1] - U[i]) / dz
        dV_dz = (V[i+1] - V[i]) / dz
        dth_dz = (theta[i+1] - theta[i]) / dz

        # Local mixing length profile (with physical decay aloft)
        z_face = z_faces[i+1]

        # Blackadar length scale
        ell_neutral = (kappa * z_face) / (1.0 + (kappa * z_face) / l_0)

        # Damp mixing length aloft to let the free atmosphere decouple
        # (e.g., using a standard boundary layer scale or vertical decay)
        U_face = 0.5 * (U[i] + U[i+1])
        V_face = 0.5 * (V[i] + V[i+1])
        h_eff = _effective_h_scale(p, U_face, V_face)
        decay_factor = exp(-z_face / h_eff)
        ell_z = ell_neutral * decay_factor

        # Exponential Stratification Activation
        stability_arg = clamp(β * dth_dz * ell_z / theta_a, -40.0, 40.0)
        G_local = expm1(stability_arg)

        # Local Net Production-Minus-Buoyancy (CORRECTED UNITS: scaled by ell_z)
        Δ_local = η * (ell_z^2) * (dU_dz^2 + dV_dz^2) - K_buoy * ell_z * G_local

        # England's Regularized C^∞ Hyperbolic Embedding Engine
        term_quadratic = (l_0 * Δ_local)^2 - δ
        e_star_xi = 0.5 * (term_quadratic + hypot(term_quadratic, ξ))

        # Evaluate Local Exchange Strengths
        K_m_faces[i] = ell_z * sqrt(e_star_xi + δ)
        K_h_faces[i] = K_m_faces[i] / Pr_t
    end

    # 5. Process Interior Cells (Divergence of fluxes)
    @inbounds for i in 2:(N-1)
        # Momentum Divergence
        flux_U_top = K_m_faces[i] * (U[i+1] - U[i]) / dz
        flux_U_bot = K_m_faces[i-1] * (U[i] - U[i-1]) / dz

        flux_V_top = K_m_faces[i] * (V[i+1] - V[i]) / dz
        flux_V_bot = K_m_faces[i-1] * (V[i] - V[i-1]) / dz

        # Heat Flux Divergence
        flux_H_top = K_h_faces[i] * (theta[i+1] - theta[i]) / dz
        flux_H_bot = K_h_faces[i-1] * (theta[i] - theta[i-1]) / dz

        # Dynamics Update
        dU[i] = f * (V[i] - Vg) + (flux_U_top - flux_U_bot) / dz
        dV[i] = -f * (U[i] - Ug) + (flux_V_top - flux_V_bot) / dz
        dtheta[i] = (flux_H_top - flux_H_bot) / dz
    end

    # 6. Bottom Boundary Conditions (i = 1)
    dU_dz_surf = (U[1] - 0.0) / dz
    dV_dz_surf = (V[1] - 0.0) / dz
    dth_dz_surf = (theta[1] - T_s) / dz

    ell_surf = (kappa * z_centers[1]) / (1.0 + (kappa * z_centers[1]) / l_0)
    h_eff_surf = _effective_h_scale(p, U[1], V[1])
    ell_surf *= exp(-z_centers[1] / h_eff_surf)
    stability_arg_surf = clamp(β * dth_dz_surf * ell_surf / theta_a, -40.0, 40.0)
    G_surf = expm1(stability_arg_surf)
    Δ_surf = η * (ell_surf^2) * (dU_dz_surf^2 + dV_dz_surf^2) - K_buoy * G_surf

    Q_surf = (l_0 * Δ_surf)^2 - δ
    e_star_surf = 0.5 * (Q_surf + hypot(Q_surf, ξ))

    # Smooth nonzero background transport at the surface. This preserves coupling
    # even when ell_surf -> 0 and e_star_surf -> 0.
    K_m_surf = K_min_surf + ell_surf * sqrt(e_star_surf + δ)
    K_h_surf = K_m_surf / Pr_t

    if T_s < Ts_min || T_s > Ts_max
        reason = if T_s < Ts_min
            "Severe radiative cooling decoupling spiral (T_s fell below $(Ts_min) K)."
        else
            "Catastrophic thermal runaway / numerical bounce (T_s exceeded $(Ts_max) K)."
        end

        theta_1 = theta[1]
        theta_2 = N >= 2 ? theta[2] : theta[1]
        u_1 = U[1]
        v_1 = V[1]
        wind_1 = hypot(u_1, v_1)
        T_rad = (R_down / sigma_SB)^0.25
        state_summary = @sprintf(
            "  - Skin Temp (T_s): %.2f K\n  - Radiative Equilibrium (T_rad): %.2f K\n  - Air Temp (theta_1): %.2f K (z=%.2f m)\n  - Air Temp (theta_2): %.2f K\n  - Wind (U_1,V_1): (%.2f, %.2f) m/s | |V|=%.2f m/s\n  - Surface K_h: %.6f m^2/s",
            T_s,
            T_rad,
            theta_1,
            z_centers[1],
            theta_2,
            u_1,
            v_1,
            wind_1,
            K_h_surf,
        )
        throw(SurfaceAnomalyException(Float64(t), Float64(T_s), reason, state_summary))
    end

    flux_U_surf = K_m_surf * (U[1] - 0.0) / dz
    flux_V_surf = K_m_surf * (V[1] - 0.0) / dz
    flux_H_surf = K_h_surf * (theta[1] - T_s) / dz

    @inbounds begin
        flux_U_top1 = K_m_faces[1] * (U[2] - U[1]) / dz
        flux_V_top1 = K_m_faces[1] * (V[2] - V[1]) / dz
        flux_H_top1 = K_h_faces[1] * (theta[2] - theta[1]) / dz

        dU[1] = f * (V[1] - Vg) + (flux_U_top1 - flux_U_surf) / dz
        dV[1] = -f * (U[1] - Ug) + (flux_V_top1 - flux_V_surf) / dz
        dtheta[1] = (flux_H_top1 - flux_H_surf) / dz

        # 7. Top Boundary Conditions (i = N)
        flux_H_topN = if theta_top_bc === :dirichlet
            K_h_faces[N-1] * (theta_top_ref - theta[N]) / dz
        elseif theta_top_bc === :relaxation
            -lambda_top * (theta[N] - theta_top_ref)
        else # Defaulting to :neumann
            0.0
        end

        dU[N] = f * (V[N] - Vg) + (0.0 - K_m_faces[N-1] * (U[N] - U[N-1]) / dz) / dz
        dV[N] = -f * (U[N] - Ug) + (0.0 - K_m_faces[N-1] * (V[N] - V[N-1]) / dz) / dz
        dtheta[N] = (flux_H_topN - K_h_faces[N-1] * (theta[N] - theta[N-1]) / dz) / dz

        # 8. Surface Energy Budget Update
        R_net = R_down - sigma_SB * (T_s^4)
        H_sensible = rho_cp * flux_H_surf
        G_ground = lambda_s * (T_s - T_deep) / d_soil

        # flux_H_surf is defined positive downward toward the surface, so it
        # warms the skin layer when the first atmospheric level is warmer.
        dX[1] = (1.0 / C_skin) * (R_net + H_sensible - G_ground)

        # Optional runtime diagnostics for SEB runaway detection.
        if hasproperty(p, :debug_print) && p.debug_print && hasproperty(p, :profile_every)
            profile_every = p.profile_every
            if profile_every > 0
                phase = mod(t, profile_every)
                at_print_step = (phase < 1.0e-9) || ((profile_every - phase) < 1.0e-9)
                if at_print_step
                    T_rad = (R_down / sigma_SB)^0.25
                    @printf(
                        "t=%7.1f | Ts=%6.2f K | Trad=%6.2f K | Rnet=%7.2f W/m^2 | H=%7.2f W/m^2 | G=%7.2f W/m^2 | Kh_surf=%9.6f\n",
                        t,
                        T_s,
                        T_rad,
                        R_net,
                        H_sensible,
                        G_ground,
                        K_h_surf,
                    )
                    if T_s < (T_rad - 20.0)
                        @warn "Physical anomaly: T_s has dropped more than 20 K below radiative equilibrium floor."
                    end
                end
            end
        end
    end

    return nothing
end