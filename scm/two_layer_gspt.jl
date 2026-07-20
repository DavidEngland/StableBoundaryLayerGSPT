#!/usr/bin/env julia
using Plots
include("two_layer_gspt_model.jl")
using .TwoLayerGSPTModel

const SBL_PARAMS = default_parameters()
X0 = default_initial_state()
tspan = (0.0, 3600.0 * 6.0) # Simulate 6 hours of evening transition
sol = simulate_column(SBL_PARAMS, X0, tspan; saveat=300.0)
geom = trajectory_geometry_summary(sol, SBL_PARAMS)

t_hours = sol.t ./ 3600.0
e1_history = [u.e1 for u in sol.u]
Ts_history = [u.Ts for u in sol.u]
e_m0_history = geom.e_eq_history
fold_history = geom.fold_history

p1 = plot(t_hours, e1_history, ylabel="TKE (e1)", xlabel="Time (hours)", label="Fast Dynamics", lw=2)
p2 = plot(Ts_history, e1_history, xlabel="Skin Temp (Ts)", ylabel="TKE (e1)", label="Trajectory Projection", lw=2)
plot!(p2, Ts_history, e_m0_history, label="M₀ Equilibrium", lw=2, ls=:dash)
p3 = plot(t_hours, fold_history, xlabel="Time (hours)", ylabel="∂g/∂e₁", label="Fold Diagnostic", lw=2, color=:black)
plot(p1, p2, p3, layout=(1,3), size=(1200, 400))