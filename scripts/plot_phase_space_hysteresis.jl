#!/usr/bin/env julia
# scripts/plot_phase_space_hysteresis.jl
# Build a publication-ready 3D hysteresis portrait in (S, Delta, e) space.

using CSV
using DataFrames
using Plots
using Statistics

function usage()
    println("Usage: julia scripts/plot_phase_space_hysteresis.jl [options]")
    println("Options:")
    println("  --datasets <csv>      Dataset list (default: CASES99,FLOSS)")
    println("  --root <path>         Root results directory (default: results)")
    println("  --out <path>          Output figure path (default: reports/generated/figures/phase_space_hysteresis_orbit.png)")
end

function parse_args(args::Vector{String})
    datasets = ["CASES99", "FLOSS"]
    root = "results"
    out = joinpath("reports", "generated", "figures", "phase_space_hysteresis_orbit.png")

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

# 1D linear interpolation with endpoint clamping.
function interp1(x::Vector{Float64}, y::Vector{Float64}, xq::Float64)
    xq <= x[1] && return y[1]
    xq >= x[end] && return y[end]
    idx = searchsortedlast(x, xq)
    x0 = x[idx]
    x1 = x[idx + 1]
    y0 = y[idx]
    y1 = y[idx + 1]
    t = (xq - x0) / (x1 - x0)
    return (1 - t) * y0 + t * y1
end

function build_manifold_curve(deltas::Vector{Float64}, e_star::Vector{Float64})
    order = sortperm(deltas)
    d_sorted = deltas[order]
    e_sorted = e_star[order]

    # Bin by Delta and average to remove temporal noise while preserving manifold trend.
    nbins = min(100, max(20, Int(floor(length(d_sorted) / 100))))
    dmin, dmax = extrema(d_sorted)
    edges = collect(range(dmin, dmax; length=nbins + 1))

    d_bin = Float64[]
    e_bin = Float64[]

    for k in 1:nbins
        lo = edges[k]
        hi = edges[k + 1]
        mask = (d_sorted .>= lo) .& (k == nbins ? (d_sorted .<= hi) : (d_sorted .< hi))
        if any(mask)
            push!(d_bin, mean(d_sorted[mask]))
            push!(e_bin, mean(e_sorted[mask]))
        end
    end

    return d_bin, e_bin
end

function load_dataset_frame(dataset::AbstractString, root::AbstractString)
    csv_path = joinpath(String(root), String(dataset), "latest", "solution.csv")
    isfile(csv_path) || error("Missing solution file for $(dataset): $(csv_path)")

    df = CSV.read(csv_path, DataFrame)
    required = (:U, :V, :Delta, :e, :e_star_smooth)
    for col in required
        col in propertynames(df) || error("$(csv_path) missing column: $(col)")
    end

    S = sqrt.(Float64.(df.U).^2 .+ Float64.(df.V).^2)
    Delta = Float64.(df.Delta)
    e = Float64.(df.e)
    e_star = Float64.(df.e_star_smooth)

    return (S=S, Delta=Delta, e=e, e_star=e_star)
end

function main(args::Vector{String})
    datasets, root, out = parse_args(args)

    traces = Dict{String,NamedTuple}()
    pooled_delta = Float64[]
    pooled_estar = Float64[]

    for ds in datasets
        tr = load_dataset_frame(ds, root)
        traces[ds] = tr
        append!(pooled_delta, tr.Delta)
        append!(pooled_estar, tr.e_star)
    end

    d_curve, e_curve = build_manifold_curve(pooled_delta, pooled_estar)

    # Build a manifold sheet e*(Delta) extruded along wind-speed axis S.
    all_S = reduce(vcat, [traces[ds].S for ds in datasets])
    smin, smax = extrema(all_S)
    dmin, dmax = extrema(pooled_delta)

    s_grid = collect(range(smin, smax; length=45))
    d_grid = collect(range(dmin, dmax; length=90))
    z_grid = [max(interp1(d_curve, e_curve, d), 0.0) for d in d_grid, s in s_grid]

    plt = surface(
        s_grid,
        d_grid,
        z_grid;
        alpha=0.28,
        c=:viridis,
        legend=:topright,
        xlabel="Wind speed S (m s^-1)",
        ylabel="Net forcing Delta",
        zlabel="TKE e (m^2 s^-2)",
        title="3D Phase-Space Hysteresis Orbit on Critical Manifold",
        label="Estimated S_0^+ sheet",
        camera=(40, 25),
        size=(1300, 900),
    )

    color_map = Dict("CASES99" => :black, "FLOSS" => :crimson, "SHEBA" => :royalblue)
    for ds in datasets
        tr = traces[ds]
        plot!(
            plt,
            tr.S,
            tr.Delta,
            tr.e;
            linewidth=3,
            color=get(color_map, ds, :darkgray),
            alpha=0.95,
            label="$(ds) trajectory",
        )

        scatter!(
            plt,
            [tr.S[1]],
            [tr.Delta[1]],
            [tr.e[1]];
            markersize=5,
            markercolor=get(color_map, ds, :darkgray),
            markerstrokecolor=:white,
            label="",
        )
    end

    mkpath(dirname(out))
    savefig(plt, out)
    println("saved: $(out)")
end

main(ARGS)
