#!/usr/bin/env julia

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
    k_min_surf::T
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

function _getkey(x, key::Symbol)
    if hasproperty(x, key)
        return getproperty(x, key)
    elseif x isa AbstractDict
        if haskey(x, key)
            return x[key]
        end
        skey = String(key)
        if haskey(x, skey)
            return x[skey]
        end
    end
    error("Missing key/property: $(key)")
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

function _savefig(Plots, fig, outdir::String, stem::String, ext::String)
    path = joinpath(outdir, string(stem, ".", ext))
    Plots.savefig(fig, path)
    println("saved: $(path)")
    return path
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

    zc = collect(Float64, _getkey(hov, :z_centers))
    zf = collect(Float64, _getkey(hov, :z_faces))
    hov_t = collect(Float64, _getkey(hov, :t)) ./ 3600.0
    hov_wind = Array{Float64}(undef, size(_getkey(hov, :wind))...)
    hov_wind .= _getkey(hov, :wind)
    hov_theta = Array{Float64}(undef, size(_getkey(hov, :theta))...)
    hov_theta .= _getkey(hov, :theta)

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

    p1 = Plots.plot(p1a, p1b; layout=(2, 1), size=(1100, 750), margin=5Plots.mm)
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
        dpi=dpi,
    )
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
        dpi=dpi,
    )
    _savefig(Plots, p3, outdir, "fig03_hovmoller_theta", fmt)

    # =========================================================================
    # Figure 4: Vertical profiles [Consolidated Legend Only on Panel A]
    # =========================================================================
    target_hours = unique([min(3.0, t_end_h), min(6.0, t_end_h), min(9.0, t_end_h)])
    t_idx = [_nearest_index(t_hours, th) for th in target_hours]

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
        legend=:topright, # Preserve separate legend here for the Ri_crit threshold
    )

    for idx in t_idx
        row = ts[idx]
        tt = t_hours[idx]
        lbl = @sprintf("t=%.1f h", tt)
        Plots.plot!(p4a, _getkey(row, :U), zc; label=lbl, linewidth=2)
        Plots.plot!(p4b, _getkey(row, :theta), zc; label="", linewidth=2)
        Plots.plot!(p4c, _getkey(row, :Km_faces), zf[2:(end-1)]; label="", linewidth=2)
        Plots.plot!(p4d, _getkey(row, :Ri_faces), zf[2:(end-1)]; label=lbl, linewidth=2)
    end

    Plots.vline!(p4d, [0.25]; color=:black, linestyle=:dash, linewidth=2, label="Ri_crit = 0.25")

    p4 = Plots.plot(p4a, p4b, p4c, p4d; layout=(1, 4), size=(1760, 420))
    _savefig(Plots, p4, outdir, "fig04_profiles_u_theta_km", fmt)

    # =========================================================================
    # Figure 5: Surface energy budget [Merged Dual-Axis Legend]
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
    )
    Plots.plot!(p5, t_hours, H; label="H", linewidth=2)
    Plots.plot!(p5, t_hours, G; label="G", linewidth=2)
    Plots.plot!(p5, t_hours, storage; label="Storage", linewidth=2, linestyle=:dash)

    # Register right-axis labels as empty series to bring them into the unified legend box
    Plots.plot!(p5, [], []; label="T_s (right axis)", linewidth=2, color=:black)
    Plots.plot!(p5, [], []; label="T_rad (right axis)", linewidth=2, color=:gray35, linestyle=:dot)

    p5r = Plots.twinx(p5)
    Plots.plot!(p5r, t_hours, T_s; label="", linewidth=2, color=:black, ylabel="Temperature (K)")
    Plots.plot!(p5r, t_hours, T_rad; label="", linewidth=2, color=:gray35, linestyle=:dot)
    _savefig(Plots, p5, outdir, "fig05_surface_energy_budget", fmt)

    # =========================================================================
    # Figure 6: Closure response vs Ri_g, colored by height band
    # =========================================================================
    z_face_mid = zf[2:(end-1)]
    z_top = maximum(zf)
    z_surface_max = 0.2 * z_top
    z_mid_max = 0.6 * z_top
    ri_min_display = max(-0.5, minimum(_flatten_field(ts, :Ri_faces)))
    ri_max_display = 1.0

    ri_surface_band = Float64[]
    q_surface_band = Float64[]
    exi_surface_band = Float64[]
    ri_mid_band = Float64[]
    q_mid_band = Float64[]
    exi_mid_band = Float64[]
    ri_upper_band = Float64[]
    q_upper_band = Float64[]
    exi_upper_band = Float64[]

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
    Plots.scatter!(
        p6a,
        ri_mid_band,
        q_mid_band;
        markersize=2,
        alpha=0.5,
        color=:darkorange,
        label="mid-BL / jet band (0.2-0.6 z_top)",
    )
    Plots.scatter!(
        p6a,
        ri_upper_band,
        q_upper_band;
        markersize=2,
        alpha=0.5,
        color=:seagreen,
        label="upper band (z > 0.6 z_top)",
    )

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
    Plots.scatter!(
        p6b,
        ri_mid_band,
        exi_mid_band;
        markersize=2,
        alpha=0.5,
        color=:darkorange,
        label="mid-BL / jet band (0.2-0.6 z_top)",
    )
    Plots.scatter!(
        p6b,
        ri_upper_band,
        exi_upper_band;
        markersize=2,
        alpha=0.5,
        color=:seagreen,
        label="upper band (z > 0.6 z_top)",
    )

    p6 = Plots.plot(p6a, p6b; layout=(1, 2), size=(1500, 480))
    _savefig(Plots, p6, outdir, "fig06_phase_delta_exi", fmt)

    # Figure 7: Diffusivity response vs Ri
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

    ri_zoom = ri_all[keep]
    km_zoom = km_all[keep]
    kh_zoom = kh_all[keep]

    p7a = Plots.scatter(
        ri_zoom,
        km_zoom;
        markersize=2,
        alpha=0.5,
        xlabel="Ri_g",
        ylabel="K_m",
        title="K_m vs Ri_g (Ri_g <= 2)",
        xlims=(ri_min_display, ri_max_display),
        bottom_margin=8Plots.mm,
        left_margin=6Plots.mm,
        label="",
        legend=:none,
        dpi=dpi,
    )
    p7b = Plots.scatter(
        ri_zoom,
        kh_zoom;
        markersize=2,
        alpha=0.5,
        xlabel="Ri_g",
        ylabel="K_h",
        title="K_h vs Ri_g (Ri_g <= 2)",
        xlims=(ri_min_display, ri_max_display),
        bottom_margin=8Plots.mm,
        left_margin=6Plots.mm,
        label="",
        legend=:none,
        dpi=dpi,
    )
    p7 = Plots.plot(p7a, p7b; layout=(1, 2), size=(1280, 460))
    _savefig(Plots, p7, outdir, "fig07_diffusivity_vs_ri", fmt)

    # Figure 8: Quadratic fold-distance diagnostic vs time
    fold_distance = [(Float64(_getkey(p, :l_0)) * Float64(val))^2 - Float64(_getkey(p, :delta)) for val in delta_surface]
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
        println(io, "- fig01_timeseries_ts_h_ustar.$(fmt)")
        println(io, "- fig02_hovmoller_wind.$(fmt)")
        println(io, "- fig03_hovmoller_theta.$(fmt)")
        println(io, "- fig04_profiles_u_theta_km.$(fmt)")
        println(io, "- fig05_surface_energy_budget.$(fmt)")
        println(io, "- fig06_phase_delta_exi.$(fmt)")
        println(io, "- fig07_diffusivity_vs_ri.$(fmt)")
        println(io, "- fig08_fold_proximity.$(fmt)")
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