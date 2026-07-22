#!/usr/bin/env julia
# scripts/plot_triheight_hovmoller.jl
# Figure Concept 3: time-height Hovmoller with tri-height tracks.

using Printf
using Statistics
import JLD2
import Plots

function usage()
    println("Usage: julia scripts/plot_triheight_hovmoller.jl --input <payload.jld2> [options]")
    println("Options:")
    println("  --input <path>          Input SCM payload JLD2 (required)")
    println("  --out <path>            Output figure path (default: reports/generated/figures/triheight_hovmoller.png)")
    println("  --field <e_xi|theta|wind>  Hovmoller field (default: e_xi)")
    println("  --dpi <int>             Figure DPI (default: 220)")
    println("  --help                  Show this help message")
end

function parse_args(args::Vector{String})
    cfg = Dict{String,Any}(
        "input" => "",
        "out" => joinpath("reports", "generated", "figures", "triheight_hovmoller.png"),
        "field" => "e_xi",
        "dpi" => 220,
    )

    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--help"
            usage()
            exit(0)
        elseif a == "--input" && i < length(args)
            cfg["input"] = args[i + 1]
            i += 2
        elseif a == "--out" && i < length(args)
            cfg["out"] = args[i + 1]
            i += 2
        elseif a == "--field" && i < length(args)
            cfg["field"] = lowercase(args[i + 1])
            i += 2
        elseif a == "--dpi" && i < length(args)
            cfg["dpi"] = parse(Int, args[i + 1])
            i += 2
        else
            error("Unknown or incomplete argument: $(a)")
        end
    end

    cfg["input"] == "" && error("--input is required")
    cfg["field"] in ("e_xi", "theta", "wind") || error("--field must be one of: e_xi, theta, wind")
    return cfg
end

function maybe_getkey(x, key::Symbol)
    if hasproperty(x, key)
        return getproperty(x, key)
    elseif x isa AbstractDict
        haskey(x, key) && return x[key]
        skey = String(key)
        haskey(x, skey) && return x[skey]
    end
    return nothing
end

function getkey(x, key::Symbol)
    val = maybe_getkey(x, key)
    val === nothing && error("Missing key/property: $(key)")
    return val
end

function sanitize_finite(arr; fallback::Float64=0.0)
    out = Float64.(arr)
    @inbounds for i in eachindex(out)
        if !isfinite(out[i])
            out[i] = fallback
        end
    end
    return out
end

function clims_safe(arr; pad::Float64=1e-12)
    flat = vec(Float64.(arr))
    vals = filter(isfinite, flat)
    isempty(vals) && return (0.0, 1.0)
    lo = minimum(vals)
    hi = maximum(vals)
    hi <= lo && return (lo - pad, hi + pad)
    return (lo, hi)
end

function clims_percentile(arr; p_lo::Float64=0.01, p_hi::Float64=0.995, pad::Float64=1e-12)
    flat = vec(Float64.(arr))
    vals = filter(isfinite, flat)
    isempty(vals) && return (0.0, 1.0)
    lo = quantile(vals, p_lo)
    hi = quantile(vals, p_hi)
    if hi <= lo
        return clims_safe(vals; pad=pad)
    end
    return (lo, hi)
end

"""Ensure matrix is oriented as (time, z) for consistent heatmap rendering."""
function align_time_z(raw_mat::AbstractMatrix{<:Real}, z_len::Int)
    if size(raw_mat, 2) == z_len
        return Float64.(raw_mat)
    elseif size(raw_mat, 1) == z_len
        return Float64.(permutedims(raw_mat))
    end
    error("Could not align Hovmoller matrix with z-length=$(z_len). matrix size=$(size(raw_mat))")
end

function overlay_triheight!(plt, t_hours, hD, hE, hG)
    Plots.plot!(plt, t_hours, hD; linewidth=2.3, linestyle=:dash, color=:gold3, alpha=0.95, label="h_D")
    Plots.plot!(plt, t_hours, hE; linewidth=2.3, linestyle=:dash, color=:deepskyblue3, alpha=0.95, label="h_e")
    Plots.plot!(plt, t_hours, hG; linewidth=2.3, linestyle=:dash, color=:orangered3, alpha=0.95, label="h_∂e")
end

function main(args::Vector{String})
    cfg = parse_args(args)

    data = JLD2.load(cfg["input"])
    ts = data["time_series"]
    hov = data["hovmoller"]

    hD = maybe_getkey(ts[1], :h_decoupling)
    hE = maybe_getkey(ts[1], :h_energy_floor)
    hG = maybe_getkey(ts[1], :h_max_energy_gradient)
    triheight_ok = !(isnothing(hD) || isnothing(hE) || isnothing(hG))
    triheight_ok || error("Tri-height diagnostics unavailable in payload: need h_decoupling, h_energy_floor, h_max_energy_gradient")

    t_hours = [Float64(getkey(r, :t)) / 3600.0 for r in ts]
    h_decoupling = [Float64(getkey(r, :h_decoupling)) for r in ts]
    h_energy_floor = [Float64(getkey(r, :h_energy_floor)) for r in ts]
    h_max_energy_gradient = [Float64(getkey(r, :h_max_energy_gradient)) for r in ts]

    hov_t = collect(Float64, getkey(hov, :t)) ./ 3600.0
    field = String(cfg["field"])

    z = Float64[]
    mat = Array{Float64}(undef, 0, 0)
    title = ""
    cbar = ""
    cmap = :viridis

    if field == "e_xi"
        zf = collect(Float64, getkey(hov, :z_faces))
        raw_mat = sanitize_finite(getkey(hov, :e_xi))

        # Prefer face-centered heights when dimensions match; otherwise fall back to centers.
        z_faces_mid = zf[2:(end - 1)]
        zc = collect(Float64, getkey(hov, :z_centers))
        if (length(z_faces_mid) == size(raw_mat, 1)) || (length(z_faces_mid) == size(raw_mat, 2))
            z = z_faces_mid
            mat = align_time_z(raw_mat, length(z))
        elseif (length(zc) == size(raw_mat, 1)) || (length(zc) == size(raw_mat, 2))
            z = zc
            mat = align_time_z(raw_mat, length(z))
        else
            error("e_xi grid mismatch: z_faces_mid=$(length(z_faces_mid)), z_centers=$(length(zc)), matrix=$(size(raw_mat))")
        end

        # Plot velocity-scale proxy q=sqrt(e_xi) to compress multi-order dynamic range.
        mat = sqrt.(max.(mat, 1.0e-12))
        title = "Tri-Height Diagnostic Hovmoller: q = sqrt(e_xi)"
        cbar = "q (m s^-1)"
        cmap = Plots.cgrad([:midnightblue, :royalblue3, :deepskyblue2, :gold1])
    elseif field == "theta"
        z = collect(Float64, getkey(hov, :z_centers))
        raw_mat = sanitize_finite(getkey(hov, :theta))
        mat = align_time_z(raw_mat, length(z))
        title = "Tri-Height Diagnostic Hovmoller: theta(z,t)"
        cbar = "theta (K)"
        cmap = :thermal
    else
        z = collect(Float64, getkey(hov, :z_centers))
        raw_mat = sanitize_finite(getkey(hov, :wind))
        mat = align_time_z(raw_mat, length(z))
        title = "Tri-Height Diagnostic Hovmoller: |V|(z,t)"
        cbar = "|V| (m s^-1)"
        cmap = :viridis
    end

    c_limits = field == "e_xi" ? clims_percentile(mat; p_lo=0.001, p_hi=0.999) : clims_safe(mat)

    plt = Plots.heatmap(
        hov_t,
        z,
        permutedims(mat),
        xlabel="Time (h)",
        ylabel="z (m)",
        title=title,
        colorbar_title=cbar,
        c=cmap,
        clims=c_limits,
        legend=:topright,
        dpi=Int(cfg["dpi"]),
        size=(1200, 700),
        right_margin=7Plots.mm,
    )

    overlay_triheight!(plt, t_hours, h_decoupling, h_energy_floor, h_max_energy_gradient)

    mkpath(dirname(String(cfg["out"])))
    Plots.savefig(plt, String(cfg["out"]))
    println("saved: $(cfg["out"])")
end

main(ARGS)
