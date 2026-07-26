#!/usr/bin/env julia
# scm/plot_case.jl: Generate diagnostic figures from a StableBoundaryLayerGSPT SCM payload
using Printf
using Statistics
import JLD2
import Plots

# Mirror payload structs so JLD2 can deserialize without reconstruction warnings.
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

function _usage()
    println("Usage: julia scm/plot_case.jl --input <payload.jld2> [options]")
    println("Options:")
    println("  --input <path>          Input payload JLD2 from scm/run_case.jl (required)")
    println("  --outdir <path>         Output directory for figures (default: <payload_dir>/plots)")
    println("  --format <png|pdf>      Figure format (default: png)")
    println("  --dpi <int>             DPI for raster export (default: 200)")
    println("  --help                  Show this help message")
end

function parse_args(args::Vector{String})
    cfg = Dict{String,Any}(
        "input" => "",
        "outdir" => "",
        "format" => "png",
        "dpi" => 200,
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
        else
            error("Unknown or incomplete argument: $(a). Use --help for options.")
        end
    end

    cfg["input"] == "" && error("--input is required")
    cfg["format"] in ("png", "pdf") || error("--format must be png or pdf")
    return cfg
end

function _maybe_getkey(x, key::Symbol)
    if hasproperty(x, key)
        return getproperty(x, key)
    elseif x isa AbstractDict
        haskey(x, key) && return x[key]
        skey = String(key)
        haskey(x, skey) && return x[skey]
    end
    return nothing
end

function _getkey(x, key::Symbol)
    val = _maybe_getkey(x, key)
    val === nothing && error("Missing key/property: $(key)")
    return val
end

function _nearest_index(values::AbstractVector{<:Real}, target::Real)
    return argmin(abs.(values .- target))
end

function _flatten_field(rows, key::Symbol)
    out = Float64[]
    for r in rows
        append!(out, vec(_getkey(r, key)))
    end
    return out
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

function _safe_clims(arr; pad::Float64=1.0e-12)
    flat = vec(Float64.(arr))
    finite_vals = filter(isfinite, flat)
    if isempty(finite_vals)
        return (0.0, 1.0)
    end
    lo = minimum(finite_vals)
    hi = maximum(finite_vals)
    if hi <= lo
        return (lo - pad, hi + pad)
    end
    return (lo, hi)
end

function _percentile_clims(arr; p_lo::Float64=0.01, p_hi::Float64=0.995, pad::Float64=1.0e-12)
    flat = vec(Float64.(arr))
    finite_vals = filter(isfinite, flat)
    if isempty(finite_vals)
        return (0.0, 1.0)
    end
    lo = quantile(finite_vals, p_lo)
    hi = quantile(finite_vals, p_hi)
    if hi <= lo
        return _safe_clims(arr; pad=pad)
    end
    return (lo, hi)
end

function _savefig(Plots, fig, outdir::String, stem::String, ext::String)
    path = joinpath(outdir, string(stem, ".", ext))
    Plots.savefig(fig, path)
    println("saved: $(path)")
    return path
end

function _overlay_triheight_tracks!(Plots, plt, t_hours, h_decoupling, h_energy_floor, h_max_energy_gradient; with_legend::Bool=true, z_cap=nothing)
    d_label = with_legend ? "h_D" : ""
    e_label = with_legend ? "h_e" : ""
    g_label = with_legend ? "h_∂e" : ""

    h_decoupling_plot = z_cap === nothing ? h_decoupling : clamp.(h_decoupling, 0.0, z_cap)
    h_energy_floor_plot = z_cap === nothing ? h_energy_floor : clamp.(h_energy_floor, 0.0, z_cap)
    h_max_energy_gradient_plot = z_cap === nothing ? h_max_energy_gradient : clamp.(h_max_energy_gradient, 0.0, z_cap)

    Plots.plot!(
        plt,
        t_hours,
        h_decoupling_plot;
        linewidth=2.2,
        linestyle=:dash,
        color=:gold3,
        alpha=0.95,
        label=d_label,
    )
    Plots.plot!(
        plt,
        t_hours,
        h_energy_floor_plot;
        linewidth=2.2,
        linestyle=:dash,
        color=:deepskyblue3,
        alpha=0.95,
        label=e_label,
    )
    Plots.plot!(
        plt,
        t_hours,
        h_max_energy_gradient_plot;
        linewidth=2.2,
        linestyle=:dash,
        color=:orangered3,
        alpha=0.95,
        label=g_label,
    )
end

function generate_figures(payload_path::String, outdir::String, fmt::String, dpi::Int)
    mkpath(outdir)
    data = JLD2.load(payload_path)

    times = data["times"]
    ts = data["time_series"]
    hov = data["hovmoller"]
    p = data["p"]

    t_hours = [Float64(_getkey(r, :t)) / 3600.0 for r in ts]
    t_end_h = maximum(t_hours)

    T_s = [Float64(_getkey(r, :T_s)) for r in ts]
    H = [Float64(_getkey(r, :sensible_heat_flux)) for r in ts]
    ustar = [Float64(_getkey(r, :u_star)) for r in ts]

    Rn = [Float64(_getkey(r, :net_radiation)) for r in ts]
    G = [Float64(_getkey(r, :ground_heat_flux)) for r in ts]
    storage = [Float64(_getkey(r, :storage)) for r in ts]
    T_rad = [Float64(_getkey(r, :radiative_equilibrium_temperature)) for r in ts]

    delta_surface = [Float64(_getkey(r, :surface_delta)) for r in ts]

    h_decoupling_raw = _maybe_getkey(ts[1], :h_decoupling)
    h_energy_floor_raw = _maybe_getkey(ts[1], :h_energy_floor)
    h_max_energy_gradient_raw = _maybe_getkey(ts[1], :h_max_energy_gradient)
    triheight_available = !isnothing(h_decoupling_raw) && !isnothing(h_energy_floor_raw) && !isnothing(h_max_energy_gradient_raw)

    h_decoupling = triheight_available ? [Float64(_getkey(r, :h_decoupling)) for r in ts] : Float64[]
    h_energy_floor = triheight_available ? [Float64(_getkey(r, :h_energy_floor)) for r in ts] : Float64[]
    h_max_energy_gradient = triheight_available ? [Float64(_getkey(r, :h_max_energy_gradient)) for r in ts] : Float64[]

    zc = collect(Float64, _getkey(hov, :z_centers))
    zf = collect(Float64, _getkey(hov, :z_faces))
    hov_t = collect(Float64, _getkey(hov, :t)) ./ 3600.0

    hov_wind = _sanitize_finite(_getkey(hov, :wind))
    hov_theta = _sanitize_finite(_getkey(hov, :theta))
    hov_km = _sanitize_finite(_getkey(hov, :Km))
    hov_exi = _sanitize_finite(_getkey(hov, :e_xi))
    zf_mid = zf[2:(end-1)]

    # Use a fixed manuscript scale for cross-case figure comparability.
    z_max = 200.0
    tick_step = z_max <= 150.0 ? 25.0 : 50.0
    z_ticks = 0:tick_step:z_max
    active_sbl_top = triheight_available ? clamp(median(h_decoupling), 0.0, z_max) : min(100.0, z_max)
    left_pad = 12Plots.mm
    bottom_pad = 8Plots.mm

    # =========================================================================
    # Figure 1: Time series (T_s, H, u_*)
    # =========================================================================
    p1a = Plots.plot(
        t_hours,
        T_s;
        xlabel="Time (h)",
        ylabel="T_s (K)",
        label="T_s (left)",
        color=:royalblue,
        linewidth=2.5,
        legend=:topleft,
        dpi=dpi,
        title="Surface Thermodynamic Evolution",
        grid=true,
        gridalpha=0.3,
        right_margin=12Plots.mm,
    )
    p1ar = Plots.twinx(p1a)
    Plots.plot!(
        p1ar,
        t_hours,
        H;
        label="H (right)",
        linewidth=2.5,
        color=:crimson,
        ylabel="Sensible Heat Flux H (W m^-2)",
        legend=:topright,
        framestyle=:box,
    )

    p1b = Plots.plot(
        t_hours,
        ustar;
        xlabel="Time (h)",
        ylabel="u_* (m s^-1)",
        label="u_*",
        color=:black,
        linewidth=2.5,
        linestyle=:dash,
        legend=:topright,
        dpi=dpi,
        title="Friction Velocity",
        grid=true,
        gridalpha=0.3,
    )

    p1 = Plots.plot(p1a, p1b; layout=(2, 1), size=(1100, 750), margin=6Plots.mm)
    _savefig(Plots, p1, outdir, "fig01_timeseries_ts_h_ustar", fmt)

    # Figure 2: Hovmoller wind speed
    p2 = Plots.heatmap(
        hov_t,
        zc,
        permutedims(hov_wind),
        xlabel="Time (h)",
        ylabel="z (m)",
        title="Figure 2: Time-Height Wind Speed",
        colorbar_title="|V| (m s^-1)",
        legend=:topright,
        clims=_percentile_clims(hov_wind; p_lo=0.005, p_hi=0.995),
        ylims=(0, z_max),
        yticks=z_ticks,
        left_margin=left_pad,
        bottom_margin=bottom_pad,
        dpi=dpi,
        right_margin=8Plots.mm,
        size=(1500, 520),
    )
    Plots.hspan!(p2, [0.0, active_sbl_top]; alpha=0.08, color=:gray65, label="")
    if triheight_available
        _overlay_triheight_tracks!(Plots, p2, t_hours, h_decoupling, h_energy_floor, h_max_energy_gradient; with_legend=true, z_cap=z_max)
    end
    _savefig(Plots, p2, outdir, "fig02_hovmoller_wind", fmt)

    # Figure 3: Hovmoller potential temperature
    p3 = Plots.heatmap(
        hov_t,
        zc,
        permutedims(hov_theta),
        xlabel="Time (h)",
        ylabel="z (m)",
        title="Figure 3: Time-Height Potential Temperature",
        colorbar_title="theta (K)",
        legend=:topright,
        clims=_percentile_clims(hov_theta; p_lo=0.005, p_hi=0.995),
        ylims=(0, z_max),
        yticks=z_ticks,
        left_margin=left_pad,
        bottom_margin=bottom_pad,
        dpi=dpi,
        right_margin=8Plots.mm,
        size=(1500, 520),
    )
    Plots.hspan!(p3, [0.0, active_sbl_top]; alpha=0.08, color=:gray65, label="")
    _savefig(Plots, p3, outdir, "fig03_hovmoller_theta", fmt)

    # Figure 3b: Time-height closure diagnostics (K_m and e_xi)
    km_plot = log10.(max.(hov_km, 1.0e-6))
    q_plot = sqrt.(max.(hov_exi, 1.0e-12))
    q_ref = median(vec(q_plot))
    q_norm = log10.(max.(q_plot ./ max(q_ref, 1.0e-12), 1.0e-8))

    p3b_a = Plots.heatmap(
        hov_t,
        zf_mid,
        permutedims(km_plot),
        xlabel="Time (h)",
        ylabel="z_face (m)",
        title="Figure 3b: Time-Height log10(K_m)",
        colorbar_title="log10(K_m)",
        c=:viridis,
        clims=_percentile_clims(km_plot; p_lo=0.005, p_hi=0.995),
        legend=:topright,
        ylims=(0, z_max),
        yticks=z_ticks,
        left_margin=left_pad,
        bottom_margin=bottom_pad,
        dpi=dpi,
    )
    p3b_b = Plots.heatmap(
        hov_t,
        zf_mid,
        permutedims(q_norm),
        xlabel="Time (h)",
        ylabel="z_face (m)",
        title="Time-Height log10(q / q_med), q=sqrt(e_xi)",
        colorbar_title="log10(q/q_med)",
        c=Plots.cgrad([:midnightblue, :royalblue3, :deepskyblue2, :gold1]),
        clims=_percentile_clims(q_norm; p_lo=0.005, p_hi=0.995),
        legend=:topright,
        ylims=(0, z_max),
        yticks=z_ticks,
        left_margin=left_pad,
        bottom_margin=bottom_pad,
        dpi=dpi,
    )
    p3b = Plots.plot(p3b_a, p3b_b; layout=(1, 2), size=(1500, 480), margin=8Plots.mm)
    _savefig(Plots, p3b, outdir, "fig03b_hovmoller_km_exi", fmt)

    # Figure 3d: Triheight diagnostic time series (declutters overlays on heatmaps)
    if triheight_available
        h_decoupling_plot = clamp.(h_decoupling, 0.0, z_max)
        h_energy_floor_plot = clamp.(h_energy_floor, 0.0, z_max)
        h_max_energy_gradient_plot = clamp.(h_max_energy_gradient, 0.0, z_max)

        p3d = Plots.plot(
            t_hours,
            h_decoupling_plot;
            linewidth=2.4,
            color=:gold3,
            xlabel="Time (h)",
            ylabel="Height (m)",
            title="Figure 3d: Triheight Diagnostics",
            label="h_D",
            legend=:topright,
            ylims=(0, z_max),
            yticks=z_ticks,
            left_margin=left_pad,
            bottom_margin=bottom_pad,
            dpi=dpi,
            size=(1300, 420),
        )
        Plots.plot!(p3d, t_hours, h_energy_floor_plot; linewidth=2.4, color=:deepskyblue3, label="h_e")
        Plots.plot!(p3d, t_hours, h_max_energy_gradient_plot; linewidth=2.4, color=:orangered3, label="h_∂e")
        _savefig(Plots, p3d, outdir, "fig03d_triheight_timeseries", fmt)
    end

    # Figure 3c: Startup zoom for Hovmoller diagnostics (captures rapid initial adjustment)
    zoom_h = min(0.30, maximum(hov_t))
    zoom_idx = findall(t -> t <= zoom_h, hov_t)
    if isempty(zoom_idx)
        zoom_idx = [1]
    end
    hov_t_zoom = hov_t[zoom_idx]
    hov_wind_zoom = hov_wind[zoom_idx, :]
    hov_theta_zoom = hov_theta[zoom_idx, :]
    km_zoom = km_plot[zoom_idx, :]
    qnorm_zoom = q_norm[zoom_idx, :]

    p2_zoom = Plots.heatmap(
        hov_t_zoom,
        zc,
        permutedims(hov_wind_zoom),
        xlabel="Time (h)",
        ylabel="z (m)",
        title="Wind Startup Zoom (0-$(round(zoom_h, digits=2)) h)",
        colorbar_title="|V| (m s^-1)",
        c=:inferno,
        clims=_percentile_clims(hov_wind; p_lo=0.005, p_hi=0.995),
        legend=:none,
        ylims=(0, z_max),
        yticks=z_ticks,
        left_margin=left_pad,
        bottom_margin=bottom_pad,
        dpi=dpi,
    )
    p3_zoom = Plots.heatmap(
        hov_t_zoom,
        zc,
        permutedims(hov_theta_zoom),
        xlabel="Time (h)",
        ylabel="z (m)",
        title="Theta Startup Zoom (0-$(round(zoom_h, digits=2)) h)",
        colorbar_title="theta (K)",
        c=:thermal,
        clims=_percentile_clims(hov_theta; p_lo=0.005, p_hi=0.995),
        legend=:none,
        ylims=(0, z_max),
        yticks=z_ticks,
        left_margin=left_pad,
        bottom_margin=bottom_pad,
        dpi=dpi,
    )
    pkm_zoom = Plots.heatmap(
        hov_t_zoom,
        zf_mid,
        permutedims(km_zoom),
        xlabel="Time (h)",
        ylabel="z_face (m)",
        title="log10(K_m) Startup Zoom",
        colorbar_title="log10(K_m)",
        c=:viridis,
        clims=_percentile_clims(km_plot; p_lo=0.005, p_hi=0.995),
        legend=:none,
        ylims=(0, z_max),
        yticks=z_ticks,
        left_margin=left_pad,
        bottom_margin=bottom_pad,
        dpi=dpi,
    )
    pq_zoom = Plots.heatmap(
        hov_t_zoom,
        zf_mid,
        permutedims(qnorm_zoom),
        xlabel="Time (h)",
        ylabel="z_face (m)",
        title="log10(q/q_med) Startup Zoom",
        colorbar_title="log10(q/q_med)",
        c=Plots.cgrad([:midnightblue, :royalblue3, :deepskyblue2, :gold1]),
        clims=_percentile_clims(q_norm; p_lo=0.005, p_hi=0.995),
        legend=:none,
        ylims=(0, z_max),
        yticks=z_ticks,
        left_margin=left_pad,
        bottom_margin=bottom_pad,
        dpi=dpi,
    )
    _savefig(Plots, p2_zoom, outdir, "fig03c_wind_startup_zoom", fmt)
    _savefig(Plots, p3_zoom, outdir, "fig03c_theta_startup_zoom", fmt)
    _savefig(Plots, pkm_zoom, outdir, "fig03c_km_startup_zoom", fmt)
    _savefig(Plots, pq_zoom, outdir, "fig03c_qnorm_startup_zoom", fmt)

    # =========================================================================
    # Figure 4: Vertical profiles
    # =========================================================================
    target_hours = unique([min(3.0, t_end_h), min(6.0, t_end_h), min(9.0, t_end_h)])
    t_idx = [_nearest_index(t_hours, th) for th in target_hours]
    line_colors = [:royalblue, :darkorange, :seagreen, :crimson]

    p4a = Plots.plot(xlabel="U (m s^-1)", ylabel="z (m)", title="U(z)", dpi=dpi, legend=:topleft, ylims=(0, z_max), yticks=z_ticks, left_margin=left_pad, bottom_margin=bottom_pad)
    p4b = Plots.plot(xlabel="theta (K)", ylabel="z (m)", title="theta(z)", dpi=dpi, legend=:none, ylims=(0, z_max), yticks=z_ticks, left_margin=left_pad, bottom_margin=bottom_pad)
    p4c = Plots.plot(xlabel="K_m (m^2 s^-1)", ylabel="z_face (m)", title="K_m(z)", dpi=dpi, legend=:none, ylims=(0, z_max), yticks=z_ticks, left_margin=left_pad, bottom_margin=bottom_pad)
    p4d = Plots.plot(
        xlabel="Ri_g",
        ylabel="z_face (m)",
        title="Ri_g(z)",
        dpi=dpi,
        xscale=:asinh,
        xguidefontsize=9,
        ylims=(0, z_max),
        yticks=z_ticks,
        left_margin=left_pad,
        bottom_margin=bottom_pad,
        legend=:topright,
    )

    for (i, idx) in enumerate(t_idx)
        row = ts[idx]
        tt = t_hours[idx]
        lbl = @sprintf("t=%.1f h", tt)
        col = line_colors[mod1(i, length(line_colors))]

        u_prof = _sanitize_finite(_getkey(row, :U))
        th_prof = _sanitize_finite(_getkey(row, :theta))
        km_prof = _sanitize_finite(_getkey(row, :Km_faces))
        ri_prof = _sanitize_finite(_getkey(row, :Ri_faces))

        Plots.plot!(p4a, u_prof, zc; label=lbl, linewidth=2, color=col)
        Plots.plot!(p4b, th_prof, zc; label="", linewidth=2, color=col)
        Plots.plot!(p4c, km_prof, zf[2:(end-1)]; label="", linewidth=2, color=col)
        Plots.plot!(p4d, ri_prof, zf[2:(end-1)]; label=lbl, linewidth=2, color=col)
    end

    Plots.vline!(p4d, [0.25]; color=:black, linestyle=:dash, linewidth=2, label="Ri_crit = 0.25")

    p4 = Plots.plot(p4a, p4b, p4c, p4d; layout=(1, 4), size=(1800, 450), margin=8Plots.mm)
    _savefig(Plots, p4, outdir, "fig04_profiles_u_theta_km", fmt)

    # =========================================================================
    # Figure 5: Surface energy budget
    # =========================================================================
    p5 = Plots.plot(
        t_hours,
        Rn;
        label="R_n",
        linewidth=2,
        xlabel="Time (h)",
        ylabel="Flux (W m^-2)",
        title="Figure 5: Surface Energy Budget",
        legend=:topright,
        dpi=dpi,
        right_margin=12Plots.mm,
    )
    Plots.plot!(p5, t_hours, H; label="H", linewidth=2)
    Plots.plot!(p5, t_hours, G; label="G", linewidth=2)
    Plots.plot!(p5, t_hours, storage; label="Storage", linewidth=2, linestyle=:dash)

    # Proxy legends for right-axis curves
    Plots.plot!(p5, [], []; label="T_s (right axis)", linewidth=2, color=:black)
    Plots.plot!(p5, [], []; label="T_rad (right axis)", linewidth=2, color=:gray35, linestyle=:dot)

    p5r = Plots.twinx(p5)
    Plots.plot!(p5r, t_hours, T_s; label="", linewidth=2, color=:black, ylabel="Temperature (K)")
    Plots.plot!(p5r, t_hours, T_rad; label="", linewidth=2, color=:gray35, linestyle=:dot)
    _savefig(Plots, p5, outdir, "fig05_surface_energy_budget", fmt)

    # =========================================================================
    # Figure 6: Closure response vs Ri_g
    # =========================================================================
    z_face_mid = zf[2:(end-1)]
    z_top = maximum(zf)
    z_surface_max = 0.2 * z_top
    z_mid_max = 0.6 * z_top
    ri_min_display = max(-0.5, minimum(_flatten_field(ts, :Ri_faces)))
    ri_max_display = 1.0

    ri_surface_band, q_surface_band, exi_surface_band = Float64[], Float64[], Float64[]
    ri_mid_band, q_mid_band, exi_mid_band = Float64[], Float64[], Float64[]
    ri_upper_band, q_upper_band, exi_upper_band = Float64[], Float64[], Float64[]

    for row in ts
        ri_vec = _getkey(row, :Ri_faces)
        dvec = _getkey(row, :Delta_faces)
        evec = _getkey(row, :e_xi_faces)
        for j in eachindex(dvec)
            zloc = z_face_mid[j]
            q_val = (Float64(_getkey(p, :l_0)) * dvec[j])^2 - Float64(_getkey(p, :delta))
            ri_val = ri_vec[j]
            if ri_val < ri_min_display || ri_val > ri_max_display
                continue
            elseif zloc <= z_surface_max
                push!(ri_surface_band, ri_vec[j])
                push!(q_surface_band, q_val)
                push!(exi_surface_band, evec[j])
            elseif zloc <= z_mid_max
                push!(ri_mid_band, ri_vec[j])
                push!(q_mid_band, q_val)
                push!(exi_mid_band, evec[j])
            else
                push!(ri_upper_band, ri_vec[j])
                push!(q_upper_band, q_val)
                push!(exi_upper_band, evec[j])
            end
        end
    end

    p6a = Plots.scatter(
        ri_surface_band,
        q_surface_band;
        markersize=2,
        alpha=0.5,
        color=:royalblue,
        xlabel="Ri_g",
        ylabel="Q = (l_0 \\Delta)^2 - \\delta",
        title="Q vs Ri_g",
        label="surface band (z <= 0.2 z_top)",
        legend=:topright,
        xlims=(ri_min_display, ri_max_display),
        dpi=dpi,
    )
    Plots.scatter!(p6a, ri_mid_band, q_mid_band; markersize=2, alpha=0.5, color=:darkorange, label="mid-BL (0.2-0.6 z_top)")
    Plots.scatter!(p6a, ri_upper_band, q_upper_band; markersize=2, alpha=0.5, color=:seagreen, label="upper (z > 0.6 z_top)")
    Plots.hline!(p6a, [0.0]; color=:black, linestyle=:dash, linewidth=2, label="Q = 0")

    p6b = Plots.scatter(
        ri_surface_band,
        exi_surface_band;
        markersize=2,
        alpha=0.5,
        color=:royalblue,
        xlabel="Ri_g",
        ylabel="e_xi",
        title="e_xi vs Ri_g",
        label="surface band (z <= 0.2 z_top)",
        legend=:topright,
        xlims=(ri_min_display, ri_max_display),
        dpi=dpi,
    )
    Plots.scatter!(p6b, ri_mid_band, exi_mid_band; markersize=2, alpha=0.5, color=:darkorange, label="mid-BL (0.2-0.6 z_top)")
    Plots.scatter!(p6b, ri_upper_band, exi_upper_band; markersize=2, alpha=0.5, color=:seagreen, label="upper (z > 0.6 z_top)")

    p6 = Plots.plot(p6a, p6b; layout=(1, 2), size=(1500, 480), margin=5Plots.mm)
    _savefig(Plots, p6, outdir, "fig06_phase_delta_exi", fmt)

    # =========================================================================
    # Figure 7: The GSPT Closure Manifold (4-Panel Geometry Analysis)
    # =========================================================================
    ri_all = Float64[]
    km_all = Float64[]
    kh_all = Float64[]
    delta_all = Float64[]
    shear_all = Float64[]
    z_all = Float64[]

    for row in ts
        ri_f = _sanitize_finite(_getkey(row, :Ri_faces))
        km_f = _sanitize_finite(_getkey(row, :Km_faces))
        kh_f = _sanitize_finite(_getkey(row, :Kh_faces))
        delta_f = _sanitize_finite(_getkey(row, :Delta_faces))

        shear_f = let s = _maybe_getkey(row, :shear_faces)
            s === nothing ? sqrt.(max.(_sanitize_finite(_getkey(row, :shear2_faces)), 0.0)) : _sanitize_finite(s)
        end

        zf_faces = zf[2:(end-1)]

        append!(ri_all, ri_f)
        append!(km_all, km_f)
        append!(kh_all, kh_f)
        append!(delta_all, delta_f)
        append!(shear_all, shear_f)
        append!(z_all, zf_faces)
    end

    valid_idx = findall(i -> isfinite(ri_all[i]) && isfinite(km_all[i]) && isfinite(kh_all[i]) && isfinite(delta_all[i]) && isfinite(shear_all[i]) && (ri_all[i] > 0.0), eachindex(ri_all))

    ri_v = ri_all[valid_idx]
    km_v = max.(km_all[valid_idx], 1.0e-6)
    kh_v = max.(kh_all[valid_idx], 1.0e-6)
    delta_v = delta_all[valid_idx]
    shear_v = max.(shear_all[valid_idx], 0.0)
    z_v = z_all[valid_idx]

    p7a = Plots.scatter(
        ri_v,
        km_v;
        zcolor=shear_v,
        c=:cividis,
        colorbar_title="Shear S (s^-1)",
        xlabel="Ri_g",
        ylabel="K_m (m^2 s^-1)",
        title="(a) K_m vs Ri_g (Color = Shear)",
        xscale=:asinh,
        yscale=:log10,
        alpha=0.6,
        markersize=3,
        markerstrokewidth=0,
        legend=:topright,
        left_margin=10Plots.mm,
        bottom_margin=8Plots.mm,
        dpi=dpi,
    )
    Plots.vline!(p7a, [0.25]; color=:red, linestyle=:dash, linewidth=1.5, label="Schematic Ri_crit = 0.25")

    p7b = Plots.scatter(
        ri_v,
        km_v;
        zcolor=z_v,
        c=:turbo,
        colorbar_title="Height z (m)",
        xlabel="Ri_g",
        ylabel="K_m (m^2 s^-1)",
        title="(b) K_m vs Ri_g (Color = Height)",
        xscale=:asinh,
        yscale=:log10,
        alpha=0.6,
        markersize=3,
        markerstrokewidth=0,
        legend=:none,
        left_margin=10Plots.mm,
        bottom_margin=8Plots.mm,
        dpi=dpi,
    )

    p7c = Plots.scatter(
        delta_v,
        km_v;
        zcolor=shear_v,
        c=:cividis,
        colorbar_title="Shear S (s^-1)",
        xlabel="Fold Invariant Delta",
        ylabel="K_m (m^2 s^-1)",
        title="(c) Manifold Collapse: K_m vs Delta",
        yscale=:log10,
        alpha=0.6,
        markersize=3,
        markerstrokewidth=0,
        legend=:topleft,
        left_margin=10Plots.mm,
        bottom_margin=8Plots.mm,
        dpi=dpi,
    )
    Plots.vline!(p7c, [0.0]; color=:black, linestyle=:solid, linewidth=1.5, label="Fold Threshold (Delta = 0)")

    pr_t_eff = km_v ./ max.(kh_v, 1.0e-12)
    p7d = Plots.scatter(
        ri_v,
        pr_t_eff;
        zcolor=shear_v,
        c=:cividis,
        colorbar_title="Shear S (s^-1)",
        xlabel="Ri_g",
        ylabel="Pr_t = K_m / K_h",
        title="(d) Dynamic Prandtl Number vs Ri_g",
        xscale=:asinh,
        alpha=0.6,
        markersize=3,
        markerstrokewidth=0,
        legend=:none,
        left_margin=10Plots.mm,
        bottom_margin=8Plots.mm,
        dpi=dpi,
    )

    p7 = Plots.plot(p7a, p7b, p7c, p7d; layout=(2, 2), size=(1400, 1000), margin=8Plots.mm, dpi=dpi)
    _savefig(Plots, p7, outdir, "fig07_closure_manifold", fmt)

    # =========================================================================
    # Figure 8: Quadratic fold-distance diagnostic vs time
    # =========================================================================
    l_0 = Float64(_getkey(p, :l_0))
    delta_p = Float64(_getkey(p, :delta))
    fold_distance = [(l_0 * Float64(val))^2 - delta_p for val in delta_surface]

    p8 = Plots.plot(
        t_hours,
        fold_distance;
        linewidth=2,
        xlabel="Time (h)",
        ylabel="Q = (l_0 \\Delta_{surface})^2 - \\delta",
        title="Figure 8: Quadratic Fold-Distance Diagnostic",
        label="Q(t)",
        legend=:topright,
        dpi=dpi,
    )
    Plots.hline!(p8, [0.0]; linewidth=2, linestyle=:dash, label="fold threshold Q = 0")
    _savefig(Plots, p8, outdir, "fig08_fold_proximity", fmt)

    manifest_path = joinpath(outdir, "figure_manifest.txt")
    open(manifest_path, "w") do io
        println(io, "Generated figures from payload: $(payload_path)")
        for fig in ("fig01_timeseries_ts_h_ustar", "fig02_hovmoller_wind", "fig03_hovmoller_theta",
            "fig03b_hovmoller_km_exi", "fig03c_wind_startup_zoom", "fig03c_theta_startup_zoom", "fig03c_km_startup_zoom", "fig03c_qnorm_startup_zoom", "fig04_profiles_u_theta_km", "fig05_surface_energy_budget",
            "fig06_phase_delta_exi", "fig07_closure_manifold", "fig08_fold_proximity")
            println(io, "- $(fig).$(fmt)")
        end
        if triheight_available
            println(io, "- fig03d_triheight_timeseries.$(fmt)")
        end
    end

    println("saved: $(manifest_path)")
end

function main(args)
    cfg = parse_args(args)
    payload = cfg["input"]
    isfile(payload) || error("Input payload not found: $(payload)")

    outdir = cfg["outdir"] == "" ? joinpath(dirname(payload), "plots") : cfg["outdir"]

    println("Generating manuscript figure suite...")
    @printf("  input : %s\n", payload)
    @printf("  out   : %s\n", outdir)
    @printf("  fmt   : %s\n", cfg["format"])

    generate_figures(payload, outdir, cfg["format"], cfg["dpi"])

    println("Figure generation complete.")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end