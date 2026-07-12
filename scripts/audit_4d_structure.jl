#!/usr/bin/env julia

using JSON3
using StableBoundaryLayerGSPT.Dynamics

function central_diff(f, x; h=1.0e-6)
    return (f(x + h) - f(x - h)) / (2 * h)
end

params = default_4d_parameters()
gamma, C_H = closure_coefficients(params)
floors = diagnostic_diffusivity_floors(params)

# Construct Ts so Delta is close to zero for a representative wind speed.
U = 6.0
V = 0.0
Ta = params["T_a"]
beta = params["beta"]
K = params["K"]

G_target = gamma * (U^2 + V^2) / K
Ts_balance = Ta - (Ta / beta) * log(1.0 + G_target)

Delta_balance = gamma * (U^2 + V^2) - K * stratification_function(Ts_balance, Ta, beta)
F_balance = fast_vector_field_F(0.0, U, V, Ts_balance, params)

# Hyperbolicity proxy: derivative of F wrt e near laminar edge should be finite.
f_e = e -> fast_vector_field_F(e, U, V, Ts_balance, params)
dF_de = central_diff(f_e, 0.0)

# Diffusivity floor checks at e = 0.
sol_floor_rows = solution_to_rows((; t=[0.0], u=[[0.0, U, V, Ts_balance]]), params)
Km0 = sol_floor_rows[1].Km
Kh0 = sol_floor_rows[1].Kh

audit = Dict(
    "delta_balance" => Delta_balance,
    "Ts_balance" => Ts_balance,
    "F_at_balance" => F_balance,
    "dF_de_at_e0" => dF_de,
    "gamma" => gamma,
    "C_H" => C_H,
    "Km_at_e0" => Km0,
    "Kh_at_e0" => Kh0,
    "Km_floor_expected" => floors["Km_floor"],
    "Kh_floor_expected" => floors["Kh_floor"],
    "checks" => Dict(
        "delta_near_zero" => abs(Delta_balance) <= 1.0e-9,
        "finite_dF_de" => isfinite(dF_de),
        "Km_has_floor" => Km0 >= 0.999 * floors["Km_floor"],
        "Kh_has_floor" => Kh0 >= 0.999 * floors["Kh_floor"],
    ),
)

all_ok = all(values(audit["checks"]))
println("Structural audit complete: all_ok=$(all_ok)")
for (k, v) in sort(collect(audit["checks"]))
    println("  $(k) = $(v)")
end

mkpath("results/4d_sbl")
out_path = joinpath("results/4d_sbl", "structure_audit.json")
open(out_path, "w") do io
    JSON3.pretty(io, audit)
end
println("audit_json=$(out_path)")

if !all_ok
    error("4D structure audit failed. Inspect $(out_path).")
end