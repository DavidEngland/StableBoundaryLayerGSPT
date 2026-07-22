#!/usr/bin/env julia
# scripts/plot_regime_map_z0m_ug.jl
# Figure Concept 5: Regime map in (z0m, U_g) space with campaign markers.

using JSON
using Plots

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

function closure_gamma(z0m::Float64, p::Dict{String,Any})
    kappa = Float64(p["kappa"])
    gamma_efficiency = Float64(get(p, "gamma_efficiency", 1.0))
    h = Float64(p["h"])
    log_m = log(h / z0m)
    return gamma_efficiency * (kappa^2 / (log_m^2))
end

function stability_response(Ts::Float64, p::Dict{String,Any})
    Ta = Float64(p["T_a"])
    beta = Float64(p["beta"])
    return tanh(beta * (Ta - Ts) / Ta)
end

# Regime classes:
# 1 = Continuous weak turbulence (Green)
# 2 = Intermittent relaxation oscillations (Gold)
# 3 = Runaway decoupling (Red)
function regime_class(Ug::Float64, z0m::Float64, p::Dict{String,Any}, Ts_ref::Float64)
    eta = Float64(get(p, "shear_production_efficiency", 1.0))
    Kb = Float64(p["K"])
    gamma = closure_gamma(z0m, p)
    G = stability_response(Ts_ref, p)

    denom = eta * max(gamma, eps(Float64))
    Sc = sqrt(max(Kb * G / denom, 0.0))
    ratio = Ug / max(Sc, 1.0e-8)

    if ratio >= 1.25
        return 1.0  # Regime I: Weak Turbulence (Green)
    elseif ratio <= 0.85
        return 3.0  # Regime III: Decoupling (Red)
    else
        return 2.0  # Regime II: Intermittent (Gold)
    end
end

function main(args::Vector{String})
    cfg = parse_args(args)

    cases = load_summary("CASES99")
    floss = load_summary("FLOSS")
    sheba = load_summary("SHEBA")

    p_ref = Dict{String,Any}(cases["parameters"])

    Ta = Float64(p_ref["T_a"])
    Ts_ref = Ta - 4.0

    ug_vals = collect(range(Float64(cfg["ug_min"]), Float64(cfg["ug_max"]); length=Int(cfg["ug_n"])))

    # 1. Transform z0m to log10 coordinate space to bypass GR heatmap bug
    log_z0m_min = log10(Float64(cfg["z0m_min"]))
    log_z0m_max = log10(Float64(cfg["z0m_max"]))
    log_z0m_vals = collect(range(log_z0m_min, log_z0m_max; length=Int(cfg["z0m_n"])))
    z0m_vals = 10.0 .^ log_z0m_vals

    # 2. Populate (N_x x N_y) matrix where x -> z0m and y -> Ug
    regime = Array{Float64}(undef, length(log_z0m_vals), length(ug_vals))
    for (j, Ug) in enumerate(ug_vals), (i, z0m) in enumerate(z0m_vals)
        regime[i, j] = regime_class(Ug, z0m, p_ref, Ts_ref)
    end

    # Explicit palette: 1 = Green (Weak Turb), 2 = Gold (Intermittent), 3 = Red (Decoupling)
    cmap = cgrad([:seagreen3, :goldenrod2, :firebrick2], 3; categorical=true)

    # Custom log-space tick labels
    xticks_pos = [-4.0, -3.0, -2.0, -1.301]
    xticks_lbl = ["10⁻⁴", "10⁻³", "10⁻²", "0.05"]

    # 3. Transpose regime' so size is (N_y x N_x) matching (length(ug_vals), length(log_z0m_vals))
    plt = heatmap(
        log_z0m_vals,
        ug_vals,
        regime';
        c=cmap,
        xlabel="Momentum Roughness Length z₀ₘ (m)",
        ylabel="Geostrophic Forcing U_g (m s⁻¹)",
        title="Regime Bifurcation Map: Roughness vs Geostrophic Forcing",
        colorbar_title="Operational Regime",
        clims=(1.0, 3.0),
        xticks=(xticks_pos, xticks_lbl),
        colorbar_ticks=([1.33, 2.0, 2.67], ["I: Weak Turb.", "II: Intermittent", "III: Decoupling"]),
        dpi=240,
        size=(1200, 760),
        right_margin=12Plots.mm,
        left_margin=8Plots.mm,
        bottom_margin=8Plots.mm,
    )

    # Overlay campaign markers on the log_z0m axis
    datasets = [
        ("CASES99", Dict{String,Any}(cases["parameters"]), :diamond),
        ("FLOSS", Dict{String,Any}(floss["parameters"]), :utriangle),
        ("SHEBA", Dict{String,Any}(sheba["parameters"]), :star5),
    ]

    # Guard against malformed roughness entries in run summaries.
    marker_z0m_fallback = Dict(
        "CASES99" => 2.0e-2,
        "FLOSS" => 1.0e-4,
        "SHEBA" => 5.0e-4,
    )

    for (name, p, mk) in datasets
        z0m = Float64(p["z0m"])
        if !(Float64(cfg["z0m_min"]) <= z0m <= Float64(cfg["z0m_max"]))
            z0m = marker_z0m_fallback[name]
        end
        Ug = Float64(p["U_g"])
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

        # Crisp white text annotation above marker
        dx = name == "FLOSS" ? 0.08 : 0.0
        x_text = clamp(log_z0m + dx, minimum(log_z0m_vals) + 0.03, maximum(log_z0m_vals) - 0.03)
        annotate!(plt, x_text, Ug + 0.45, text(name, 10, :bold, :white))
    end

    mkpath(dirname(String(cfg["out"])))
    savefig(plt, String(cfg["out"]))
    println("Saved corrected regime map: $(cfg["out"])")
end

main(ARGS)