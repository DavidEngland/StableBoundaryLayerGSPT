using DifferentialEquations
using LinearAlgebra
using ForwardDiff

# ====================================================================
# 1. Physical and Numerical Parameters (Active Baseline)
# ====================================================================
const Ug = 10.0            # Zonal geostrophic wind (m/s)
const Vg = 0.0             # Meridional geostrophic wind (m/s)
const Ta = 285.15          # Reference air temperature (K)
const Tdeep = 283.15       # Deep soil/ice core temperature (K)
const Rdown = 260.0        # Downward longwave radiation (W/m^2)
const f_cor = 0.0001       # Coriolis parameter (s^-1)

const epsilon = 0.01       # Fast-slow timescale ratio (eps << 1)
const delta = 0.0001       # Background TKE floor (m^2/s^2)
const K_buoy = 0.32        # Buoyant destruction scale (m/s^2)
const beta_T = 15.0        # Thermal stability sensitivity in G(Ts)
const sigma_e = 15.0       # Fast linear TKE term
const h_bl = 50.0          # Boundary layer bulk scale height (m)
const h_min = 20.0         # Lower bound for emergent h_eff (m)
const h_max = 400.0        # Upper bound for emergent h_eff (m)
const l0 = 15.0            # Master turbulent mixing length (m)
const gamma = 1.4e-3       # Effective momentum drag scaling (s^-1)
const CH = 1.2e-3          # Thermal exchange coefficient
const eta = 1.5            # Shear production efficiency

const sigma_SB = 5.67e-8   # Stefan-Boltzmann constant (W/m^2/K^4)
const lambda = 1.2         # Soil/Ice thermal conductivity (W/m/K)
const d_soil = 0.5         # Soil coupling depth (m)
const rho_cp = 1200.0      # Volumetric heat capacity of air (J/m^3/K)
const C_skin = 20000.0     # Thermal capacity of skin layer (J/m^2/K)

# Numerical Safeguard Parameters
const alpha_safe = 1.0e-6  # Damping scale for the safeguard floor gate
const ts_min = 220.0       # Validated physical Arctic surface floor (K)

# ====================================================================
# 2. Vector Field Definition (AD-Safe, Type-Generic Structure)
# ====================================================================
function gspt_sbl_dynamics!(dx, x, p, t)
    # State mapping: x = [e, U, V, Ts]
    e = x[1]
    U = x[2]
    V = x[3]
    Ts = max(x[4], ts_min) # Apply physical safety floor inline

    # Shifted TKE coordinate
    phi = e + delta

    # Emergent effective boundary-layer height with runtime clamp
    vel_ratio = sqrt(U^2 + V^2 + 1.0e-6) / max(Ug, 1.0e-6)
    h_eff = clamp(h_bl * vel_ratio, h_min, h_max)
    gamma_eff = gamma * (h_bl / h_eff)

    # 2.1 Smooth Safeguard Floor Gate
    # +1.0e-15 prevents NaN dual-number derivatives
    # from the 1/(2*sqrt(phi)) singular limit at phi = 0.
    psi = sqrt(phi + 1.0e-15) / (sqrt(phi + 1.0e-15) + alpha_safe)

    # 2.2 Physical Auxiliary Functions
    # Bounded tanh stability response prevents runaway buoyancy growth
    G_Ts = tanh(beta_T * (Ta - Ts) / Ta)

    # Net mechanical production minus buoyancy balance
    shear_prod = eta * gamma_eff * (U^2 + V^2)
    buoy_dest = K_buoy * G_Ts
    Delta = shear_prod - buoy_dest

    # C^inf coordinate shifting avoids non-differentiable max() gates
    # and prevents derivative blowup in ForwardDiff.Dual components
    sqrt_phi_reg = sqrt(phi + 1.0e-15)

    # Surface Energy Budget Terms
    Rn = Rdown - sigma_SB * (Ts^4)
    H = rho_cp * CH * sqrt_phi_reg * (Ts - Ta)
    G = lambda * (Ts - Tdeep) / d_soil

    # 2.3 Evaluated Tendencies
    # Fast TKE Equation: activated production + non-linear dissipation
    dx[1] = (1.0 / epsilon) * (l0 * Delta * phi * psi + sigma_e * phi - (phi^(3/2)) / l0)

    # Slow Momentum and Thermodynamic Equations
    dx[2] = f_cor * (V - Vg) - gamma_eff * sqrt_phi_reg * U
    dx[3] = -f_cor * (U - Ug) - gamma_eff * sqrt_phi_reg * V
    dx[4] = (1.0 / C_skin) * (Rn - H - G)

    return nothing
end

# ====================================================================
# 3. Solver Execution and Integration Setup
# ====================================================================
# Initial Conditions: Cold active Arctic boundary layer
x0 = [0.05, 5.0, -1.0, 250.0]
tspan = (0.0, 43200.0) # Full 12-hour production window

prob = ODEProblem(gspt_sbl_dynamics!, x0, tspan)

# Solve using Rodas5P (5th order A-L-stable Rosenbrock method with AD)
sol = solve(prob, Rodas5P(autodiff=true), reltol=1.0e-6, abstol=1.0e-8)
