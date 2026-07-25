#!/usr/bin/env julia
# scripts/plot_regime_map_z0m_ug.jl
# Figure Concept 5: Analytical Regime Map in (z0m, U_g) Parameter Space with campaign markers.

using JSON
using Plots
using Plots.PlotMeasures

# --- Script Constants ---
const RATIO_UPPER = 1.25   # Weak Turbulence / Intermittent boundary threshold
const RATIO_LOWER = 0.85   # Intermittent / Runaway Collapse boundary threshold

function usage()
    println("Usage: julia scripts/plot_regime_map_z0m_ug.jl [options]")
    println("Options:")
    println("  --out <path>          Output PNG path (default: reports/generated/figures/regime_map_z0m_ug.png)")
    println("  --ug-min <value>      Min U_g (default: 2.0)")
    println("  --ug-max <value>      Max U_g (default: 15.0)")
    println("  --ug-n <int>          Number of U_g samples (default: 150)")
    println("  --z0m-min <value>     Min z0m (default: 1e-4)")
    println("  --z0m-max <value>     Max z0m (default: 5e-2)")
    println("  --z0m-n <int>         Number of z0m samples (default: 150)")
    println("  --help                Show this help message")
end

function parse_args(args::Vector{String})
    cfg = Dict{String,Any}(
        "out" => joinpath("reports", "generated", "figures", "regime_map_z0m_ug.png"),
        "ug_min" => 2.0,
        "ug_max" => 15.0,
        "ug_n" => 150,
        "z0m_min" => 1.0e-4,
        "z0m_max" => 5.0e-2,
        "z0m_n" => 150,
    )

    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--help"
            usage()
            exit(0)
        elseif a == "--out" && i < length(args)
            cfg["out"] = args[i+1]
            i += 2
        elseif a == "--ug-min" && i < length(args)
            cfg["ug_min"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--ug-max" && i < length(args)
            cfg["ug_max"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--ug-n" && i < length(args)
            cfg["ug_n"] = parse(Int, args[i+1])
            i += 2
        elseif a == "--z0m-min" && i < length(args)
            cfg["z0m_min"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--z0m-max" && i < length(args)
            cfg["z0m_max"] = parse(Float64, args[i+1])
            i += 2
        elseif a == "--z0m-n" && i < length(args)
            cfg["z0m_n"] = parse(Int, args[i+1])
            i += 2
        else
            error("Unknown or incomplete argument: $(a)")
        end
    end

    return cfg
end

function load_summary(dataset::String)
    path = joinpath("results", dataset, "latest", "summary.json")
    if !isfile(path)
        dirs = filter(isdir, readdir(joinpath("results", dataset), join=true))
        if !isempty(dirs)
            sort!(dirs, by=mtime, rev=true)
            path = joinpath(dirs[1], "summary.json")
        end
    end
    isfile(path) || error("Missing summary file for $(dataset): $(path)")
    return JSON.parsefile(path)
end

# Formatting integer exponents to Unicode superscript
function to_superscript(n::Int)
    superscripts = Dict('0'=>'⁰', '1'=>'¹', '2'=>'²', '3'=>'³', '4'=>'⁴',
        '5'=>'⁵', '6'=>'⁶', '7'=>'⁷', '8'=>'⁸', '9'=>'⁹', '-'=>'⁻')
    return join([get(superscripts, c, c) for c in string(n)])
end

# Surface-layer drag coefficient C_D evaluated at first node height z1 = 2.0m
function closure_gamma(z0m::Float64, p::Dict{String,Any})
    kappa = Float64(get(p, "kappa", 0.4))
    gamma_efficiency = Float64(get(p, "gamma_efficiency", 1.0))
    z1 = 2.0 # First node surface layer height (m)
    log_m = log(max(z1 / z0m, 1.05))
    return gamma_efficiency * (kappa^2 / (log_m^2))
end

function stability_response(Ts::Float64, p::Dict{String,Any})
    Ta = Float64(get(p, "T_a", 273.15))
    beta = Float64(get(p, "beta", 1.0))
    return tanh(beta * (Ta - Ts) / Ta)
end

function regime_class(Ug::Float64, gamma::Float64, p::Dict{String,Any}, Ts_ref::Float64)
    eta = Float64(get(p, "shear_production_efficiency", 1.0))
    Kb = Float64(get(p, "K", 0.05))
    G = stability_response(Ts_ref, p)

    denom = eta * max(gamma, eps(Float64))
    Sc = sqrt(max(Kb * G / denom, 0.0))
    ratio = Ug / max(Sc, 1.0e-8)

    if ratio >= RATIO_UPPER
        return 1.0  # Regime I: Weak Turbulence
    elseif ratio <= RATIO_LOWER
        return 3.0  # Regime III: Runaway Decoupling
    else
        return 2.0  # Regime II: Intermittent
    end
end

function main(args::Vector{String})
    cfg = parse_args(args)

    cases = load_summary("CASES99")
    floss = load_summary("FLOSS")
    sheba = load_summary("SHEBA")

    p_ref = Dict{String,Any}(cases["parameters"])
    eta = Float64(get(p_ref, "shear_production_efficiency", 1.0))
    Kb = Float64(get(p_ref, "K", 0.05))

    Ta = Float64(get(p_ref, "T_a", 273.15))
    Ts_ref = Ta - 4.0

    ug_vals = collect(range(Float64(cfg["ug_min"]), Float64(cfg["ug_max"]); length=Int(cfg["ug_n"])))

    # 1. Log-transformed z0m coordinates
    log_z0m_min = log10(Float64(cfg["z0m_min"]))
    log_z0m_max = log10(Float64(cfg["z0m_max"]))
    log_z0m_vals = collect(range(log_z0m_min, log_z0m_max; length=Int(cfg["z0m_n"])))
    z0m_vals = 10.0 .^ log_z0m_vals

    # 2. Precompute drag coefficient
    gamma_vals = closure_gamma.(z0m_vals, Ref(p_ref))

    # 3. Populate regime matrix (transposed for heatmap convention [x, y])
    regime = [regime_class(ug, g, p_ref, Ts_ref) for g in gamma_vals, ug in ug_vals]

    # 4. Color palette & Categorical limits
    cmap = cgrad([:seagreen3, :goldenrod2, :firebrick2], 3; categorical=true)

    # Dynamic log ticks generation
    log_start = floor(Int, log_z0m_min)
    log_stop = ceil(Int, log_z0m_max)
    xticks_pos = Float64.(log_start:log_stop)
    xticks_lbl = ["10$(to_superscript(k))" for k in log_start:log_stop]

    plt = heatmap(
        log_z0m_vals,
        ug_vals,
        regime';
        c=cmap,
        xlabel="Momentum Roughness Length z₀ₘ (m)",
        ylabel="Geostrophic Forcing U_g (m s⁻¹)",
        title="Analytical Regime Map in (z₀ₘ, U_g) Parameter Space",
        colorbar_title="Analytical Regime",
        clims=(0.5, 3.5),
        xticks=(xticks_pos, xticks_lbl),
        colorbar_ticks=([1.0, 2.0, 3.0], ["Weak turbulence", "Intermittent", "Runaway decoupling"]),
        dpi=240,
        size=(1200, 760),
        right_margin=12mm,
        left_margin=8mm,
        bottom_margin=8mm,
    )

    # 5. Transition boundary curves
    G_val = stability_response(Ts_ref, p_ref)
    ug_bnd_upper = [RATIO_UPPER * sqrt(max(Kb * G_val / (eta * max(g, eps(Float64))), 0.0)) for g in gamma_vals]
    ug_bnd_lower = [RATIO_LOWER * sqrt(max(Kb * G_val / (eta * max(g, eps(Float64))), 0.0)) for g in gamma_vals]

    plot!(plt, log_z0m_vals, ug_bnd_upper; line=(2, :dash, :black), label="Upper transition (Weak/Intermittent)")
    plot!(plt, log_z0m_vals, ug_bnd_lower; line=(2, :dot, :black), label="Lower transition (Intermittent/Collapse)")

    # 6. DYNAMIC REGIME ANNOTATIONS
    # Evaluate analytical bounds at horizontal midpoint to dynamically center regime text
    mid_idx = length(log_z0m_vals) ÷ 2
    x_mid = log_z0m_vals[mid_idx]

    ymin, ymax = extrema(ug_vals)
    y_bnd_up_mid = clamp(ug_bnd_upper[mid_idx], ymin, ymax)
    y_bnd_low_mid = clamp(ug_bnd_lower[mid_idx], ymin, ymax)

    # Compute midpoints between limits/boundaries for each region
    y_pos_regimeI = (ymax + y_bnd_up_mid) / 2.0
    y_pos_regimeII = (y_bnd_up_mid + y_bnd_low_mid) / 2.0
    y_pos_regimeIII = (y_bnd_low_mid + ymin) / 2.0

    if (ymax - y_bnd_up_mid) > 0.05 * (ymax - ymin)
        annotate!(plt, x_mid, y_pos_regimeI, text("REGIME I\nWeak Turbulence", 11, :bold, :white, :center))
    end
    if (y_bnd_up_mid - y_bnd_low_mid) > 0.05 * (ymax - ymin)
        annotate!(plt, x_mid, y_pos_regimeII, text("REGIME II\nIntermittent", 11, :bold, :black, :center))
    end
    if (y_bnd_low_mid - ymin) > 0.05 * (ymax - ymin)
        annotate!(plt, x_mid, y_pos_regimeIII, text("REGIME III\nDecoupled", 11, :bold, :white, :center))
    end

    # 7. Campaign markers
    marker_z0m_fallback = Dict(
        "CASES99" => 2.0e-2,
        "FLOSS" => 1.0e-4,
        "SHEBA" => 5.0e-4,
    )

    datasets = [
        ("CASES99", Dict{String,Any}(cases["parameters"]), :diamond),
        ("FLOSS", Dict{String,Any}(floss["parameters"]), :utriangle),
        ("SHEBA", Dict{String,Any}(sheba["parameters"]), :star5),
    ]

    xmin, xmax = extrema(log_z0m_vals)
    dx_range = xmax - xmin
    dy_range = ymax - ymin

    for (name, p, mk) in datasets
        z0m_raw = get(p, "z0m", missing)
        z0m = ismissing(z0m_raw) ? marker_z0m_fallback[name] : Float64(z0m_raw)

        # Handle FLOSS canopy/measurement height anomaly safely
        if z0m > 0.1
            z0m = marker_z0m_fallback[name]
        end

        Ug = Float64(get(p, "U_g", 10.0))
        log_z0m = log10(z0m)

        scatter!(
            plt,
            [log_z0m],
            [Ug];
            marker=mk,
            markersize=12,
            markercolor=:white,
            markerstrokecolor=:black,
            markerstrokewidth=2.0,
            label=name
        )

        # Adaptive marker label placement
        dx = 0.02 * dx_range
        dy = 0.03 * dy_range
        x_text = clamp(log_z0m + dx, xmin + 0.02 * dx_range, xmax - 0.12 * dx_range)
        y_text = clamp(Ug + dy, ymin + 0.03 * dy_range, ymax - 0.03 * dy_range)

        annotate!(plt, x_text, y_text, text(name, 10, :bold, :black, :left))
    end

    mkpath(dirname(String(cfg["out"])))
    savefig(plt, String(cfg["out"]))
    println("Saved restored regime map: $(cfg["out"])")
end

main(ARGS)