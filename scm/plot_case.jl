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

function _savefig(Plots, fig, outdir::String, stem::String, ext::String)
    path = joinpath(outdir, string(stem, ".", ext))
    Plots.savefig(fig, path)
    println("saved: $(path)")
    return path
end

function _overlay_triheight_tracks!(Plots, plt, t_hours, h_decoupling, h_energy_floor, h_max_energy_gradient; with_legend::Bool=true)
    d_label = with_legend ? "h_D" : ""
    e_label = with_legend ? "h_e" : ""
    g_label = with_legend ? "h_∂e" : ""

    Plots.plot!(
        plt,
        t_hours,
        h_decoupling;
        linewidth=2.2,
        linestyle=:dash,
        color=:gold3,
        alpha=0.95,
        label=d_label,
    )
    Plots.plot!(
        plt,
        t_hours,
        h_energy_floor;
        linewidth=2.2,
        linestyle=:dash,
        color=:deepskyblue3,
        alpha=0.95,
        label=e_label,
    )
    Plots.plot!(
        plt,
        t_hours,
        h_max_energy_gradient;
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
        dpi=dpi,
        right_margin=6Plots.mm,
    )
    if triheight_available
        _overlay_triheight_tracks!(Plots, p2, t_hours, h_decoupling, h_energy_floor, h_max_energy_gradient; with_legend=true)
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
        dpi=dpi,
        right_margin=6Plots.mm,
    )
    if triheight_available
        _overlay_triheight_tracks!(Plots, p3, t_hours, h_decoupling, h_energy_floor, h_max_energy_gradient; with_legend=false)
    end
    _savefig(Plots, p3, outdir, "fig03_hovmoller_theta", fmt)

    # Figure 3b: Time-height closure diagnostics (K_m and e_xi)
    p3b_a = Plots.heatmap(
        hov_t,
        zf_mid,
        permutedims(hov_km),
        xlabel="Time (h)",
        ylabel="z_face (m)",
        title="Figure 3b: Time-Height K_m",
        colorbar_title="K_m (m^2 s^-1)",
        c=:viridis,
        clims=_safe_clims(hov_km),
        legend=:topright,
        dpi=dpi,
    )
    p3b_b = Plots.heatmap(
        hov_t,
        zf_mid,
        permutedims(hov_exi),
        xlabel="Time (h)",
        ylabel="z_face (m)",
        title="Time-Height e_xi",
        colorbar_title="e_xi",
        c=:inferno,
        clims=_safe_clims(hov_exi),
        legend=:topright,
        dpi=dpi,
    )
    if triheight_available
        _overlay_triheight_tracks!(Plots, p3b_a, t_hours, h_decoupling, h_energy_floor, h_max_energy_gradient; with_legend=true)
        _overlay_triheight_tracks!(Plots, p3b_b, t_hours, h_decoupling, h_energy_floor, h_max_energy_gradient; with_legend=false)
    end
    p3b = Plots.plot(p3b_a, p3b_b; layout=(1, 2), size=(1500, 480), margin=5Plots.mm)
    _savefig(Plots, p3b, outdir, "fig03b_hovmoller_km_exi", fmt)

    # =========================================================================
    # Figure 4: Vertical profiles
    # =========================================================================
    target_hours = unique([min(3.0, t_end_h), min(6.0, t_end_h), min(9.0, t_end_h)])
    t_idx = [_nearest_index(t_hours, th) for th in target_hours]
    line_colors = [:royalblue, :darkorange, :seagreen, :crimson]

    p4a = Plots.plot(xlabel="U (m s^-1)", ylabel="z (m)", title="U(z)", dpi=dpi, legend=:topleft)
    p4b = Plots.plot(xlabel="theta (K)", ylabel="z (m)", title="theta(z)", dpi=dpi, legend=:none)
    p4c = Plots.plot(xlabel="K_m (m^2 s^-1)", ylabel="z_face (m)", title="K_m(z)", dpi=dpi, legend=:none)
    p4d = Plots.plot(
        xlabel="Ri_g",
        ylabel="z_face (m)",
        title="Ri_g(z)",
        dpi=dpi,
        xscale=:asinh,
        xguidefontsize=9,
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

    p4 = Plots.plot(p4a, p4b, p4c, p4d; layout=(1, 4), size=(1760, 420), margin=6Plots.mm)
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
    # Figure 7: Diffusivity response vs Ri
    # =========================================================================
    ri_all = _flatten_field(ts, :Ri_faces)
    km_all = _flatten_field(ts, :Km_faces)
    kh_all = _flatten_field(ts, :Kh_faces)

    ri_max_display = 2.0
    ri_min_display = max(minimum(ri_all), -0.5)
    keep = [
        isfinite(ri_all[i]) && isfinite(km_all[i]) && isfinite(kh_all[i]) &&
        (ri_all[i] >= ri_min_display) && (ri_all[i] <= ri_max_display)
        for i in eachindex(ri_all)
    ]

    p7a = Plots.scatter(
        ri_all[keep],
        km_all[keep];
        markersize=2,
        alpha=0.5,
        xlabel="Ri_g",
        ylabel="K_m",
        title="K_m vs Ri_g (Ri_g <= 2)",
        xlims=(ri_min_display, ri_max_display),
        label="",
        legend=:none,
        dpi=dpi,
    )
    p7b = Plots.scatter(
        ri_all[keep],
        kh_all[keep];
        markersize=2,
        alpha=0.5,
        xlabel="Ri_g",
        ylabel="K_h",
        title="K_h vs Ri_g (Ri_g <= 2)",
        xlims=(ri_min_display, ri_max_display),
        label="",
        legend=:none,
        dpi=dpi,
    )
    p7 = Plots.plot(p7a, p7b; layout=(1, 2), size=(1280, 460), margin=6Plots.mm)
    _savefig(Plots, p7, outdir, "fig07_diffusivity_vs_ri", fmt)

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
            "fig03b_hovmoller_km_exi", "fig04_profiles_u_theta_km", "fig05_surface_energy_budget",
            "fig06_phase_delta_exi", "fig07_diffusivity_vs_ri", "fig08_fold_proximity")
            println(io, "- $(fig).$(fmt)")
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