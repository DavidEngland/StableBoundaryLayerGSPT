using ComponentArrays  # For clean, named variable access
using DifferentialEquations
using Plots

# ==========================================
# 1. PARAMETERS & HYDRODYNAMIC CLOSURES
# ==========================================
# Named tuple for all physical constants and GSPT scaling
const SBL_PARAMS = (
    # GSPT Timescale separation factor (0 < ε ≪ 1)
    ε = 0.01,

    # Domain & Grid Setup
    Δz = 50.0,         # Bulk layer thickness (m)

    # Core Atmospheric Forcing
    f_cor = 1.0e-4,    # Coriolis parameter (s⁻¹)
    Ug = 8.0,          # Geostrophic wind U (m/s)
    Vg = 0.0,          # Geostrophic wind V (m/s)
    g_over_θ0 = 9.81 / 273.15, # Buoyancy parameter (m/(s²·K))
    γ_θ = 0.01,        # Background tropospheric lapse rate (K/m)

    # Surface Parameters
    C_skin = 10000.0,  # Thermal capacity of skin layer (J/(m²·K))
    R_down = 200.0,    # Downward longwave radiation (W/m²)
    σ_SB = 5.67e-8,    # Stefan-Boltzmann constant
    ρ_air = 1.2,       # Surface air density (kg/m³)
    cp = 1004.0,       # Specific heat of dry air (J/(kg·K))
    λ_s = 0.3,         # Soil thermal conductivity (W/(m·K))
    d_soil = 0.1,      # Soil coupling depth (m)
    T_deep = 270.0,    # Deep soil temperature (K)

    # Transfer & Turbulence Coefficients
    CD = 1.5e-3,       # Bulk drag coefficient for momentum
    CH = 1.5e-3,       # Bulk exchange coefficient for heat
    l_0 = 15.0,        # Master turbulent mixing length (m)

    # Regularization Floor
    δ = 1.0e-4         # Background TKE floor (m²/s²)
)

# ==========================================
# 2. THE 4S + 1F VECTOR FIELD
# ==========================================
function sbl_5d_system!(dX, X, p, t)
    # Unpack state vector seamlessly via ComponentArray labels
    U1, V1, θ1, Ts, e1 = X.U1, X.V1, X.θ1, X.Ts, X.e1

    # Compute the smooth velocity scale parameter (No square-root singularity!)
    vel_scale = sqrt(e1 + p.δ)

    # Local Eddy Diffusivities as functions of the fast TKE variable
    K_m = p.l_0 * vel_scale
    K_h = p.l_0 * vel_scale # Assuming Prandtl number = 1 for simplicity

    # --- SLOW EQUATIONS (f) ---
    # Zonal Momentum (dU1/dt)
    dX.U1 = p.f_cor * (V1 - p.Vg) + (1.0 / p.Δz) * (K_m * (p.Ug - U1) / p.Δz - p.CD * vel_scale * U1)

    # Meridional Momentum (dV1/dt)
    dX.V1 = -p.f_cor * (U1 - p.Ug) + (1.0 / p.Δz) * (K_m * (p.Vg - V1) / p.Δz - p.CD * vel_scale * V1)

    # Potential Temperature (dθ1/dt)
    dX.θ1 = (1.0 / p.Δz) * (K_h * p.γ_θ - p.CH * vel_scale * (θ1 - Ts))

    # Skin Layer Energy Budget (dTs/dt)
    sensible_heat = p.ρ_air * p.cp * p.CH * vel_scale * (Ts - θ1)
    ground_flux = p.λ_s * (Ts - p.T_deep) / p.d_soil
    dX.Ts = (1.0 / p.C_skin) * (p.R_down - p.σ_SB * Ts^4 - sensible_heat - ground_flux)

    # --- FAST EQUATION (g) ---
    # Shear production
    shear = K_m * (((p.Ug - U1) / p.Δz)^2 + ((p.Vg - V1) / p.Δz)^2)
    # Buoyancy destruction (using background lapse rate as proxy for upper layer coupling)
    buoyancy = K_h * p.g_over_θ0 * p.γ_θ
    # Viscous dissipation
    dissipation = (e1 + p.δ)^(1.5) / p.l_0

    # TKE Evolution explicitly scaled by 1/ε
    dX.e1 = (1.0 / p.ε) * (shear - buoyancy - dissipation)

    return nothing
end

# ==========================================
# 3. EXECUTION AND SOLVER SELECTION
# ==========================================
# Define initial conditions (Start slightly off the critical manifold)
X0 = ComponentArray(U1=4.0, V1=1.0, θ1=275.0, Ts=272.0, e1=0.5)
tspan = (0.0, 3600.0 * 6.0) # Simulate 6 hours of evening transition

prob = ODEProblem(sbl_5d_system!, X0, tspan, SBL_PARAMS)

# Use Rosenbrock23 or Rodas4: Highly optimized for stiff, multi-timescale systems
sol = solve(prob, Rosenbrock23(), reltol=1e-6, abstol=1e-8)

# ==========================================
# 4. PLOTTING THE PHASE SPACE TRAJECTORY
# ==========================================
# Extract timeseries
t_hours = sol.t ./ 3600.0
e1_history = [u.e1 for u in sol.u]
Ts_history = [u.Ts for u in sol.u]

p1 = plot(t_hours, e1_history, ylabel="TKE (e1)", xlabel="Time (hours)", label="Fast Dynamics", lw=2)
p2 = plot(Ts_history, e1_history, xlabel="Skin Temp (Ts)", ylabel="TKE (e1)", label="Trajectory Projection", lw=2)
plot(p1, p2, layout=(1,2), size=(900, 400))