#!/usr/bin/env julia
# scripts/plot_blackadar_hodograph_sc.jl
# Blackadar hodograph with dynamic critical wind radius S_c(T_s).

using CSV
using DataFrames
using JSON
using Plots
using Statistics

function usage()
    println("Usage: julia scripts/plot_blackadar_hodograph_sc.jl [options]")
    println("Options:")
    println("  --datasets <csv>      Dataset list (default: CASES99,FLOSS)")
    println("  --root <path>         Root results directory (default: results)")
    println("  --out <path>          Output figure path")
end

function parse_args(args::Vector{String})
    datasets = ["CASES99", "FLOSS"]
    root = "results"
    out = joinpath("reports", "generated", "figures", "blackadar_hodograph_critical_radius.png")

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--datasets" && i < length(args)
            datasets = split(args[i + 1], ',')
            i += 2
        elseif arg == "--root" && i < length(args)
            root = args[i + 1]
            i += 2
        elseif arg == "--out" && i < length(args)
            out = args[i + 1]
            i += 2
        elseif arg == "--help"
            usage()
            exit(0)
        else
            error("Unknown or incomplete argument: $(arg)")
        end
    end

    return datasets, root, out
end

function effective_h_scale(U::Float64, V::Float64, p::Dict{String,Any})
    h_local = Float64(p["h"])
    use_nonlocal = Float64(get(p, "use_nonlocal_h", 0.0)) > 0.5
    if !use_nonlocal
        return h_local
    end

    weight = clamp(Float64(get(p, "nonlocal_h_weight", 0.5)), 0.0, 1.0)
    h_min = Float64(get(p, "nonlocal_h_min", 20.0))
    h_max = Float64(get(p, "nonlocal_h_max", 400.0))
    u_floor = Float64(get(p, "nonlocal_velocity_floor", 0.1))
    f_floor = Float64(get(p, "nonlocal_f_floor", 1.0e-5))

    speed = max(hypot(U, V), u_floor)
    f_eff = max(abs(Float64(p["f_coriolis"])), f_floor)
    h_nonlocal = clamp(speed / f_eff, h_min, h_max)
    return (1.0 - weight) * h_local + weight * h_nonlocal
end

function closure_gamma(U::Float64, V::Float64, p::Dict{String,Any})
    kappa = Float64(p["kappa"])
    z0m = Float64(p["z0m"])
    gamma_efficiency = Float64(get(p, "gamma_efficiency", 1.0))
    h_eff = effective_h_scale(U, V, p)
    log_m = log(h_eff / z0m)
    return gamma_efficiency * (kappa^2 / (log_m^2)) / h_eff
end

function stability_response(Ts::Float64, p::Dict{String,Any})
    Ta = Float64(p["T_a"])
    beta = Float64(p["beta"])
    return tanh(beta * (Ta - Ts) / Ta)
end

function load_dataset(dataset::AbstractString, root::AbstractString)
    run_dir = joinpath(String(root), String(dataset), "latest")
    csv_path = joinpath(run_dir, "solution.csv")
    summary_path = joinpath(run_dir, "summary.json")

    isfile(csv_path) || error("Missing file: $(csv_path)")
    isfile(summary_path) || error("Missing file: $(summary_path)")

    df = CSV.read(csv_path, DataFrame)
    summary = JSON.parsefile(summary_path)
    p = Dict{String,Any}(summary["parameters"])

    U = Float64.(df.U)
    V = Float64.(df.V)
    Ts = Float64.(df.Ts)
    Delta = Float64.(df.Delta)
    t_h = Float64.(df.t) ./ 3600.0
    S = hypot.(U, V)

    eta = Float64(get(p, "shear_production_efficiency", 1.0))
    Kb = Float64(p["K"])

    Sc = similar(S)
    for i in eachindex(S)
        G = stability_response(Ts[i], p)
        gamma = closure_gamma(U[i], V[i], p)
        rhs = Kb * G
        denom = eta * max(gamma, eps(Float64))
        Sc[i] = rhs > 0 ? sqrt(rhs / denom) : 0.0
    end

    # Crossing logic: margin > 0 means outside critical radius (turbulence-sustaining region).
    margin = S .- Sc
    collapse_idx = Int[]
    reignite_idx = Int[]
    for i in 2:length(margin)
        if margin[i - 1] >= 0 && margin[i] < 0
            push!(collapse_idx, i)
        elseif margin[i - 1] < 0 && margin[i] >= 0
            push!(reignite_idx, i)
        end
    end

    return (dataset=dataset, U=U, V=V, Ts=Ts, S=S, Sc=Sc, t_h=t_h, Delta=Delta,
        collapse_idx=collapse_idx, reignite_idx=reignite_idx)
end

function circle_xy(r::Float64; n::Int=240)
    th = range(0.0, 2pi; length=n)
    return (r .* cos.(th), r .* sin.(th))
end

function add_hodograph_panel!(plt, tr, panel_index::Int)
    U, V, Sc, S, t_h = tr.U, tr.V, tr.Sc, tr.S, tr.t_h
    cidx, ridx = tr.collapse_idx, tr.reignite_idx

    plot!(plt[panel_index], U, V;
        line_z=t_h,
        linewidth=3,
        c=:plasma,
        colorbar_title="Time (h)",
        label="Hodograph",
    )

    # Draw critical-radius circles for representative times.
    i_start = 1
    i_mid = argmin(abs.(t_h .- (maximum(t_h) / 2)))
    i_end = length(t_h)

    for (idx, style, lbl, col) in (
        (i_start, :dash, "S_c start", :steelblue),
        (i_mid, :dot, "S_c mid", :darkorange),
        (i_end, :solid, "S_c end", :firebrick),
    )
        x, y = circle_xy(Sc[idx])
        plot!(plt[panel_index], x, y; linestyle=style, linewidth=2.2, color=col, alpha=0.9, label=lbl)
    end

    if !isempty(cidx)
        scatter!(plt[panel_index], U[cidx], V[cidx]; marker=:xcross, ms=8, color=:red, label="Collapse entry")
    end
    if !isempty(ridx)
        scatter!(plt[panel_index], U[ridx], V[ridx]; marker=:star5, ms=8, color=:limegreen, label="Re-ignition")
    end

    scatter!(plt[panel_index], [U[1]], [V[1]]; marker=:circle, ms=6, color=:black, label="Start")
    scatter!(plt[panel_index], [U[end]], [V[end]]; marker=:diamond, ms=6, color=:black, label="End")

    title!(plt[panel_index], "$(tr.dataset): Hodograph vs Dynamic Critical Radius")
    xlabel!(plt[panel_index], "U (m s^-1)")
    ylabel!(plt[panel_index], "V (m s^-1)")
    plot!(plt[panel_index]; aspect_ratio=:equal, grid=true)
end

function main(args::Vector{String})
    datasets, root, out = parse_args(args)
    traces = [load_dataset(ds, root) for ds in datasets]

    n = length(traces)
    plt = plot(layout=(1, n), size=(700 * n, 640), legend=:outerbottom, legendcolumns=4)

    for (i, tr) in enumerate(traces)
        add_hodograph_panel!(plt, tr, i)
    end

    mkpath(dirname(out))
    savefig(plt, out)
    println("saved: $(out)")
end

main(ARGS)
