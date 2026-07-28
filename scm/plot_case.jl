#!/usr/bin/env julia
# scm/plot_case.jl: High-performance, publication-grade diagnostic figure generator

using Printf
using Random
using Statistics
using Dates
using Logging
import JLD2
import Plots

# Use file-only rendering to avoid interactive GR transport warnings in CLI runs.
ENV["GKSwstype"] = "100"

# Default GR backend setup for crisp publication typography
Plots.gr()
Plots.default(
    fontfamily="Computer Modern",
    titlefontsize=11,
    guidefontsize=10,
    tickfontsize=8,
    legendfontsize=8,
    framestyle=:box,
    grid=true,
    gridalpha=0.25,
    gridlinewidth=0.6,
)

# Mirror payload structs so JLD2 can deserialize without reconstruction warnings
mutable struct SCMWorkspace{T}
    Km::Vector{T}
    Kh::Vector{T}
end

struct SCMParameters{T,W}
    N::Int
    dz::T
    z_centers::Vector{T}
    z_faces::Vector{T}
    f::T
    Ug::T
    Vg::T
    theta_a::T
    T_deep::T
    delta::T
    K_buoy::T
    beta::T
    l_0::T
    eta::T
    xi::T
    C_skin::T
    R_down::T
    lambda_s::T
    d_soil::T
    h::T
    use_nonlocal_h::T
    nonlocal_h_weight::T
    nonlocal_h_min::T
    nonlocal_h_max::T
    nonlocal_velocity_floor::T
    nonlocal_f_floor::T
    z0m::T
    z0h::T
    k_min_surf::T
    pr_t_base::T
    pr_t_slope::T
    use_dynamic_pr_t::Bool
    g_stability_max::T
    k_exchange_min::T
    ell_min_surf::T
    use_ell_floor_surf::Bool
    ts_min::T
    ts_max::T
    theta_top_bc::Symbol
    theta_top::T
    lambda_top::T
    debug_print::Bool
    profile_every::T
    workspace::W
end

Base.@kwdef struct PlotContext
    payload_path::String
    ts::Vector{Any}
    p::Any
    N_t::Int
    t_hours::Vector{Float64}
    t_end_h::Float64
    T_s::Vector{Float64}
    H::Vector{Float64}
    ustar::Vector{Float64}
    Rn::Vector{Float64}
    G::Vector{Float64}
    storage::Vector{Float64}
    T_rad::Vector{Float64}
    delta_surface::Vector{Float64}
    zc::Vector{Float64}
    zf::Vector{Float64}
    zf_mid::Vector{Float64}
    hov_t::Vector{Float64}
    hov_wind::Matrix{Float64}
    hov_theta::Matrix{Float64}
    hov_km::Matrix{Float64}
    hov_exi::Matrix{Float64}
    z_max::Float64
    z_ticks::Any
    left_pad::Any
    bottom_pad::Any
    right_pad::Any
end

Base.@kwdef struct ClosureArrays
    ri_flat::Vector{Float64}
    delta_flat::Vector{Float64}
    exi_flat::Vector{Float64}
    km_flat::Vector{Float64}
    kh_flat::Vector{Float64}
    shear_flat::Vector{Float64}
    z_flat::Vector{Float64}
    q_flat::Vector{Float64}
    ri_min_disp::Float64
    ri_max_disp::Float64
    m_surf::BitVector
    m_mid::BitVector
    m_upp::BitVector
    pr_t_all::Vector{Float64}
    pos_ri::BitVector
end

function _usage()
    println("Usage: julia scm/plot_case.jl --input <payload.jld2> [options]")
    println("Options:")
    println("  --input <path>          Input payload JLD2 from scm/run_case.jl (required)")
    println("  --outdir <path>         Output directory for figures (default: <payload_dir>/plots)")
    println("  --format <png|pdf>      Figure format (default: png)")
    println("  --dpi <int>             DPI for raster export (default: 300)")
    println("  --figure <all|1..8>     Render all figures or only one target figure (default: all)")
    println("  --max-points <int>      Max scatter points per plotted series (default: 25000, 0 = full density)")
    println("  --help                  Show this help message")
end

function parse_args(args::Vector{String})
    cfg = Dict{String,Any}(
        "input" => "",
        "outdir" => "",
        "format" => "png",
        "dpi" => 300,
        "figure" => 0,
        "max_points" => 25_000,
    )

    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--help"
            _usage()
            exit(0)
        elseif a == "--input" && i < length(args)
            cfg["input"] = args[i+1]
            i += 2
        elseif a == "--outdir" && i < length(args)
            cfg["outdir"] = args[i+1]
            i += 2
        elseif a == "--format" && i < length(args)
            cfg["format"] = lowercase(args[i+1])
            i += 2
        elseif a == "--dpi" && i < length(args)
            cfg["dpi"] = parse(Int, args[i+1])
            i += 2
        elseif a == "--figure" && i < length(args)
            cfg["figure"] = _normalize_figure_selector(args[i+1])
            i += 2
        elseif a == "--max-points" && i < length(args)
            cfg["max_points"] = parse(Int, args[i+1])
            i += 2
        else
            error("Unknown or incomplete argument: $(a). Use --help for options.")
        end
    end

    cfg["input"] == "" && error("--input is required")
    cfg["format"] in ("png", "pdf") || error("--format must be png or pdf")
    cfg["max_points"] >= 0 || error("--max-points must be >= 0")
    return cfg
end

function _normalize_figure_selector(raw::String)
    s = lowercase(strip(raw))
    s in ("all", "*") && return 0
    m = match(r"^fig0?([1-8])$", s)
    m !== nothing && return parse(Int, m.captures[1])
    m = match(r"^([1-8])$", s)
    m !== nothing && return parse(Int, m.captures[1])
    error("--figure must be one of: all, 1..8, fig1..fig8")
end

@inline _figure_enabled(selector::Int, fig::Int) = (selector == 0 || selector == fig)

@inline function _get_field(obj, key::Symbol)
    if hasproperty(obj, key)
        return getproperty(obj, key)
    elseif obj isa AbstractDict
        haskey(obj, key) && return obj[key]
        skey = String(key)
        haskey(obj, skey) && return obj[skey]
    end
    error("Key $(key) not found")
end

@inline function _maybe_get_field(obj, key::Symbol)
    if hasproperty(obj, key)
        return getproperty(obj, key)
    elseif obj isa AbstractDict
        haskey(obj, key) && return obj[key]
        skey = String(key)
        haskey(obj, skey) && return obj[skey]
    end
    return nothing
end

function _nearest_index(values::AbstractVector{<:Real}, target::Real)
    return argmin(abs.(values .- target))
end

function _percentile_clims(arr; p_lo::Float64=0.005, p_hi::Float64=0.995)
    flat = vec(Float64.(arr))
    finite_vals = filter(isfinite, flat)
    isempty(finite_vals) && return (0.0, 1.0)
    lo = quantile(finite_vals, p_lo)
    hi = quantile(finite_vals, p_hi)
    return hi <= lo ? (lo - 1e-6, hi + 1e-6) : (lo, hi)
end

function _sanitize_finite(arr; fallback::Float64=0.0)
    out = Float64.(arr)
    @inbounds for i in eachindex(out)
        if !isfinite(out[i])
            out[i] = fallback
        end
    end
    return out
end

function _asinh_forward(values, scale::Float64)
    return asinh.(Float64.(values) ./ scale)
end

function _asinh_ticks(lo::Float64, hi::Float64; scale::Float64)
    candidates = [-1.0, -0.5, -0.25, -0.1, -0.05, 0.0, 0.05, 0.1, 0.25, 0.5, 1.0, 2.0]
    vals = [v for v in candidates if lo <= v <= hi]
    isempty(vals) && (vals = [lo, hi])
    positions = asinh.(vals ./ scale)
    labels = [@sprintf("%.3g", v) for v in vals]
    return (positions, labels)
end

function _savefig(Plots, fig, outdir::String, stem::String, ext::String)
    path = joinpath(outdir, string(stem, ".", ext))
    Plots.savefig(fig, path)
    @info "Saved figure" path=path
    return path
end

@inline _plot_defaults(ctx::PlotContext, dpi::Int) = (
    dpi=dpi,
    left_margin=ctx.left_pad,
    bottom_margin=ctx.bottom_pad,
    right_margin=ctx.right_pad,
)

function _json_escape(s::AbstractString)
    t = replace(s, "\\" => "\\\\")
    t = replace(t, "\"" => "\\\"")
    t = replace(t, "\n" => "\\n")
    return t
end

function _git_commit_or_unknown()
    try
        return readchomp(`git rev-parse --short HEAD`)
    catch
        return "unknown"
    end
end

function _write_figure_metadata(fig_path::String, ctx::PlotContext, dpi::Int, fmt::String, max_points::Int)
    meta_path = replace(fig_path, r"\.[^.]+$" => ".meta.json")
    created = Dates.format(Dates.now(), dateformat"yyyy-mm-ddTHH:MM:SS")
    commit = _git_commit_or_unknown()
    open(meta_path, "w") do io
        println(io, "{")
        println(io, "  \"figure\": \"$(_json_escape(basename(fig_path)))\",")
        println(io, "  \"payload\": \"$(_json_escape(ctx.payload_path))\",")
        println(io, "  \"git_commit\": \"$(_json_escape(commit))\",")
        println(io, "  \"dpi\": $(dpi),")
        println(io, "  \"format\": \"$(_json_escape(fmt))\",")
        println(io, "  \"max_points\": $(max_points),")
        println(io, "  \"created\": \"$(_json_escape(created))\"")
        println(io, "}")
    end
    @info "Saved metadata" path=meta_path
end

function _subsample_indices(n::Int, max_points::Int; seed::Int=42)
    if max_points <= 0 || n <= max_points
        return collect(1:n)
    end
    rng = MersenneTwister(seed)
    idx = randperm(rng, n)[1:max_points]
    sort!(idx)
    return idx
end

function _subsample_pairs(x, y, max_points::Int; seed::Int=42)
    n = min(length(x), length(y))
    n == 0 && return (Float64[], Float64[])
    idx = _subsample_indices(n, max_points; seed=seed)
    return (x[idx], y[idx])
end

function _build_plot_context(data, payload_path::String)
    ts = data["time_series"]
    hov = data["hovmoller"]
    p = data["p"]
    N_t = length(ts)
    N_t == 0 && error("time_series is empty in payload: $(payload_path)")

    t_hours = Float64[_get_field(r, :t) for r in ts] ./ 3600.0
    t_end_h = maximum(t_hours)

    T_s = Float64[_get_field(r, :T_s) for r in ts]
    H = Float64[_get_field(r, :sensible_heat_flux) for r in ts]
    ustar = Float64[_get_field(r, :u_star) for r in ts]
    Rn = Float64[_get_field(r, :net_radiation) for r in ts]
    G = Float64[_get_field(r, :ground_heat_flux) for r in ts]
    storage = Float64[_get_field(r, :storage) for r in ts]
    T_rad = Float64[_get_field(r, :radiative_equilibrium_temperature) for r in ts]
    delta_surface = Float64[_get_field(r, :surface_delta) for r in ts]

    zc = collect(Float64, _get_field(hov, :z_centers))
    zf = collect(Float64, _get_field(hov, :z_faces))
    zf_mid = zf[2:(end-1)]
    hov_t = collect(Float64, _get_field(hov, :t)) ./ 3600.0

    hov_wind = _sanitize_finite(_get_field(hov, :wind))
    hov_theta = _sanitize_finite(_get_field(hov, :theta))
    hov_km = _sanitize_finite(_get_field(hov, :Km))
    hov_exi = _sanitize_finite(_get_field(hov, :e_xi))

    z_max = 200.0
    z_ticks = 0:50:z_max
    left_pad = 12Plots.mm
    bottom_pad = 10Plots.mm
    right_pad = 12Plots.mm

    return PlotContext(
        payload_path=payload_path,
        ts=Vector{Any}(ts),
        p=p,
        N_t=N_t,
        t_hours=t_hours,
        t_end_h=t_end_h,
        T_s=T_s,
        H=H,
        ustar=ustar,
        Rn=Rn,
        G=G,
        storage=storage,
        T_rad=T_rad,
        delta_surface=delta_surface,
        zc=zc,
        zf=zf,
        zf_mid=zf_mid,
        hov_t=hov_t,
        hov_wind=hov_wind,
        hov_theta=hov_theta,
        hov_km=hov_km,
        hov_exi=hov_exi,
        z_max=z_max,
        z_ticks=z_ticks,
        left_pad=left_pad,
        bottom_pad=bottom_pad,
        right_pad=right_pad,
    )
end

function _prepare_closure_arrays(ctx::PlotContext)
    N_f = length(ctx.zf_mid)
    Ri_mat = Matrix{Float64}(undef, N_f, ctx.N_t)
    Delta_mat = Matrix{Float64}(undef, N_f, ctx.N_t)
    Exi_mat = Matrix{Float64}(undef, N_f, ctx.N_t)
    Km_mat = Matrix{Float64}(undef, N_f, ctx.N_t)
    Kh_mat = Matrix{Float64}(undef, N_f, ctx.N_t)
    Shear_mat = Matrix{Float64}(undef, N_f, ctx.N_t)

    for (j, row) in enumerate(ctx.ts)
        Ri_mat[:, j] .= Float64.(_get_field(row, :Ri_faces))
        Delta_mat[:, j] .= Float64.(_get_field(row, :Delta_faces))
        Exi_mat[:, j] .= Float64.(_get_field(row, :e_xi_faces))
        Km_mat[:, j] .= Float64.(_get_field(row, :Km_faces))
        Kh_mat[:, j] .= Float64.(_get_field(row, :Kh_faces))
        sh = _maybe_get_field(row, :shear_faces)
        Shear_mat[:, j] .= sh === nothing ? sqrt.(max.(Float64.(_get_field(row, :shear2_faces)), 0.0)) : Float64.(sh)
    end

    ri_flat = vec(Ri_mat)
    delta_flat = vec(Delta_mat)
    exi_flat = vec(Exi_mat)
    km_flat = max.(vec(Km_mat), 1e-6)
    kh_flat = max.(vec(Kh_mat), 1e-6)
    shear_flat = vec(Shear_mat)
    z_flat = repeat(ctx.zf_mid, outer=ctx.N_t)

    l_0 = Float64(_get_field(ctx.p, :l_0))
    delta_p = Float64(_get_field(ctx.p, :delta))
    q_flat = @. (l_0 * delta_flat)^2 - delta_p

    ri_min_disp, ri_max_disp = -0.5, 1.0
    valid_ri = (ri_flat .>= ri_min_disp) .& (ri_flat .<= ri_max_disp)

    z_top = maximum(ctx.zf)
    m_surf = valid_ri .& (z_flat .<= 0.2 * z_top)
    m_mid = valid_ri .& (z_flat .> 0.2 * z_top) .& (z_flat .<= 0.6 * z_top)
    m_upp = valid_ri .& (z_flat .> 0.6 * z_top)

    pr_t_all = km_flat ./ kh_flat
    pos_ri = (ri_flat .> 0.0) .& isfinite.(ri_flat) .& isfinite.(km_flat) .& isfinite.(kh_flat) .& isfinite.(pr_t_all)
    any(pos_ri) || error("No valid positive Ri points available for Figure 7 plotting")

    return ClosureArrays(
        ri_flat=ri_flat,
        delta_flat=delta_flat,
        exi_flat=exi_flat,
        km_flat=km_flat,
        kh_flat=kh_flat,
        shear_flat=shear_flat,
        z_flat=z_flat,
        q_flat=q_flat,
        ri_min_disp=ri_min_disp,
        ri_max_disp=ri_max_disp,
        m_surf=BitVector(m_surf),
        m_mid=BitVector(m_mid),
        m_upp=BitVector(m_upp),
        pr_t_all=pr_t_all,
        pos_ri=BitVector(pos_ri),
    )
end

function plot_surface_timeseries(ctx, outdir::String, fmt::String, dpi::Int)
    base_kw = _plot_defaults(ctx, dpi)
    p1a = Plots.plot(
        ctx.t_hours, ctx.T_s;
        base_kw...,
        xlabel="Time (h)", ylabel="T_s (K)",
        label="T_s", color=:royalblue3, linewidth=2.0,
        legend=:topleft, title="Surface Thermodynamic Evolution"
    )
    p1ar = Plots.twinx(p1a)
    Plots.plot!(
        p1ar, ctx.t_hours, ctx.H;
        label="H", linewidth=2.0, color=:crimson,
        ylabel="H (W m^-2)", legend=:topright, framestyle=:box
    )

    p1b = Plots.plot(
        ctx.t_hours, ctx.ustar;
        base_kw...,
        xlabel="Time (h)", ylabel="u_* (m s^-1)",
        label="u_*", color=:slategray, linewidth=2.0, linestyle=:dash,
        legend=:topright, title="Friction Velocity"
    )
    p1 = Plots.plot(p1a, p1b; layout=(2, 1), size=(1100, 700), margin=6Plots.mm)
    _savefig(Plots, p1, outdir, "fig01_timeseries_ts_h_ustar", fmt)
end

function plot_hovmoller_wind(ctx, outdir::String, fmt::String, dpi::Int)
    base_kw = _plot_defaults(ctx, dpi)
    p2 = Plots.heatmap(
        ctx.hov_t, ctx.zc, permutedims(ctx.hov_wind);
        base_kw...,
        xlabel="Time (h)", ylabel="z (m)", title="Time-Height Wind Speed Evolution",
        colorbar_title="|V| (m s^-1)", c=:viridis,
        clims=_percentile_clims(ctx.hov_wind), ylims=(0, ctx.z_max), yticks=ctx.z_ticks,
        size=(1400, 500)
    )
    _savefig(Plots, p2, outdir, "fig02_hovmoller_wind", fmt)
end

function plot_hovmoller_theta(ctx, outdir::String, fmt::String, dpi::Int)
    base_kw = _plot_defaults(ctx, dpi)
    p3 = Plots.heatmap(
        ctx.hov_t, ctx.zc, permutedims(ctx.hov_theta);
        base_kw...,
        xlabel="Time (h)", ylabel="z (m)", title="Time-Height Potential Temperature Evolution",
        colorbar_title="theta (K)", c=:thermal,
        clims=_percentile_clims(ctx.hov_theta), ylims=(0, ctx.z_max), yticks=ctx.z_ticks,
        size=(1400, 500)
    )
    _savefig(Plots, p3, outdir, "fig03_hovmoller_theta", fmt)
end

function plot_vertical_profiles(ctx, outdir::String, fmt::String, dpi::Int)
    target_hours = unique([min(3.0, ctx.t_end_h), min(6.0, ctx.t_end_h), min(9.0, ctx.t_end_h)])
    t_idx = [_nearest_index(ctx.t_hours, th) for th in target_hours]
    line_colors = [:royalblue3, :darkorange2, :seagreen, :crimson]

    p4a = Plots.plot(xlabel="U (m s^-1)", ylabel="z (m)", title="U(z)", legend=:topleft, ylims=(0, ctx.z_max), yticks=ctx.z_ticks)
    p4b = Plots.plot(xlabel="theta (K)", ylabel="z (m)", title="theta(z)", legend=:none, ylims=(0, ctx.z_max), yticks=ctx.z_ticks)
    p4c = Plots.plot(xlabel="K_m (m^2 s^-1)", ylabel="z (m)", title="K_m(z)", legend=:none, ylims=(0, ctx.z_max), yticks=ctx.z_ticks)

    ri_faces_all = _sanitize_finite(vcat([_get_field(r, :Ri_faces) for r in ctx.ts]...))
    ri4_lo = max(-0.5, minimum(ri_faces_all))
    ri4_hi = max(0.5, maximum(ri_faces_all))
    if ri4_hi <= ri4_lo
        ri4_hi = ri4_lo + 1.0
    end
    ri4_scale = 0.10
    p4_xticks = _asinh_ticks(ri4_lo, ri4_hi; scale=ri4_scale)
    p4_xlim = (asinh(ri4_lo / ri4_scale), asinh(ri4_hi / ri4_scale))

    p4d = Plots.plot(
        xlabel="Ri_g",
        ylabel="z (m)",
        title="Ri_g(z)",
        xlims=p4_xlim,
        xticks=p4_xticks,
        ylims=(0, ctx.z_max),
        yticks=ctx.z_ticks,
        legend=:topright,
    )

    for (i, idx) in enumerate(t_idx)
        row = ctx.ts[idx]
        lbl = @sprintf("t = %.1f h", ctx.t_hours[idx])
        col = line_colors[mod1(i, length(line_colors))]

        Plots.plot!(p4a, _sanitize_finite(_get_field(row, :U)), ctx.zc; label=lbl, linewidth=2.0, color=col)
        Plots.plot!(p4b, _sanitize_finite(_get_field(row, :theta)), ctx.zc; label="", linewidth=2.0, color=col)
        Plots.plot!(p4c, _sanitize_finite(_get_field(row, :Km_faces)), ctx.zf_mid; label="", linewidth=2.0, color=col)
        ri_prof_t = _asinh_forward(_sanitize_finite(_get_field(row, :Ri_faces)), ri4_scale)
        Plots.plot!(p4d, ri_prof_t, ctx.zf_mid; label=lbl, linewidth=2.0, color=col)
    end
    Plots.vline!(p4d, [asinh(0.25 / ri4_scale)]; color=:black, linestyle=:dash, linewidth=1.5, label="Ri_crit = 0.25")
    p4 = Plots.plot(p4a, p4b, p4c, p4d; layout=(1, 4), size=(1800, 480), margin=8Plots.mm)
    _savefig(Plots, p4, outdir, "fig04_profiles_u_theta_km", fmt)
end

function plot_surface_energy_budget(ctx, outdir::String, fmt::String, dpi::Int)
    p5 = Plots.plot(
        ctx.t_hours, ctx.Rn; label="R_n", linewidth=2.0, color=:navy,
        xlabel="Time (h)", ylabel="Flux (W m^-2)",
        title="Surface Energy Budget Balance", legend=:topright, dpi=dpi
    )
    Plots.plot!(p5, ctx.t_hours, ctx.H; label="H", linewidth=2.0, color=:crimson)
    Plots.plot!(p5, ctx.t_hours, ctx.G; label="G", linewidth=2.0, color=:darkgreen)
    Plots.plot!(p5, ctx.t_hours, ctx.storage; label="Storage", linewidth=2.0, linestyle=:dash, color=:darkorange)
    _savefig(Plots, p5, outdir, "fig05_surface_energy_budget", fmt)
end

function plot_phase_response(ctx, closure, outdir::String, fmt::String, dpi::Int; max_points::Int=25_000)
    # Sample once per layer so Ri, Q, and e_xi stay index-aligned across both panels.
    idx_surf = _subsample_indices(count(closure.m_surf), max_points; seed=101)
    idx_mid = _subsample_indices(count(closure.m_mid), max_points; seed=102)
    idx_upp = _subsample_indices(count(closure.m_upp), max_points; seed=103)

    ri_surf_all = closure.ri_flat[closure.m_surf]
    q_surf_all = closure.q_flat[closure.m_surf]
    exi_surf_all = closure.exi_flat[closure.m_surf]

    ri_mid_all = closure.ri_flat[closure.m_mid]
    q_mid_all = closure.q_flat[closure.m_mid]
    exi_mid_all = closure.exi_flat[closure.m_mid]

    ri_upp_all = closure.ri_flat[closure.m_upp]
    q_upp_all = closure.q_flat[closure.m_upp]
    exi_upp_all = closure.exi_flat[closure.m_upp]

    ri_surf = ri_surf_all[idx_surf]
    q_surf = q_surf_all[idx_surf]
    exi_surf = exi_surf_all[idx_surf]

    ri_mid = ri_mid_all[idx_mid]
    q_mid = q_mid_all[idx_mid]
    exi_mid = exi_mid_all[idx_mid]

    ri_upp = ri_upp_all[idx_upp]
    q_upp = q_upp_all[idx_upp]
    exi_upp = exi_upp_all[idx_upp]

    p6a = Plots.scatter(
        ri_surf, q_surf;
        markersize=2, alpha=0.5, color=:royalblue3,
        xlabel="Ri_g", ylabel="Q = (l0 Delta)^2 - delta",
        title="Q vs Ri_g", label="z <= 0.2 z_top", legend=:topright,
        xlims=(closure.ri_min_disp, closure.ri_max_disp), dpi=dpi
    )
    Plots.scatter!(p6a, ri_mid, q_mid; markersize=2, alpha=0.5, color=:darkorange, label="0.2 z_top < z <= 0.6 z_top")
    Plots.scatter!(p6a, ri_upp, q_upp; markersize=2, alpha=0.5, color=:seagreen, label="z > 0.6 z_top")
    Plots.hline!(p6a, [0.0]; color=:black, linestyle=:dash, label="Q = 0")

    p6b = Plots.scatter(
        ri_surf, exi_surf;
        markersize=2, alpha=0.5, color=:royalblue3,
        xlabel="Ri_g", ylabel="e_xi", title="e_xi vs Ri_g",
        label="z <= 0.2 z_top", legend=:topright, xlims=(closure.ri_min_disp, closure.ri_max_disp), dpi=dpi
    )
    Plots.scatter!(p6b, ri_mid, exi_mid; markersize=2, alpha=0.5, color=:darkorange, label="0.2 z_top < z <= 0.6 z_top")
    Plots.scatter!(p6b, ri_upp, exi_upp; markersize=2, alpha=0.5, color=:seagreen, label="z > 0.6 z_top")

    p6 = Plots.plot(p6a, p6b; layout=(1, 2), size=(1500, 480), margin=8Plots.mm)
    _savefig(Plots, p6, outdir, "fig06_phase_delta_exi", fmt)
end

function plot_closure_manifold(ctx, closure, outdir::String, fmt::String, dpi::Int; max_points::Int=25_000)
    ri_pos = closure.ri_flat[closure.pos_ri]
    km_pos = closure.km_flat[closure.pos_ri]
    shear_pos = closure.shear_flat[closure.pos_ri]
    z_pos = closure.z_flat[closure.pos_ri]
    delta_pos = closure.delta_flat[closure.pos_ri]
    pr_pos = closure.pr_t_all[closure.pos_ri]

    n_pos = length(ri_pos)
    idx = _subsample_indices(n_pos, max_points; seed=42)
    ri_pos = ri_pos[idx]
    km_pos = km_pos[idx]
    shear_pos = shear_pos[idx]
    z_pos = z_pos[idx]
    delta_pos = delta_pos[idx]
    pr_pos = pr_pos[idx]

    ri7_lo = 0.0
    ri7_hi = max(1.0, maximum(ri_pos))
    ri7_scale = 0.10
    ri7_vals = _asinh_forward(ri_pos, ri7_scale)
    ri7_xticks = _asinh_ticks(ri7_lo, ri7_hi; scale=ri7_scale)
    ri7_xlim = (asinh(ri7_lo / ri7_scale), asinh(ri7_hi / ri7_scale))

    p7a = Plots.scatter(
        ri7_vals, km_pos;
        zcolor=shear_pos, c=:cividis, colorbar_title="Shear S (s^-1)",
        xlabel="Ri_g", ylabel="K_m (m^2 s^-1)",
        title="(a) Km vs Ri_g (Color = Shear)", xlims=ri7_xlim, xticks=ri7_xticks, yscale=:identity,
        alpha=0.6, markersize=2.5, markerstrokewidth=0, legend=:topright, dpi=dpi
    )
    Plots.vline!(p7a, [asinh(0.25 / ri7_scale)]; color=:crimson, linestyle=:dash, label="Ri_crit = 0.25")

    p7b = Plots.scatter(
        ri7_vals, km_pos;
        zcolor=z_pos, c=:turbo, colorbar_title="z (m)",
        xlabel="Ri_g", ylabel="K_m (m^2 s^-1)",
        title="(b) Km vs Ri_g (Color = Height)", xlims=ri7_xlim, xticks=ri7_xticks, yscale=:identity,
        alpha=0.6, markersize=2.5, markerstrokewidth=0, legend=:none, dpi=dpi
    )

    p7c = Plots.scatter(
        delta_pos, km_pos;
        zcolor=shear_pos, c=:cividis, colorbar_title="Shear S (s^-1)",
        xlabel="Delta", ylabel="K_m (m^2 s^-1)",
        title="(c) Manifold Collapse: Km vs Delta", yscale=:identity,
        alpha=0.6, markersize=2.5, markerstrokewidth=0, legend=:topleft, dpi=dpi
    )
    Plots.vline!(p7c, [0.0]; color=:black, label="Delta = 0")

    p7d = Plots.scatter(
        ri7_vals, pr_pos;
        zcolor=shear_pos, c=:cividis, colorbar_title="Shear S (s^-1)",
        xlabel="Ri_g", ylabel="Pr_t = Km / Kh",
        title="(d) Dynamic Prandtl Number Pr_t vs Ri_g", xlims=ri7_xlim, xticks=ri7_xticks,
        alpha=0.6, markersize=2.5, markerstrokewidth=0, legend=:none, dpi=dpi
    )

    p7 = Plots.plot(p7a, p7b, p7c, p7d; layout=(2, 2), size=(1450, 950), margin=8Plots.mm, dpi=dpi)
    _savefig(Plots, p7, outdir, "fig07_closure_manifold", fmt)
end

function plot_fold_proximity(ctx, outdir::String, fmt::String, dpi::Int)
    l_0 = Float64(_get_field(ctx.p, :l_0))
    delta_p = Float64(_get_field(ctx.p, :delta))
    fold_dist = @. (l_0 * ctx.delta_surface)^2 - delta_p

    p8 = Plots.plot(
        ctx.t_hours, fold_dist; linewidth=2.0, color=:royalblue3,
        xlabel="Time (h)", ylabel="Q = (l0 Delta)^2 - delta",
        title="Quadratic Surface Fold Proximity Diagnostic",
        label="Q(t)", legend=:topright, dpi=dpi
    )
    Plots.hline!(p8, [0.0]; linewidth=1.5, linestyle=:dash, color=:black, label="Fold Threshold (Q = 0)")
    _savefig(Plots, p8, outdir, "fig08_fold_proximity", fmt)
end

function generate_figures(payload_path::String, outdir::String, fmt::String, dpi::Int; figure::Int=0, max_points::Int=25_000)
    mkpath(outdir)
    data = JLD2.load(payload_path)
    ctx = _build_plot_context(data, payload_path)

    _run_step(fig_num, name, fn) = begin
        if _figure_enabled(figure, fig_num)
            local fig_path = ""
            t_elapsed = @elapsed (fig_path = fn())
            _write_figure_metadata(fig_path, ctx, dpi, fmt, max_points)
            @printf("  [Fig %d] %-32s saved (%.2fs)\n", fig_num, name, t_elapsed)
        end
    end

    _run_step(1, "Surface Timeseries", () -> plot_surface_timeseries(ctx, outdir, fmt, dpi))
    _run_step(2, "Hovmoller Wind", () -> plot_hovmoller_wind(ctx, outdir, fmt, dpi))
    _run_step(3, "Hovmoller Theta", () -> plot_hovmoller_theta(ctx, outdir, fmt, dpi))
    _run_step(4, "Vertical Profiles", () -> plot_vertical_profiles(ctx, outdir, fmt, dpi))
    _run_step(5, "Surface Energy Budget", () -> plot_surface_energy_budget(ctx, outdir, fmt, dpi))

    closure = nothing
    if _figure_enabled(figure, 6) || _figure_enabled(figure, 7)
        closure = _prepare_closure_arrays(ctx)
    end

    _run_step(6, "Phase Response", () -> plot_phase_response(ctx, closure, outdir, fmt, dpi; max_points=max_points))
    _run_step(7, "Closure Manifold", () -> plot_closure_manifold(ctx, closure, outdir, fmt, dpi; max_points=max_points))
    _run_step(8, "Fold Proximity", () -> plot_fold_proximity(ctx, outdir, fmt, dpi))

    if figure == 0
        println("All figures generated successfully.")
    else
        @printf("Figure %d generated successfully.\n", figure)
    end
end

function main(args)
    cfg = parse_args(args)
    payload = cfg["input"]
    isfile(payload) || error("Input payload not found: $(payload)")
    outdir = cfg["outdir"] == "" ? joinpath(dirname(payload), "plots") : cfg["outdir"]

    println("Generating manuscript figure suite (High-Performance Pipeline)...")
    generate_figures(payload, outdir, cfg["format"], cfg["dpi"]; figure=cfg["figure"], max_points=cfg["max_points"])
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end