#!/usr/bin/env julia
# scripts/plot_4d_diagnostics.jl

using CSV
using DataFrames
using Plots
using Plots.PlotMeasures: mm
using Statistics
using LinearAlgebra
using JSON

function parse_args(args::Vector{String})
    solution_csv = ""
    out_path = "figures/4d_sbl_diagnostics.png"

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--solution" && i < length(args)
            solution_csv = args[i+1]
            i += 2
        elseif arg == "--out" && i < length(args)
            out_path = args[i+1]
            i += 2
        else
            error("Unknown or incomplete argument: $(arg)")
        end
    end

    solution_csv == "" && error("Provide --solution path to solution CSV")
    return solution_csv, out_path
end

solution_csv, out_path = parse_args(ARGS)
df = CSV.read(solution_csv, DataFrame)

U = df.U
V = df.V
Ts = df.Ts
e = df.e
t_hours = df.t ./ 3600.0

# --- Provenance Integration: Extract True Geostrophic Forcing Parameters ---
ug_true = 0.0
vg_true = 0.0
param_found = false
run_dir = dirname(solution_csv)

possible_json_paths = [
    joinpath(run_dir, "run_manifest.json"),
    joinpath(run_dir, "provenance.json"),
    joinpath(run_dir, "summary.json"),
    joinpath(run_dir, "..", "summary.json")
]

for path in possible_json_paths
    if isfile(path)
        try
            data = JSON.parsefile(path)
            # Handle nested parameter summaries or flat configurations
            target_dict = haskey(data, "parameters") ? data["parameters"] : data
            if haskey(target_dict, "U_g")
                ug_true = Float64(target_dict["U_g"])
                param_found = true
            end
            if haskey(target_dict, "V_g")
                vg_true = Float64(target_dict["V_g"])
            end
            if param_found
                ;
                break;
            end
        catch
            # Fall back to next file if parsing fails
        end
    end
end

# If completely isolated from metadata, assume standard rotated forcing alignment
if !param_found
    @warn "No parameter summary JSON located. Falling back to bulk trajectory center estimation."
    ug_true = mean(U[(end-min(40, length(U)-1)):end])
    vg_true = mean(V[(end-min(40, length(V)-1)):end])
end

# Panel 1: Wind Hodograph with true, parameter-locked geostrophic core
p1 = plot(U, V, linewidth=2, color=:black, label="Trajectory", xlabel="U (m s⁻¹)", ylabel="V (m s⁻¹)", title="Wind Hodograph")
scatter!(p1, [ug_true], [vg_true], markersize=7, marker=:star5, color=:gold, linecolor=:black, label="True Geostrophic Forcing")

# Panel 2: TKE and Skin Temp with clean twin y-axis legend separation
p2 = plot(t_hours, e, linewidth=2, color=:blue, label="e(t) [Left]", xlabel="Time (h)", ylabel="TKE (m² s⁻²)", title="TKE and Skin Temperature", legend=:topleft)
p2r = twinx(p2)
plot!(p2r, t_hours, Ts, linewidth=2, color=:red, label="Ts(t) [Right]", ylabel="Ts (K)", legend=:topright)

# --- GSPT Manifold Isolation: Exclude Fast Initial Transient Shock From Fit ---
# Isolate the surface fit to late-time data (last 60% of run hours) where the system is on the slow manifold
late_idx = findall(t_hours .>= (maximum(t_hours) * 0.40))
if isempty(late_idx)
    ;
    late_idx = 1:length(U);
end

U_late = U[late_idx]
V_late = V[late_idx]
Ts_late = Ts[late_idx]

X_late = hcat(ones(length(U_late)), U_late, V_late, U_late .^ 2, U_late .* V_late, V_late .^ 2)
coef = X_late \ Ts_late

# Evaluate surface residuals across the full execution path to show convergence
X_full = hcat(ones(length(U)), U, V, U .^ 2, U .* V, V .^ 2)
Ts_fit_full = X_full * coef
residual = Ts - Ts_fit_full
rmse_late = sqrt(mean(residual[late_idx] .^ 2))

u_min, u_max = extrema(U_late)
v_min, v_max = extrema(V_late)
u_pad = 0.15 * max(abs(u_max - u_min), 1.0)
v_pad = 0.15 * max(abs(v_max - v_min), 1.0)
u_grid = range(u_min - u_pad, u_max + u_pad; length=70)
v_grid = range(v_min - v_pad, v_max + v_pad; length=70)

U_surf = [u for u in u_grid, _ in v_grid]
V_surf = [v for _ in u_grid, v in v_grid]
Ts_surf = [
    coef[1] + coef[2] * u + coef[3] * v + coef[4] * u^2 + coef[5] * u * v + coef[6] * v^2
    for u in u_grid, v in v_grid
]

p3 = surface(
    U_surf,
    V_surf,
    Ts_surf,
    alpha=0.30,
    color=:viridis,
    xlabel="U",
    ylabel="V",
    zlabel="Ts",
    title="Isolated GSPT Slow Manifold Fit",
    bottom_margin=10mm, left_margin=8mm, right_margin=8mm,
    legend=false,
)
plot!(p3, U, V, Ts, linewidth=3, color=:black, label="System Trajectory")

# Panel 4: Residual tracking showing the initial state crashing onto the slow manifold
p4 = plot(
    t_hours,
    residual,
    linewidth=2,
    color=:darkgreen,
    label="Ts Residual",
    xlabel="Time (h)",
    ylabel="Residual (K)",
    title="Manifold Deviation over Time",
    bottom_margin=10mm, left_margin=8mm, right_margin=8mm,
)
hline!(p4, [0.0], color=:black, linestyle=:dash, linewidth=1.5, label="")
vline!(p4, [maximum(t_hours) * 0.40], color=:gray, linestyle=:dot, linewidth=1.5, label="Fit Boundaries")

H = [2.0 * coef[4] coef[5]; coef[5] 2.0 * coef[6]]
eigvals_H = eigvals(H)
annotate!(
    p4,
    maximum(t_hours) * 0.45,
    maximum(residual) * 0.8,
    text(
        "k1=$(round(eigvals_H[1], sigdigits=4))\nk2=$(round(eigvals_H[2], sigdigits=4))\nLate RMSE=$(round(rmse_late, sigdigits=4))",
        :left,
        8,
        :black
    ),
)

layout = @layout [a b; c d]
plt = plot(
    p1, p2, p3, p4;
    layout=layout,
    size=(2000, 1180),
    margin=6mm,
    bottom_margin=12mm,
)

mkpath(dirname(out_path))
savefig(plt, out_path)

println("Diagnostic plot generated successfully.")
println("figure=$(out_path)")