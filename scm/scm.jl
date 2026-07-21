#!/usr/bin/env julia
# scm/scm.jl
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
    if hasproperty(p, :workspace)
        ws = p.workspace
        if eltype(ws.Km) === T && eltype(ws.Kh) === T
            return ws.Km, ws.Kh
        end
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
Implements Option 2 GSPT Fold Catastrophe with Kolmogorov non-linear dissipation,
C^infty hyperbolic manifold embedding, and Lipschitz activation gate regularization.
Optimized for zero-allocation and maximum SIMD vectorization.
"""
function scm_gspt_tendencies!(dX, X, p, t)
    # 1. Unpack Parameters & Dimensions
    N = p.N
    dz = p.dz
    z_centers = p.z_centers
    z_faces = p.z_faces

    f = p.f
    Ug = p.Ug
    Vg = p.Vg
    theta_a = p.theta_a
    T_deep = p.T_deep

    # GSPT Parameters (Option 2 Fold Geometry)
    δ = p.delta                                # Background mixing offset
    K_buoy = p.K_buoy                         # Buoyancy destruction coupling
    l_0 = p.l_0                               # Master mixing length
    η = p.eta                                 # Shear production efficiency
    ξ = p.xi                                  # Hyperbolic embedding parameter

    # Distinguish GSPT self-amplification (beta_gspt) from thermal stability factor (beta_stab)
    β_gspt = hasproperty(p, :beta_gspt) ? convert(Float64, p.beta_gspt) : (hasproperty(p, :beta) ? convert(Float64, p.beta) : 1.0)
    β_stab = hasproperty(p, :beta_stab) ? convert(Float64, p.beta_stab) : 5.0
    alpha_gate = hasproperty(p, :alpha_gate) ? convert(Float64, p.alpha_gate) : 1.0e-3 # Activation gate scale

    kappa = 0.4
    Pr_t_base = p.pr_t_base
    Pr_t_slope = p.pr_t_slope
    use_dynamic_pr_t = p.use_dynamic_pr_t

    C_skin = p.C_skin
    R_down = p.R_down
    sigma_SB = 5.67e-8
    rho_cp = 1200.0                            # Atmospheric air density * specific heat
    lambda_s = p.lambda_s
    d_soil = p.d_soil
    K_min_surf = p.k_min_surf
    ell_min_surf = p.ell_min_surf
    use_ell_floor_surf = p.use_ell_floor_surf

    # Global interior mixing length floor to ensure a smooth manifold everywhere
    ell_min_interior = hasproperty(p, :ell_min_interior) ? convert(Float64, p.ell_min_interior) : 1.0e-2
    K_min_interior = hasproperty(p, :k_min_interior) ? convert(Float64, p.k_min_interior) : 0.0

    Ts_min = p.ts_min
    Ts_max = p.ts_max

    theta_top_bc = p.theta_top_bc
    theta_top_ref = p.theta_top
    lambda_top = p.lambda_top

    # 2. Extract State Views
    T_s = X[1]
    U = @view X[2:(N+1)]
    V = @view X[(N+2):(2N+1)]
    theta = @view X[(2N+2):(3N+1)]

    dU = @view dX[2:(N+1)]
    dV = @view dX[(N+2):(2N+1)]
    dtheta = @view dX[(2N+2):(3N+1)]

    T = eltype(U)
    K_m_faces, K_h_faces = _get_face_diffusivity_buffers(p, T)

    # 3. Hoist Non-Local H-Scale Configurations
    use_nonlocal = hasproperty(p, :use_nonlocal_h) && p.use_nonlocal_h > 0.5
    h_local = hasproperty(p, :h) ? convert(T, p.h) : convert(T, 100.0)
    h_weight = clamp(hasproperty(p, :nonlocal_h_weight) ? convert(T, p.nonlocal_h_weight) : convert(T, 0.5), zero(T), one(T))
    h_min = hasproperty(p, :nonlocal_h_min) ? convert(T, p.nonlocal_h_min) : convert(T, 20.0)
    h_max = hasproperty(p, :nonlocal_h_max) ? convert(T, p.nonlocal_h_max) : convert(T, 400.0)
    u_floor = hasproperty(p, :nonlocal_velocity_floor) ? convert(T, p.nonlocal_velocity_floor) : convert(T, 0.1)
    f_floor = hasproperty(p, :nonlocal_f_floor) ? convert(T, p.nonlocal_f_floor) : convert(T, 1.0e-5)
    f_eff = max(abs(convert(T, f)), f_floor)

    # 4. Global Smooth Manifold Turbulence Loop (Interior Faces)
    @inbounds @simd for i in 1:(N-1)
        dU_dz = (U[i+1] - U[i]) / dz
        dV_dz = (V[i+1] - V[i]) / dz
        dth_dz = (theta[i+1] - theta[i]) / dz

        z_face = z_faces[i+1]
        ell_neutral = (kappa * z_face) / (one(T) + (kappa * z_face) / l_0)

        h_eff = h_local
        if use_nonlocal
            U_face = 0.5 * (U[i] + U[i+1])
            V_face = 0.5 * (V[i] + V[i+1])
            speed = max(sqrt(U_face^2 + V_face^2), u_floor)
            h_nonlocal = clamp(speed / f_eff, h_min, h_max)
            h_eff = (one(T) - h_weight) * h_local + h_weight * h_nonlocal
        end

        # Global smooth mixing length floor to prevent zero-lockup
        ell_z_raw = ell_neutral * exp(-z_face / h_eff)
        ell_z = sqrt(ell_z_raw^2 + ell_min_interior^2)

        stability_arg = clamp(β_stab * dth_dz * ell_z / theta_a, -40.0, 40.0)
        G_local = expm1(stability_arg)

        # Net Forcing Δ = η * S^2 - K_buoy * G
        S2_local = dU_dz^2 + dV_dz^2
        Δ_local = η * S2_local - K_buoy * G_local

        # Option 2 Fold Catastrophe Equilibrium & C^\infty Hyperbolic Embedding
        D_local = β_gspt^2 + 4.0 * Δ_local
        sqrt_D_reg = sqrt(0.5 * (D_local + sqrt(D_local^2 + ξ^2)))
        H_step = 0.5 * (one(T) + D_local / sqrt(D_local^2 + ξ^2))
        q_star = H_step * 0.5 * l_0 * (β_gspt + sqrt_D_reg)

        # Regularized Lipschitz Activation Gate Psi(tilde_e; alpha)
        tilde_e_star = q_star^2
        psi_gate = sqrt(tilde_e_star) / (sqrt(tilde_e_star) + alpha_gate)

        K_m_faces[i] = K_min_interior + ell_z * sqrt(psi_gate * tilde_e_star + δ)

        Pr_t_local = Pr_t_base
        if use_dynamic_pr_t
            Pr_t_local += Pr_t_slope * tanh(max(zero(T), G_local))
        end
        K_h_faces[i] = K_m_faces[i] / max(Pr_t_local, eps(T))
    end

    # 5. Process Interior Cells (Divergence of downward fluxes)
    @inbounds for i in 2:(N-1)
        flux_U_top = K_m_faces[i] * (U[i+1] - U[i]) / dz
        flux_U_bot = K_m_faces[i-1] * (U[i] - U[i-1]) / dz

        flux_V_top = K_m_faces[i] * (V[i+1] - V[i]) / dz
        flux_V_bot = K_m_faces[i-1] * (V[i] - V[i-1]) / dz

        flux_H_top = K_h_faces[i] * (theta[i+1] - theta[i]) / dz
        flux_H_bot = K_h_faces[i-1] * (theta[i] - theta[i-1]) / dz

        dU[i] = f * (V[i] - Vg) + (flux_U_top - flux_U_bot) / dz
        dV[i] = -f * (U[i] - Ug) + (flux_V_top - flux_V_bot) / dz
        dtheta[i] = (flux_H_top - flux_H_bot) / dz
    end

    # 6. Bottom Boundary Conditions (Fixed Half-Cell Step)
    dz_surf = z_centers[1]
    dU_dz_surf = (U[1] - 0.0) / dz_surf
    dV_dz_surf = (V[1] - 0.0) / dz_surf
    dth_dz_surf = (theta[1] - T_s) / dz_surf

    ell_surf = (kappa * dz_surf) / (one(T) + (kappa * dz_surf) / l_0)

    if use_nonlocal
        speed_surf = max(sqrt(U[1]^2 + V[1]^2), u_floor)
        h_nonlocal_surf = clamp(speed_surf / f_eff, h_min, h_max)
        h_eff_surf = (one(T) - h_weight) * h_local + h_weight * h_nonlocal_surf
    else
        h_eff_surf = h_local
    end
    ell_surf *= exp(-dz_surf / h_eff_surf)
    ell_eff_surf = use_ell_floor_surf ? sqrt(ell_surf^2 + ell_min_surf^2) : ell_surf

    stability_arg_surf = clamp(β_stab * dth_dz_surf * ell_eff_surf / theta_a, -40.0, 40.0)
    G_surf = expm1(stability_arg_surf)

    S2_surf = dU_dz_surf^2 + dV_dz_surf^2
    Δ_surf = η * S2_surf - K_buoy * G_surf

    # Surface Option 2 Fold Geometry & Regularization
    D_surf = β_gspt^2 + 4.0 * Δ_surf
    sqrt_D_reg_surf = sqrt(0.5 * (D_surf + sqrt(D_surf^2 + ξ^2)))
    H_step_surf = 0.5 * (one(T) + D_surf / sqrt(D_surf^2 + ξ^2))
    q_star_surf = H_step_surf * 0.5 * l_0 * (β_gspt + sqrt_D_reg_surf)

    tilde_e_surf = q_star_surf^2
    psi_gate_surf = sqrt(tilde_e_surf) / (sqrt(tilde_e_surf) + alpha_gate)

    K_m_surf = K_min_surf + ell_eff_surf * sqrt(psi_gate_surf * tilde_e_surf + δ)
    Pr_t_surf = Pr_t_base
    if use_dynamic_pr_t
        Pr_t_surf += Pr_t_slope * tanh(max(zero(T), G_surf))
    end
    K_h_surf = K_m_surf / max(Pr_t_surf, eps(T))

    # Surface Anomaly Check
    if T_s < Ts_min || T_s > Ts_max
        reason = T_s < Ts_min ?
                 "Severe radiative cooling decoupling spiral (T_s fell below $(Ts_min) K)." :
                 "Catastrophic thermal runaway / numerical bounce (T_s exceeded $(Ts_max) K)."

        theta_1 = theta[1]
        theta_2 = N >= 2 ? theta[2] : theta[1]
        wind_1 = hypot(U[1], V[1])
        T_rad = (R_down / sigma_SB)^0.25
        state_summary = @sprintf(
            "  - Skin Temp (T_s): %.2f K\n  - Radiative Equilibrium (T_rad): %.2f K\n  - Air Temp (theta_1): %.2f K (z=%.2f m)\n  - Air Temp (theta_2): %.2f K\n  - Wind |V|=%.2f m/s\n  - Surface K_h: %.6f m^2/s",
            T_s, T_rad, theta_1, dz_surf, theta_2, wind_1, K_h_surf
        )
        throw(SurfaceAnomalyException(Float64(t), Float64(T_s), reason, state_summary))
    end

    flux_U_surf = K_m_surf * dU_dz_surf
    flux_V_surf = K_m_surf * dV_dz_surf
    flux_H_surf = K_h_surf * dth_dz_surf # Downward-positive internal flux

    @inbounds begin
        flux_U_top1 = K_m_faces[1] * (U[2] - U[1]) / dz
        flux_V_top1 = K_m_faces[1] * (V[2] - V[1]) / dz
        flux_H_top1 = K_h_faces[1] * (theta[2] - theta[1]) / dz

        dU[1] = f * (V[1] - Vg) + (flux_U_top1 - flux_U_surf) / dz
        dV[1] = -f * (U[1] - Ug) + (flux_V_top1 - flux_V_surf) / dz
        dtheta[1] = (flux_H_top1 - flux_H_surf) / dz

        # 7. Top Boundary Conditions (Fixed Half-Cell Step)
        dz_top = z_faces[N+1] - z_centers[N]
        flux_H_topN = if theta_top_bc === :dirichlet
            K_h_faces[N-1] * (theta_top_ref - theta[N]) / dz_top
        elseif theta_top_bc === :relaxation
            -lambda_top * (theta[N] - theta_top_ref)
        else
            0.0
        end

        dU[N] = f * (V[N] - Vg) + (0.0 - K_m_faces[N-1] * (U[N] - U[N-1]) / dz) / dz
        dV[N] = -f * (U[N] - Ug) + (0.0 - K_m_faces[N-1] * (V[N] - V[N-1]) / dz) / dz
        dtheta[N] = (flux_H_topN - K_h_faces[N-1] * (theta[N] - theta[N-1]) / dz) / dz

        # 8. Surface Energy Balance
        R_net = R_down - sigma_SB * (T_s^4)
        H_upward = rho_cp * K_h_surf * (T_s - theta[1]) / dz_surf
        G_downward = lambda_s * (T_s - T_deep) / d_soil

        dX[1] = (one(T) / C_skin) * (R_net - H_upward - G_downward)
    end

    return nothing
end