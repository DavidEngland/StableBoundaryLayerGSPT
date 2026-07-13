#!/usr/bin/env julia

using CSV
using DataFrames
using Plots
using Statistics
using LinearAlgebra

function parse_args(args::Vector{String})
    solution_csv = ""
    out_path = "figures/4d_sbl_diagnostics.png"

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--solution" && i < length(args)
            solution_csv = args[i + 1]
            i += 2
        elseif arg == "--out" && i < length(args)
            out_path = args[i + 1]
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

# Panel 1: Hodograph with geostrophic reference from late-time mean.
Ug_ref = mean(U[end-min(20, length(U)-1):end])
Vg_ref = mean(V[end-min(20, length(V)-1):end])
p1 = plot(U, V, linewidth=2, label="Trajectory", xlabel="U (m s^-1)", ylabel="V (m s^-1)", title="Wind Hodograph")
scatter!(p1, [Ug_ref], [Vg_ref], markersize=5, marker=:star5, label="Geostrophic core")

# Panel 2: e(t) and Ts(t) with twin y-axis style via overlay.
p2 = plot(t_hours, e, linewidth=2, color=:blue, label="e(t)", xlabel="Time (h)", ylabel="TKE (m^2 s^-2)", title="TKE and Skin Temperature")
p2r = twinx(p2)
plot!(p2r, t_hours, Ts, linewidth=2, color=:red, label="Ts(t)", ylabel="Ts (K)")

# Panel 3: 3D trajectory with fitted elliptic paraboloid geometry.
# Fit Ts(U,V) = c0 + c1 U + c2 V + c3 U^2 + c4 UV + c5 V^2.
X = hcat(ones(length(U)), U, V, U .^ 2, U .* V, V .^ 2)
coef = X \ Ts
Ts_fit = X * coef
residual = Ts - Ts_fit

u_min, u_max = extrema(U)
v_min, v_max = extrema(V)
u_pad = 0.08 * max(abs(u_max - u_min), 1.0)
v_pad = 0.08 * max(abs(v_max - v_min), 1.0)
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
    alpha=0.35,
    color=:lightgray,
    label="",
    xlabel="U",
    ylabel="V",
    zlabel="Ts",
    title="3D Elliptic Paraboloid Fit",
    legend=false,
)
plot!(p3, U, V, Ts, linewidth=3, color=:black, label="")

# Panel 4: Residual diagnostics and curvature summary.
p4 = scatter(
    t_hours,
    residual,
    markersize=3,
    alpha=0.7,
    color=:darkgreen,
    label="Ts - Ts_fit",
    xlabel="Time (h)",
    ylabel="Residual (K)",
    title="Quadratic Fit Residuals",
)
hline!(p4, [0.0], color=:black, linestyle=:dash, linewidth=1.5, label="")

# Hessian of the quadratic form gives principal curvatures in U-V coordinates.
H = [2.0 * coef[4] coef[5]; coef[5] 2.0 * coef[6]]
eigvals_H = eigvals(H)
rmse = sqrt(mean(residual .^ 2))
annotate!(
    p4,
    t_hours[1],
    maximum(residual),
    text(
        "k1=$(round(eigvals_H[1], sigdigits=4)), k2=$(round(eigvals_H[2], sigdigits=4)), RMSE=$(round(rmse, sigdigits=4))",
        :left,
        8,
    ),
)

layout = @layout [a b; c d]
plt = plot(p1, p2, p3, p4; layout=layout, size=(1800, 980))
mkpath(dirname(out_path))
savefig(plt, out_path)

println("Diagnostic plot generated")
println("figure=$(out_path)")