using LinearAlgebra

"""
    _get_face_diffusivity_buffers(p, T, N)

Return preallocated face diffusivity buffers `(Km, Kh)` of length `N-1`.
If unavailable in `p`, fall back to local buffers.
"""
function _get_face_diffusivity_buffers(p, T, N)
    nfaces = N - 1

    if hasproperty(p, :workspace)
        ws = getproperty(p, :workspace)
        if hasproperty(ws, :Km) && hasproperty(ws, :Kh)
            Km = getproperty(ws, :Km)
            Kh = getproperty(ws, :Kh)
            if length(Km) == nfaces && length(Kh) == nfaces
                return Km, Kh
            end
        end
    end

    if hasproperty(p, :K_m_faces) && hasproperty(p, :K_h_faces)
        Km = getproperty(p, :K_m_faces)
        Kh = getproperty(p, :K_h_faces)
        if length(Km) == nfaces && length(Kh) == nfaces
            return Km, Kh
        end
    end

    return Vector{T}(undef, nfaces), Vector{T}(undef, nfaces)
end

"""
    scm_gspt_tendencies!(dX, X, p, t)

In-place ODE RHS function for a vertically resolved Single Column Model (SCM)
using England's regularized C^∞ hyperbolic TKE embedding closures.

State Vector `X` Layout (Size: 3N + 1):
  X[1]         = T_s      (Skin Temperature)
  X[2:N+1]     = U        (Zonal Velocities at cell centers)
  X[N+2:2N+1]  = V        (Meridional Velocities at cell centers)
  X[2N+2:3N+1] = theta    (Potential Temperatures at cell centers)

Notes:
- Turbulence is treated as an algebraic slow-manifold closure (no prognostic TKE state).
- Surface energy budget is intentionally idealized for nocturnal runs (longwave + sensible + ground conduction).
"""
function scm_gspt_tendencies!(dX, X, p, t)
    # 1. Unpack Parameters & Parameters Struct
    N       = p.N       # Number of vertical layers
    dz      = p.dz      # Grid spacing [m]
    z_centers = p.z_centers # Array of cell center heights [m]
    z_faces   = p.z_faces   # Array of cell face heights [m]

    # Physical Consts
    f       = p.f       # Coriolis parameter [s^-1]
    Ug      = p.Ug      # Zonal geostrophic forcing [m s^-1]
    Vg      = p.Vg      # Meridional geostrophic forcing [m s^-1]
    theta_a = p.theta_a # Reference air temperature aloft [K]
    T_deep  = p.T_deep  # Deep soil boundary temperature [K]

    # GSPT Turbulence Internals
    δ       = p.delta   # Background mixing floor parameter [m^2 s^-2]
    K_buoy  = p.K_buoy  # Buoyant destruction scale [m s^-2]
    β       = p.beta    # Stratification sensitivity activation
    l_0     = p.l_0     # Master mixing length ceiling [m]
    η       = p.eta     # Shear production efficiency
    ξ       = p.xi      # Hyperbolic embedding smoothness scale
    kappa   = 0.4       # von Kármán constant
    Pr_t    = 1.0       # Turbulent Prandtl number

    # Land Surface Surface Properties
    C_skin  = p.C_skin  # Thermal capacity of skin layer [J m^-2 K^-1]
    R_down  = p.R_down  # Downward longwave radiative forcing [W m^-2]
    sigma_SB = 5.67e-8  # Stefan-Boltzmann constant
    rho_cp  = 1200.0    # Volumetric heat capacity of air [J m^-3 K^-1]
    lambda_s = p.lambda_s # Soil thermal conductivity [W m^-1 K^-1]
    d_soil  = p.d_soil  # Effective soil layer depth [m]

    # 2. Extract State Views (Zero-Allocation)
    T_s   = X[1]
    U     = @view X[2:N+1]
    V     = @view X[N+2:2N+1]
    theta = @view X[2N+2:3N+1]

    dU     = @view dX[2:N+1]
    dV     = @view dX[N+2:2N+1]
    dtheta = @view dX[2N+2:3N+1]

    # 3. Pre-compute Face Diffusivities using reusable buffers when available
    # Array indices 1 to N-1 correspond to internal cell faces.
    K_m_faces, K_h_faces = _get_face_diffusivity_buffers(p, eltype(X), N)

    for i in 1:(N-1)
        # Spatial gradients evaluated across the interior cell interfaces
        dU_dz = (U[i+1] - U[i]) / dz
        dV_dz = (V[i+1] - V[i]) / dz
        dth_dz = (theta[i+1] - theta[i]) / dz

        # Local mixing length profile model
        z_face = z_faces[i+1] # Face interface sitting between center i and i+1
        ell_z = (kappa * z_face) / (1.0 + (kappa * z_face) / l_0)

        # Exponential Stratification Activation Function G(dth_dz)
        # Modified continuously for localized vertical profile gradients
        stability_arg = clamp(β * dth_dz * ell_z / theta_a, -40.0, 40.0)
        G_local = expm1(stability_arg)

        # Local Net Production-Minus-Buoyancy Metrics Balance (Δ)
        Δ_local = η * (ell_z^2) * (dU_dz^2 + dV_dz^2) - K_buoy * G_local

        # England's Regularized C^∞ Hyperbolic Embedding Engine
        term_affine = l_0 * Δ_local - δ
        e_star_xi = 0.5 * (term_affine + hypot(term_affine, ξ))

        # Evaluate Local Exchange Strengths at Face Interface
        K_m_faces[i] = ell_z * sqrt(e_star_xi + δ)
        K_h_faces[i] = K_m_faces[i] / Pr_t
    end

    # 4. Process Boundary Layer Core Profiles (Interior Cells)
    for i in 2:(N-1)
        # Momentum Divergence (Flux differences across faces)
        flux_U_top = K_m_faces[i]   * (U[i+1] - U[i]) / dz
        flux_U_bot = K_m_faces[i-1] * (U[i] - U[i-1]) / dz

        flux_V_top = K_m_faces[i]   * (V[i+1] - V[i]) / dz
        flux_V_bot = K_m_faces[i-1] * (V[i] - V[i-1]) / dz

        # Heat Flux Divergence
        flux_H_top = K_h_faces[i]   * (theta[i+1] - theta[i]) / dz
        flux_H_bot = K_h_faces[i-1] * (theta[i] - theta[i-1]) / dz

        # Combine with Rotational Coriolis Terms (Skew-Symmetric System Balance)
        dU[i] = f * (V[i] - Vg) + (flux_U_top - flux_U_bot) / dz
        dV[i] = -f * (U[i] - Ug) + (flux_V_top - flux_V_bot) / dz
        dtheta[i] = (flux_H_top - flux_H_bot) / dz
    end

    # 5. Handle Boundary Conditions (Lower Surface Interface, i=1)
    # Use the same manifold closure at the surface to keep wall coupling consistent.
    dU_dz_surf = (U[1] - 0.0) / dz
    dV_dz_surf = (V[1] - 0.0) / dz
    dth_dz_surf = (theta[1] - T_s) / dz

    ell_surf = (kappa * z_centers[1]) / (1.0 + (kappa * z_centers[1]) / l_0)
    stability_arg_surf = clamp(β * dth_dz_surf * ell_surf / theta_a, -40.0, 40.0)
    G_surf = expm1(stability_arg_surf)
    Δ_surf = η * (ell_surf^2) * (dU_dz_surf^2 + dV_dz_surf^2) - K_buoy * G_surf

    A_surf = l_0 * Δ_surf - δ
    e_star_surf = 0.5 * (A_surf + hypot(A_surf, ξ))

    K_m_surf = ell_surf * sqrt(e_star_surf + δ)
    K_h_surf = K_m_surf / Pr_t

    flux_U_surf = K_m_surf * (U[1] - 0.0) / dz # No-slip condition at wall
    flux_V_surf = K_m_surf * (V[1] - 0.0) / dz
    flux_H_surf = K_h_surf * (theta[1] - T_s) / dz

    flux_U_top1 = K_m_faces[1] * (U[2] - U[1]) / dz
    flux_V_top1 = K_m_faces[1] * (V[2] - V[1]) / dz
    flux_H_top1 = K_h_faces[1] * (theta[2] - theta[1]) / dz

    dU[1] = f * (V[1] - Vg) + (flux_U_top1 - flux_U_surf) / dz
    dV[1] = -f * (U[1] - Ug) + (flux_V_top1 - flux_V_surf) / dz
    dtheta[1] = (flux_H_top1 - flux_H_surf) / dz

    # 6. Handle Boundary Conditions (Upper Atmosphere Boundary, i=N)
    # Momentum: zero-flux Neumann condition aloft.
    # Thermodynamics: optional top BC mode via p.theta_top_bc = :neumann | :dirichlet | :relaxation
    theta_top_bc = hasproperty(p, :theta_top_bc) ? getproperty(p, :theta_top_bc) : :neumann
    theta_top_ref = hasproperty(p, :theta_top) ? getproperty(p, :theta_top) : theta_a
    lambda_top = hasproperty(p, :lambda_top) ? getproperty(p, :lambda_top) : 0.0

    flux_H_topN = if theta_top_bc == :dirichlet
        K_h_faces[N-1] * (theta_top_ref - theta[N]) / dz
    elseif theta_top_bc == :relaxation
        -lambda_top * (theta[N] - theta_top_ref)
    else
        0.0
    end

    dU[N] = f * (V[N] - Vg) + (0.0 - K_m_faces[N-1] * (U[N] - U[N-1]) / dz) / dz
    dV[N] = -f * (U[N] - Ug) + (0.0 - K_m_faces[N-1] * (V[N] - V[N-1]) / dz) / dz
    dtheta[N] = (flux_H_topN - K_h_faces[N-1] * (theta[N] - theta[N-1]) / dz) / dz

    # 7. Surface Energy Budget (SEB) Equation Update
    # Compute active components: net radiation, sensible ground heat exchange, deep soil conduction
    R_net = R_down - sigma_SB * (T_s^4)
    H_sensible = rho_cp * flux_H_surf # Sensible heat exchange scaling
    G_ground = lambda_s * (T_s - T_deep) / d_soil

    dX[1] = (1.0 / C_skin) * (R_net - H_sensible - G_ground)

    return nothing
end