#!/usr/bin/env julia
# scripts/plot_regularization_smooth_vs_clipped.jl
# Figure Concept 4: Smooth C-infinity regularization vs hard clipping.

using JSON
using Plots

function usage()
    println("Usage: julia scripts/plot_regularization_smooth_vs_clipped.jl [options]")
    println("Options:")
    println("  --summary <path>    Summary JSON with parameters (default: results/CASES99/latest/summary.json)")
    println("  --out <path>        Output image path (default: reports/generated/figures/regularization_smooth_vs_clipped.png)")
    println("  --dpi <int>         Figure DPI (default: 240)")
end

function parse_args(args::Vector{String})
    cfg = Dict{String,Any}(
        "summary" => joinpath("results", "CASES99", "latest", "summary.json"),
        "out" => joinpath("reports", "generated", "figures", "regularization_smooth_vs_clipped.png"),
        "dpi" => 240,
    )

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--summary" && i < length(args)
            cfg["summary"] = args[i + 1]
            i += 2
        elseif arg == "--out" && i < length(args)
            cfg["out"] = args[i + 1]
            i += 2
        elseif arg == "--dpi" && i < length(args)
            cfg["dpi"] = parse(Int, args[i + 1])
            i += 2
        elseif arg == "--help"
            usage()
            exit(0)
        else
            error("Unknown or incomplete argument: $(arg)")
        end
    end

    return cfg
end

smooth_embed(raw::Float64, xi::Float64) = 0.5 * (raw + sqrt(raw^2 + xi^2))

function main(args::Vector{String})
    cfg = parse_args(args)
    summary_path = String(cfg["summary"])
    out_path = String(cfg["out"])
    dpi = Int(cfg["dpi"])

    isfile(summary_path) || error("Summary file not found: $(summary_path)")
    summary = JSON.parsefile(summary_path)
    params = summary["parameters"]

    l0 = Float64(params["l0"])
    delta = Float64(params["delta"])

    # Span collapse-to-active forcing region around the clipping threshold raw=0.
    d_clip = delta / l0
    dmin = d_clip - 0.03
    dmax = d_clip + 0.08
    Delta = collect(range(dmin, dmax; length=800))

    raw = l0 .* Delta .- delta
    e_clip = max.(0.0, raw)

    xi_values = [1.0e-5, 1.0e-4, 1.0e-3]
    colors = [:royalblue, :darkorange, :seagreen]

    p1 = plot(
        Delta,
        e_clip;
        linewidth=2.8,
        color=:black,
        linestyle=:dash,
        label="Hard clip: max(0, l0*Delta - delta)",
        xlabel="Net forcing Delta",
        ylabel="Embedded branch e*",
        title="Panel A: e* regularization near the laminar threshold",
        dpi=dpi,
        grid=true,
        gridalpha=0.3,
    )

    for (xi, col) in zip(xi_values, colors)
        e_smooth = smooth_embed.(raw, xi)
        plot!(p1, Delta, e_smooth; linewidth=2.4, color=col, label="Smooth e*_xi, xi=$(xi)")
    end

    vline!(p1, [d_clip]; color=:gray35, linestyle=:dot, linewidth=1.7, label="Delta = delta/l0")

    # Effective diffusivity response with a representative mixing-length scale.
    ell_ref = l0
    Km_clip = ell_ref .* sqrt.(e_clip .+ delta)

    p2 = plot(
        Delta,
        Km_clip;
        linewidth=2.8,
        color=:black,
        linestyle=:dash,
        label="K_m from hard clip",
        xlabel="Net forcing Delta",
        ylabel="K_m (scaled)",
        title="Panel B: K_m continuity and positive mixing floor",
        dpi=dpi,
        grid=true,
        gridalpha=0.3,
    )

    for (xi, col) in zip(xi_values, colors)
        e_smooth = smooth_embed.(raw, xi)
        Km_smooth = ell_ref .* sqrt.(e_smooth .+ delta)
        plot!(p2, Delta, Km_smooth; linewidth=2.4, color=col, label="K_m with xi=$(xi)")
    end

    k_floor = ell_ref * sqrt(delta)
    hline!(p2, [k_floor]; color=:purple4, linestyle=:dot, linewidth=1.7, label="Mixing floor: l0*sqrt(delta)")
    vline!(p2, [d_clip]; color=:gray35, linestyle=:dot, linewidth=1.7, label="")

    fig = plot(p1, p2; layout=(1, 2), size=(1600, 620), margin=6Plots.mm)

    mkpath(dirname(out_path))
    savefig(fig, out_path)
    println("saved: $(out_path)")
end

main(ARGS)
