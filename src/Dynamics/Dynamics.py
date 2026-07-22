import numpy as np
from scipy.integrate import solve_ivp
import matplotlib.pyplot as plt

# Parameters from default_4d_parameters
U_g = 10.0
V_g = 0.0
T_a = 285.15
theta_top = 285.15
alpha_air = 0.85
T_deep = 283.15
R_down = 260.0
f_coriolis = 1.0e-4
epsilon = 0.01
delta = 1.0e-4
K = 0.32
beta = 15.0
h = 50.0
kappa = 0.40
z0m = 0.05
z0h = 0.01
l0 = 15.0
gamma_eff = 2.0
shear_eff = 15.0
sigma_sb = 5.67e-8
lambda_soil = 1.2
d_soil = 0.5
rho_cp = 1200.0
C_skin = 2.0e4
smooth_eps = 1e-8
g_stability_max = 1.0

log_m = np.log(h / z0m)
log_h = np.log(h / z0h)
C_H = kappa**2 / (log_m * log_h)
gamma = gamma_eff * (kappa**2 / (log_m**2)) / h

print(f"gamma = {gamma}, C_H = {C_H}")

def smooth_max(a, b, eps=1e-3):
    d = a - b
    return 0.5 * (a + b + np.sqrt(d*d + eps*eps))

def smooth_min(a, b, eps=1e-3):
    d = a - b
    return 0.5 * (a + b - np.sqrt(d*d + eps*eps))

def smooth_min_zero(x, eps=1e-10):
    return 0.5 * (x - np.sqrt(x*x + eps*eps))

def smooth_floor_gate(e, e_floor, transition=1e-5):
    return 0.5 * (1.0 + np.tanh((e - e_floor) / transition))

def rhs(t, u):
    e, U, V, Ts = u

    Ts_eff = smooth_min(smooth_max(Ts, 220.0, 1e-3), 350.0, 1e-3)

    e_plus = max(e + delta, smooth_eps)
    sqrt_e = np.sqrt(e_plus)

    arg = beta * (T_a - Ts_eff) / T_a
    G = g_stability_max * np.tanh(arg)

    prod_minus_buoy = shear_eff * gamma * (U**2 + V**2) - K * G
    dissipation = (e_plus**1.5) / l0
    F = sqrt_e * prod_minus_buoy - dissipation

    de_dt_raw = F / epsilon
    e_floor = -delta + smooth_eps
    gate = smooth_floor_gate(e, e_floor, 1e-5)
    neg_part = smooth_min_zero(de_dt_raw, 1e-10)
    de_dt = de_dt_raw - (1.0 - gate) * neg_part

    dU_dt = f_coriolis * (V - V_g) - gamma * sqrt_e * U
    dV_dt = -f_coriolis * (U - U_g) - gamma * sqrt_e * V

    theta_air_eff = alpha_air * Ts_eff + (1.0 - alpha_air) * theta_top
    Rn = R_down - sigma_sb * (Ts_eff**4)
    Gflux = lambda_soil * (Ts_eff - T_deep) / d_soil
    H = rho_cp * C_H * sqrt_e * (Ts_eff - theta_air_eff)
    dTs_dt = (Rn - H - Gflux) / C_skin

    return [de_dt, dU_dt, dV_dt, dTs_dt]

u0 = [1.0, 5.0, 0.0, 285.15]
t_span = (0, 14 * 3600)
sol = solve_ivp(rhs, t_span, u0, method='Radau', max_step=60.0)

print(f"Status: {sol.status}, message: {sol.message}")
print(f"Number of time points: {len(sol.t)}")
print(f"Final e: {sol.y[0,-1]}, U: {sol.y[1,-1]}, V: {sol.y[2,-1]}, Ts: {sol.y[3,-1]}")

# Check min/max of e, U, Ts
print(f"e range: min={np.min(sol.y[0])}, max={np.max(sol.y[0])}")
print(f"U range: min={np.min(sol.y[1])}, max={np.max(sol.y[1])}")
print(f"Ts range: min={np.min(sol.y[3])}, max={np.max(sol.y[3])}")