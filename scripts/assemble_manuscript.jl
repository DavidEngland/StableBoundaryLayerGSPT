#!/usr/bin/env julia
# scripts/assemble_manuscript.jl
using CSV
using DataFrames
using Dates
using JSON3
using LinearAlgebra
using Printf
using Statistics

include(joinpath(@__DIR__, "lib", "utils.jl"))
include(joinpath(@__DIR__, "generate_symbols.jl"))

const DEFAULT_DATASET = "CASES99"
const DEFAULT_GENERATED_DATE_HUMAN = "July 13, 2026"
const SUPPORTED_DATASETS = ["CASES99", "FLOSS", "SHEBA"]
const DEFAULT_PROSE_LINT_ALLOWLIST_PATH = "config/prose_lint_allowlist.txt"
const RAW_TEMPLATE_SUFFIXES = ("_tex", "_includes", "_blocks")
const PROVENANCE_PARAM_KEYS = [
    "epsilon",
    "delta",
    "xi",
    "beta",
    "beta_t",
    "sigma_e",
    "h",
    "l0",
    "z0m",
    "z0h",
    "T_deep",
    "U_g",
    "R_down",
    "f_coriolis",
    "K",
    "kappa",
    "nonlocal_h_min",
    "nonlocal_h_max",
    "nonlocal_h_weight",
    "shear_production_efficiency",
    "d_soil",
    "rho_cp",
    "lambda_soil",
    "sigma_sb",
]

function first_existing_dir(paths::Vector{String})
    for path in paths
        if isdir(path)
            entries = filter(name -> name != ".gitkeep", readdir(path))
            if !isempty(entries)
                return path
            end
        end
    end
    return first(paths)
end

function parse_args(args::Vector{String})
    dataset = DEFAULT_DATASET
    generated_date_human = DEFAULT_GENERATED_DATE_HUMAN
    write_parameter_macros_only = false
    check_parameter_drift = false
    lint_prose_literals = false
    lint_prose_strict = false
    lint_prose_allowlist_path = DEFAULT_PROSE_LINT_ALLOWLIST_PATH

    i = 1
    while i <= length(args)
        arg = args[i]
        if arg == "--dataset" && i < length(args)
            dataset = args[i+1]
            i += 2
        elseif arg == "--date" && i < length(args)
            generated_date_human = args[i+1]
            i += 2
        elseif arg == "--write-parameter-macros-only"
            write_parameter_macros_only = true
            i += 1
        elseif arg == "--check-parameter-drift"
            check_parameter_drift = true
            i += 1
        elseif arg == "--lint-prose-literals"
            lint_prose_literals = true
            i += 1
        elseif arg == "--lint-prose-strict"
            lint_prose_strict = true
            i += 1
        elseif arg == "--lint-prose-allowlist" && i < length(args)
            lint_prose_allowlist_path = args[i+1]
            i += 2
        else
            error("Unknown or incomplete argument: $(arg)")
        end
    end
    return uppercase(String(strip(dataset))), String(strip(generated_date_human)), write_parameter_macros_only, check_parameter_drift, lint_prose_literals, lint_prose_strict, String(strip(lint_prose_allowlist_path))
end

function read_text(path::String; fallback::String="")
    return isfile(path) ? read(path, String) : fallback
end

function should_render_raw(key::String)
    return any(suffix -> endswith(key, suffix), RAW_TEMPLATE_SUFFIXES)
end

function render_template(template::String, context::Dict{String,String}; escape_values::Bool=true)
    rendered = template
    for (k, v) in context
        escaped = escape_values ? latex_escape(v) : v
        rendered = replace(rendered, "{{{$(k)}}}" => v)
        rendered = replace(rendered, "{{$(k)}}" => (should_render_raw(k) ? v : escaped))
    end
    return rendered
end

function build_optional_tex_template(path::String, context::Dict{String,String}; fallback::String="")
    if !isfile(path)
        return fallback
    end
    rendered = render_template(read_text(path), context)
    return "% --- Begin Section: $(path) ---\n" * rendered * "\n% --- End Section: $(path) ---"
end

function build_tex_template_sections(section_dir::String, context::Dict{String,String})
    if !isdir(section_dir)
        return "% No template sections directory found."
    end

    all_tex_templates = sort(filter(name -> endswith(name, ".tex.mustache"), readdir(section_dir)))
    if isempty(all_tex_templates)
        return "% No TeX section templates found."
    end

    wrapper_name = "section_theory.tex.mustache"
    front_matter_templates = Set(["abstract.tex.mustache"])
    # Keep the canonical comparison section and skip the legacy duplicate template.
    excluded_templates = Set([
        "numerical_verification_physical_interpretation.tex.mustache",
        "mixing_length.tex.mustache",
    ])
    content_templates = filter(name -> (name != wrapper_name) && !(name in front_matter_templates) && !(name in excluded_templates), all_tex_templates)

    preferred_order = [
        "governing_system.tex.mustache",
        "governing_equations.tex.mustache",
        "critical_manifold_geometry.tex.mustache",
        "regularization.tex.mustache",
        "visual_phase_space_ascii.tex.mustache",
        "mathematical_formulation_regularization_thermal_shift.tex.mustache",
        "comparative_metrics.tex.mustache",
        "executive_campaign_matrix.tex.mustache",
        "numerical_implementation_solver_strategy.tex.mustache",
        "closures.tex.mustache",
        "gspt_closure_manifold.tex.mustache",
        "parameters_table.tex.mustache",
        "parameters_geometry.tex.mustache",
    ]

    ordered_templates = String[]
    for name in preferred_order
        if name in content_templates
            push!(ordered_templates, name)
        end
    end

    for name in content_templates
        if !(name in ordered_templates)
            push!(ordered_templates, name)
        end
    end

    content_blocks = String[]
    for file in ordered_templates
        template_path = joinpath(section_dir, file)
        template_text = read_text(template_path)
        rendered = render_template(template_text, context)

        # Inject explicit source traceability comments
        commented_block = "% --- Begin Section: $(template_path) ---\n" * rendered * "\n% --- End Section: $(template_path) ---"
        push!(content_blocks, commented_block)
    end

    content_joined = join(content_blocks, "\n\n")
    if wrapper_name in all_tex_templates
        wrapper_path = joinpath(section_dir, wrapper_name)
        wrapper_text = read_text(wrapper_path)
        wrapper_context = copy(context)
        wrapper_context["content"] = content_joined
        rendered_wrapper = render_template(wrapper_text, wrapper_context)
        return "% --- Begin Wrapper: $(wrapper_path) ---\n" * rendered_wrapper * "\n% --- End Wrapper: $(wrapper_path) ---"
    end

    return content_joined
end

function sanitize_macro_fragment(value::String)
    cleaned = replace(value, r"[^A-Za-z]" => "")
    return isempty(cleaned) ? "Unknown" : uppercase(cleaned)
end

function normalize_numeric_text(value::Float64)
    if abs(value) >= 1e4 || (abs(value) > 0 && abs(value) < 1e-3)
        sci = lowercase(string(value))
        if occursin("e", sci)
            parts = split(sci, "e")
            coeff = parts[1]
            exponent = parse(Int, parts[2])
            return "$(coeff) \\times 10^{$(exponent)}"
        end
    end

    rounded = round(value; digits=8)
    text = string(rounded)
    if occursin(".", text)
        text = replace(text, r"0+$" => "")
        text = replace(text, r"\.$" => "")
    end
    return text
end

function texify_number(value)
    value isa Number || return latex_escape(string(value))
    return normalize_numeric_text(Float64(value))
end

function find_dataset_summary_path(dataset::String)
    latest_summary = joinpath("results", dataset, "latest", "summary.json")
    if isfile(latest_summary)
        return latest_summary
    end

    run_root = joinpath("results", dataset)
    if isdir(run_root)
        run_dirs = sort(filter(name -> startswith(name, "run_") && isdir(joinpath(run_root, name)), readdir(run_root)); rev=true)
        for run_dir in run_dirs
            candidate = joinpath(run_root, run_dir, "summary.json")
            if isfile(candidate)
                return candidate
            end
        end
    end

    return ""
end

function read_dataset_parameters(dataset::String)
    summary_path = find_dataset_summary_path(dataset)
    isempty(summary_path) && return nothing

    summary_obj = JSON3.read(read(summary_path, String))
    params_obj = getnested(summary_obj, ["parameters"], nothing)
    params_obj === nothing && return nothing

    params = Dict{String,Float64}()
    for (k, v) in pairs(params_obj)
        if v isa Number
            params[string(k)] = Float64(v)
        end
    end
    return Dict(
        "summary_path" => summary_path,
        "parameters" => params,
    )
end

function parameter_to_macro_name(param_key::String)
    overrides = Dict(
        "z0m" => "SBLParamZZeroM",
        "z0h" => "SBLParamZZeroH",
        "l0" => "SBLParamLZero",
    )
    if haskey(overrides, param_key)
        return overrides[param_key]
    end

    digit_words = Dict(
        '0' => "Zero",
        '1' => "One",
        '2' => "Two",
        '3' => "Three",
        '4' => "Four",
        '5' => "Five",
        '6' => "Six",
        '7' => "Seven",
        '8' => "Eight",
        '9' => "Nine",
    )

    parts = split(param_key, '_')
    normalized = String[]
    for part in parts
        out = IOBuffer()
        for ch in lowercase(part)
            if haskey(digit_words, ch)
                print(out, digit_words[ch])
            else
                print(out, ch)
            end
        end
        push!(normalized, uppercasefirst(String(take!(out))))
    end
    return "SBLParam" * join(normalized, "")
end

function parameter_to_context_key(param_key::String)
    return "param_" * lowercase(param_key) * "_tex"
end

function parameter_to_code_context_key(param_key::String)
    return "param_" * lowercase(param_key) * "_code"
end

function run_cmd_text(cmd::Cmd; fallback::String="unknown")
    try
        return chomp(read(cmd, String))
    catch
        return fallback
    end
end

function git_provenance_context()
    short_sha = run_cmd_text(`git rev-parse --short HEAD`; fallback="unknown")
    full_sha = run_cmd_text(`git rev-parse HEAD`; fallback="unknown")
    worktree_state = begin
        try
            status = read(`git status --porcelain`, String)
            isempty(strip(status)) ? "clean" : "dirty"
        catch
            "unknown"
        end
    end
    build_timestamp_iso = Dates.format(Dates.now(), dateformat"yyyy-mm-ddTHH:MM:SS")

    return Dict(
        "git_commit_short" => short_sha,
        "git_commit_full" => full_sha,
        "git_worktree_state" => worktree_state,
        "build_timestamp_iso" => build_timestamp_iso,
    )
end

function codeify_number(value::Float64)
    return lowercase(string(value))
end

function set_notation_context_aliases!(context::Dict{String,String}, params::Dict{String,Float64})
    # Thermal response sensitivity defaults to legacy beta when beta_t is absent.
    beta_t_val = if haskey(params, "beta_t")
        params["beta_t"]
    elseif haskey(params, "beta")
        params["beta"]
    else
        0.0
    end

    # Fast linear TKE term defaults to legacy beta when sigma_e is absent.
    sigma_e_val = if haskey(params, "sigma_e")
        params["sigma_e"]
    elseif haskey(params, "beta")
        params["beta"]
    else
        0.0
    end

    context["param_beta_t_tex"] = texify_number(beta_t_val)
    context["param_beta_t_code"] = codeify_number(beta_t_val)
    context["param_sigma_e_tex"] = texify_number(sigma_e_val)
    context["param_sigma_e_code"] = codeify_number(sigma_e_val)
end

function write_parameter_macro_bundle(active_dataset::String)
    mkpath(joinpath("reports", "generated", "parameters"))

    datasets_data = Dict{String,Dict}()
    for ds in SUPPORTED_DATASETS
        data = read_dataset_parameters(ds)
        if data === nothing
            if ds == active_dataset
                error("Missing required active dataset summary for $(active_dataset). Expected results/$(active_dataset)/latest/summary.json or a run_*/summary.json.")
            end
            @warn "Skipping parameter macro export for $(ds): no summary.json found."
            continue
        end
        datasets_data[ds] = data
    end

    haskey(datasets_data, active_dataset) || error("Cannot render manuscript parameters: active dataset $(active_dataset) has no summary payload.")

    active_params = datasets_data[active_dataset]["parameters"]::Dict{String,Float64}
    provenance = git_provenance_context()
    context = Dict{String,String}(
        "active_dataset" => active_dataset,
        "active_parameter_macros_path" => "parameters/parameters_all.tex",
        "git_commit_short" => provenance["git_commit_short"],
        "git_commit_full" => provenance["git_commit_full"],
        "git_worktree_state" => provenance["git_worktree_state"],
        "build_timestamp_iso" => provenance["build_timestamp_iso"],
    )

    for (k, v) in active_params
        context[parameter_to_context_key(k)] = texify_number(v)
        context[parameter_to_code_context_key(k)] = codeify_number(v)
    end

    set_notation_context_aliases!(context, active_params)

    if haskey(datasets_data, "CASES99")
        p = datasets_data["CASES99"]["parameters"]::Dict{String,Float64}
        context["cases_z0m_tex"] = haskey(p, "z0m") ? texify_number(p["z0m"]) : "n/a"
        context["cases_z0h_tex"] = haskey(p, "z0h") ? texify_number(p["z0h"]) : "n/a"
    else
        context["cases_z0m_tex"] = "n/a"
        context["cases_z0h_tex"] = "n/a"
    end
    if haskey(datasets_data, "FLOSS")
        p = datasets_data["FLOSS"]["parameters"]::Dict{String,Float64}
        context["floss_z0m_tex"] = haskey(p, "z0m") ? texify_number(p["z0m"]) : "n/a"
        context["floss_z0h_tex"] = haskey(p, "z0h") ? texify_number(p["z0h"]) : "n/a"
    else
        context["floss_z0m_tex"] = "n/a"
        context["floss_z0h_tex"] = "n/a"
    end

    macro_lines = String[]
    push!(macro_lines, "% Auto-generated by scripts/assemble_manuscript.jl. Do not edit by hand.")
    push!(macro_lines, "% Active dataset: $(active_dataset)")
    push!(macro_lines, "\\providecommand{\\SBLActiveDataset}{$(latex_escape(active_dataset))}")
    push!(macro_lines, "\\providecommand{\\ActiveDataset}{\\SBLActiveDataset}")
    push!(macro_lines, "\\providecommand{\\SBLGitCommitShort}{$(latex_escape(provenance["git_commit_short"]))}")
    push!(macro_lines, "\\providecommand{\\SBLGitCommitFull}{$(latex_escape(provenance["git_commit_full"]))}")
    push!(macro_lines, "\\providecommand{\\SBLGitWorktreeState}{$(latex_escape(provenance["git_worktree_state"]))}")
    push!(macro_lines, "\\providecommand{\\SBLBuildTimestampIso}{$(latex_escape(provenance["build_timestamp_iso"]))}")
    push!(macro_lines, "")

    for ds in sort(collect(keys(datasets_data)))
        ds_params = datasets_data[ds]["parameters"]::Dict{String,Float64}
        ds_tag = sanitize_macro_fragment(ds)
        push!(macro_lines, "% Dataset: $(ds)")
        for key in sort(collect(keys(ds_params)))
            value_tex = texify_number(ds_params[key])
            macro_name = "\\SBL$(ds_tag)" * parameter_to_macro_name(key)
            push!(macro_lines, "\\providecommand{$(macro_name)}{$(value_tex)}")
        end
        push!(macro_lines, "")
    end

    push!(macro_lines, "% Active dataset aliases")
    for key in sort(collect(keys(active_params)))
        value_tex = texify_number(active_params[key])
        macro_name = "\\" * parameter_to_macro_name(key)
        push!(macro_lines, "\\providecommand{$(macro_name)}{$(value_tex)}")
    end

    macro_path = joinpath("reports", "generated", "parameters", "parameters_all.tex")
    write(macro_path, join(macro_lines, "\n") * "\n")
    return context, macro_path, active_params
end

function load_datasets_data(active_dataset::String)
    datasets_data = Dict{String,Dict}()
    for ds in SUPPORTED_DATASETS
        data = read_dataset_parameters(ds)
        if data === nothing
            if ds == active_dataset
                error("Missing required active dataset summary for $(active_dataset). Expected results/$(active_dataset)/latest/summary.json or a run_*/summary.json.")
            end
            @warn "Skipping dataset $(ds) during prose lint: no summary.json found."
            continue
        end
        datasets_data[ds] = data
    end
    haskey(datasets_data, active_dataset) || error("Cannot lint prose literals: active dataset $(active_dataset) has no summary payload.")
    return datasets_data
end

function trim_decimal_string(s::String)
    out = replace(s, r"0+$" => "")
    out = replace(out, r"\.$" => "")
    return isempty(out) ? "0" : out
end

function numeric_spellings(v::Float64)
    tokens = Set{String}()
    push!(tokens, lowercase(string(v)))
    push!(tokens, trim_decimal_string(@sprintf("%.12f", v)))
    push!(tokens, trim_decimal_string(@sprintf("%.8f", v)))
    push!(tokens, lowercase(@sprintf("%.12g", v)))
    return filter(t -> !isempty(t), collect(tokens))
end

function build_whitelist_numeric_tokens(datasets_data::Dict{String,Dict})
    token_to_keys = Dict{String,Set{String}}()
    for (_ds, data) in datasets_data
        params = data["parameters"]::Dict{String,Float64}
        for key in PROVENANCE_PARAM_KEYS
            haskey(params, key) || continue
            for token in numeric_spellings(params[key])
                if !haskey(token_to_keys, token)
                    token_to_keys[token] = Set{String}()
                end
                push!(token_to_keys[token], key)
            end
        end
    end
    return token_to_keys
end

function load_prose_lint_allowlist(path::String)
    allowlist = Set{Tuple{String,Int,String}}()
    if !isfile(path)
        return allowlist
    end

    for (idx, raw) in enumerate(eachline(path))
        line = strip(raw)
        if isempty(line) || startswith(line, "#")
            continue
        end

        parts = split(line, ':')
        if length(parts) != 3
            @warn "Ignoring invalid prose lint allowlist entry at $(path):$(idx): $(line)"
            continue
        end

        rel_path = strip(parts[1])
        line_no = try
            parse(Int, strip(parts[2]))
        catch
            @warn "Ignoring invalid line number in prose lint allowlist entry at $(path):$(idx): $(line)"
            continue
        end
        token = lowercase(strip(parts[3]))
        push!(allowlist, (rel_path, line_no, token))
    end
    return allowlist
end

function lint_prose_literals!(active_dataset::String; strict::Bool=false, allowlist_path::String=DEFAULT_PROSE_LINT_ALLOWLIST_PATH)
    datasets_data = load_datasets_data(active_dataset)
    token_to_keys = build_whitelist_numeric_tokens(datasets_data)
    number_re = r"(?<![A-Za-z0-9_\\])[-+]?\d+(?:\.\d+)?(?:[eE][-+]?\d+)?(?!\^)"

    findings = Tuple{String,Int,String,String,Vector{String}}[]
    allowlist = load_prose_lint_allowlist(allowlist_path)
    root = "templates"
    if !isdir(root)
        @warn "Skipping prose literal lint: templates directory not found."
        return 0
    end

    for (dir, _, files) in walkdir(root)
        for file in files
            endswith(file, ".tex.mustache") || continue
            path = joinpath(dir, file)
            lines = split(read(path, String), '\n')
            in_verbatim = false
            for (idx, line) in enumerate(lines)
                if occursin("\\begin{verbatim}", line)
                    in_verbatim = true
                end
                if in_verbatim
                    if occursin("\\end{verbatim}", line)
                        in_verbatim = false
                    end
                    continue
                end
                if occursin("\\SBLParam", line) || occursin("{{param_", line)
                    continue
                end
                seen_tokens_on_line = Set{String}()
                for m in eachmatch(number_re, line)
                    token = lowercase(m.match)
                    token in seen_tokens_on_line && continue
                    push!(seen_tokens_on_line, token)

                    # Avoid false positives from TeX scientific notation fragments like 10^{-4}.
                    after = m.offset + length(m.match)
                    if token == "10" && after <= lastindex(line) && line[after] == '^'
                        continue
                    end

                    haskey(token_to_keys, token) || continue
                    keys = sort(collect(token_to_keys[token]))
                    push!(findings, (path, idx, token, strip(line), keys))
                end
            end
        end
    end

    actionable_findings = Tuple{String,Int,String,String,Vector{String}}[]
    ignored_count = 0
    for finding in findings
        path, line_no, token, source_line, keys = finding
        if (path, line_no, token) in allowlist
            ignored_count += 1
            continue
        end
        push!(actionable_findings, finding)
    end

    if isempty(actionable_findings)
        println("[lint-prose] no hardcoded provenance literals detected in templates/*.tex.mustache")
        if ignored_count > 0
            println("[lint-prose] ignored $(ignored_count) allowlisted finding(s) from $(allowlist_path)")
        end
        return 0
    end

    println("[lint-prose] detected $(length(actionable_findings)) potential hardcoded provenance literal(s):")
    if ignored_count > 0
        println("[lint-prose] ignored $(ignored_count) allowlisted finding(s) from $(allowlist_path)")
    end
    for (path, line_no, token, source_line, keys) in actionable_findings
        println("  - $(path):$(line_no) token=$(token) keys=$(join(keys, ","))")
        println("    $(source_line)")
    end

    if strict
        error("Prose literal lint failed in strict mode with $(length(actionable_findings)) finding(s).")
    end
    return length(actionable_findings)
end

function verify_parameter_macro_bundle!(macro_path::String, active_dataset::String, active_params::Dict{String,Float64})
    content = read(macro_path, String)
    missing = String[]

    drift_keys = [
        "epsilon",
        "delta",
        "xi",
        "beta",
        "beta_t",
        "sigma_e",
        "h",
        "l0",
        "z0m",
        "z0h",
        "T_deep",
        "U_g",
        "R_down",
        "f_coriolis",
        "K",
        "kappa",
        "nonlocal_h_min",
        "nonlocal_h_max",
        "nonlocal_h_weight",
        "shear_production_efficiency",
        "d_soil",
        "rho_cp",
        "lambda_soil",
        "sigma_sb",
    ]

    ds_tag = sanitize_macro_fragment(active_dataset)
    for key in drift_keys
        haskey(active_params, key) || continue

        alias_expected = "\\providecommand{\\" * parameter_to_macro_name(key) * "}{$(texify_number(active_params[key]))}"
        dataset_expected = "\\providecommand{\\SBL$(ds_tag)" * parameter_to_macro_name(key) * "}{$(texify_number(active_params[key]))}"

        if !occursin(alias_expected, content)
            push!(missing, alias_expected)
        end
        if !occursin(dataset_expected, content)
            push!(missing, dataset_expected)
        end
    end

    if !isempty(missing)
        error("Parameter drift check failed. Missing or mismatched macro definitions: $(join(missing, " | "))")
    end
end

function build_tex_figure_includes(fig_dir::String;
                                   tex_output_dir::String=joinpath("reports", "generated"),
                                   config_path::String=joinpath("config", "manuscript_figures.json"))
    if !isdir(fig_dir)
        return "% No generated figures directory found."
    end

    figure_cfg = load_manuscript_figure_config(config_path)
    fig_metadata_cfg = get(figure_cfg, "figures", Dict{String,Any}())
    preferred_stems_cfg = Vector{String}(get(figure_cfg, "preferred_stems", String[]))
    acronyms_cfg = get(figure_cfg, "acronyms", Dict{String,Any}())

    FIGURE_METADATA = Dict(
        "figure_bifurcation_fold_envelope" => (
            title="Comparative benchmark: Bifurcation envelope under a classical interior fold scenario (shown for structural comparison only; not generated by the present model). This illustrates the scenario where the active turbulent branch loses normal hyperbolicity at an interior saddle-node locus.",
            label="fig:fold_envelope",
        ),
        "figure_bifurcation_fold_map" => (
            title="Comparative benchmark: Topological phase-space map of an interior fold regime (shown for comparison only). Vector fields highlight the catastrophic jump dynamics occurring at an interior fold point, contrasting with the boundary-crossing mechanics of the present system.",
            label="fig:fold_map",
        ),
        "figure_bifurcation_transcritical_envelope" => (
            title="Transcritical bifurcation envelope corresponding to the transversal boundary crossing regime (\$e=0\$). The diagram illustrates the smooth transition tracking the physical admissibility threshold \$\\Delta = \\delta / l_0\$.",
            label="fig:transcritical_envelope",
        ),
        "figure_bifurcation_transcritical_map" => (
            title="Trajectory flow field mapping the non-folding boundary crossing. The phase portraits confirm that the system transitions smoothly onto the regularized background laminar floor without undergoing an interior saddle-node collapse.",
            label="fig:transcritical_map",
        ),
        "figure_bifurcation_transcritical_distance_map" => (
            title="Distance-to-threshold map for the transcritical boundary crossing. Smaller values indicate states close to the critical exchange surface where the laminar branch changes stability.",
            label="fig:transcritical_distance_map",
        ),
        "figure_bifurcation_parameter_sensitivity_envelope" => (
            title="Sensitivity envelope for transcritical threshold statistics under coupled parameter scaling. The median and extrema summarize threshold migration as closure controls are perturbed.",
            label="fig:parameter_sensitivity_envelope",
        ),
        "4d_sbl_diagnostics" => (
            title="Complete 4D time-series trajectories and phase-space projections for the nocturnal stable boundary layer simulated under CASES99 conditions. The panels illustrate the rapid initial turbulent decay followed by the slow ageostrophic development of the nocturnal low-level jet.",
            label="fig:sbl_diagnostics",
        ),
        "diagnostic_regularization_comparison" => (
            title="Comparative analysis of the state-derived vertical eddy diffusivities (\$K_m, K_h\$) versus the \$C^\\infty\$ regularized hyperbolic embedded tracks (\$K_{m,\\star}, K_{h,\\star}\$) defined in Eq.~\\eqref{eq:embedded_diffusivities}. The comparison illustrates how the smooth embedding smooths out the sharp gradient kinks at the collapse threshold while ensuring a bounded closure Jacobian \$J_K\$.",
            label="fig:regularization_comparison",
        ),
        "figure_gspt_manifold_tikz" => (
            title="Geometric Singular Perturbation Theory (GSPT) phase-space schematic illustrating nocturnal transition geometry. The active turbulent branch (\$\\mathcal{M}_0^+\$) forms an upper potential cup in state space. Progressive radiative cooling deforms the cup until the attracting equilibrium disappears at the fold curve \$\\mathcal{C}_{\\text{fold}}\$, driving a rapid vertical transition along fast fibers to the weakly turbulent manifold (\$\\mathcal{M}_0^0\$). On this lower branch, ageostrophic inertial adjustment generates the nocturnal low-level jet until accumulated vertical shear triggers turbulent re-ignition.",
            label="fig:gspt_manifold_tikz",
        ),
        "fig_gspt_manifold_tikz" => (
            title="Geometric Singular Perturbation Theory (GSPT) phase-space schematic illustrating nocturnal transition geometry. The active turbulent branch (\$\\mathcal{M}_0^+\$) forms an upper potential cup in state space. Progressive radiative cooling deforms the cup until the attracting equilibrium disappears at the fold curve \$\\mathcal{C}_{\\text{fold}}\$, driving a rapid vertical transition along fast fibers to the weakly turbulent manifold (\$\\mathcal{M}_0^0\$). On this lower branch, ageostrophic inertial adjustment generates the nocturnal low-level jet until accumulated vertical shear triggers turbulent re-ignition.",
            label="fig:gspt_manifold_tikz",
        ),
        "regime_map_z0m_ug" => (
            title="Analytical regime map in \$(z_{0m}, U_g)\$ parameter space derived from surface-layer similarity scaling. The three dynamic regimes—continuous weak turbulence (Regime I), intermittent relaxation oscillations (Regime II), and runaway radiative decoupling (Regime III)—are partitioned by the critical geostrophic shear boundaries \$S_c\$. Observational field campaign markers locate typical parameter pairs for CASES99, FLOSS, and SHEBA.",
            label="fig:regime_map_z0m_ug",
        ),
        "figure_regime_map_z0m_ug" => (
            title="Analytical regime map in \$(z_{0m}, U_g)\$ parameter space derived from surface-layer similarity scaling. The three dynamic regimes—continuous weak turbulence (Regime I), intermittent relaxation oscillations (Regime II), and runaway radiative decoupling (Regime III)—are partitioned by the critical geostrophic shear boundaries \$S_c\$. Observational field campaign markers locate typical parameter pairs for CASES99, FLOSS, and SHEBA.",
            label="fig:regime_map_z0m_ug",
        ),
    )

    function figure_caption_and_label(stem::String)
        if haskey(fig_metadata_cfg, stem)
            meta = fig_metadata_cfg[stem]
            title = get(meta, "title", prettify_figure_title(stem))
            label = get(meta, "label", "")
            return String(title), String(label)
        end
        if haskey(FIGURE_METADATA, stem)
            meta = FIGURE_METADATA[stem]
            return meta.title, meta.label
        end
        return prettify_figure_title(stem), ""
    end

    function make_figure_block(path::String, caption::String, label::String)
        rel_path = relpath(path, tex_output_dir)
        label_line = isempty(label) ? "" : "\n\\label{$(label)}"
        return "\\begin{figure}[ht!]\n\\centering\n\\includegraphics[width=0.95\\linewidth]{$(rel_path)}\n\\caption{$(caption)}$(label_line)\n\\end{figure}"
    end

    function prettify_figure_title(stem::String)
        parts = split(replace(stem, "-" => "_"), "_")
        normalized = String[]
        for part in parts
            lw = lowercase(part)
            if haskey(acronyms_cfg, lw)
                push!(normalized, String(acronyms_cfg[lw]))
            elseif lw == "4d"
                push!(normalized, "4D")
            elseif lw == "sbl"
                push!(normalized, "SBL")
            elseif lw == "tke"
                push!(normalized, "TKE")
            elseif lw == "gspt"
                push!(normalized, "GSPT")
            elseif lw == "nwp"
                push!(normalized, "NWP")
            elseif lw == "ug"
                push!(normalized, "\$U_g\$")
            elseif lw == "z0m"
                push!(normalized, "\$z_{0m}\$")
            else
                push!(normalized, uppercasefirst(lw))
            end
        end
        return join(normalized, " ")
    end

    tex_files = sort(filter(name -> startswith(name, "figure_bifurcation_") && endswith(name, ".tex"), readdir(fig_dir)))
    handled_stems = Set{String}()
    candidate_paths = Dict{String,String}()

    blocks = String[]
    for file in tex_files
        stem = replace(file, ".tex" => "")
        push!(handled_stems, stem)
        pdf_path = joinpath(fig_dir, "$(stem).pdf")
        if isfile(pdf_path)
            candidate_paths[stem] = pdf_path
        end
    end

    image_files = sort(filter(name -> (
            (endswith(name, ".png") || endswith(name, ".jpg") || endswith(name, ".jpeg") || endswith(name, ".pdf"))
        ), readdir(fig_dir)))

    for file in image_files
        stem = replace(file, r"\.[^.]+$" => "")
        if stem in handled_stems
            continue
        end
        img_path = joinpath(fig_dir, file)
        if !haskey(candidate_paths, stem) || endswith(lowercase(img_path), ".pdf")
            candidate_paths[stem] = img_path
        end
    end

    # Collapse known alias stems to a canonical figure key to avoid duplicate
    # figure blocks and label collisions when both legacy and current names exist.
    stem_aliases = Dict(
        "regime_map_z0m_ug" => ["figure_regime_map_z0m_ug"],
        "figure_gspt_manifold_tikz" => ["fig_gspt_manifold_tikz"],
    )
    for (canonical, aliases) in stem_aliases
        if haskey(candidate_paths, canonical)
            for alias in aliases
                pop!(candidate_paths, alias, nothing)
            end
        else
            for alias in aliases
                if haskey(candidate_paths, alias)
                    candidate_paths[canonical] = candidate_paths[alias]
                    pop!(candidate_paths, alias, nothing)
                    break
                end
            end
        end
    end

    # These figures are embedded directly in section templates and should not
    # be duplicated in the auto-generated diagnostics block.
    manual_section_stems = Set([
        "regime_map_z0m_ug",
        "figure_regime_map_z0m_ug",
    ])
    for stem in manual_section_stems
        pop!(candidate_paths, stem, nothing)
    end

    preferred_stems = isempty(preferred_stems_cfg) ? [
        "fig_gspt_manifold_tikz",
        "figure_gspt_manifold_tikz",
        "regime_map_z0m_ug",
        "figure_regime_map_z0m_ug",
        "figure_bifurcation_transcritical_map",
        "figure_bifurcation_transcritical_distance_map",
        "figure_bifurcation_transcritical_envelope",
        "figure_bifurcation_parameter_sensitivity_envelope",
        "figure_bifurcation_fold_map",
        "figure_bifurcation_fold_envelope",
        "4d_sbl_diagnostics",
        "diagnostic_regularization_comparison",
    ] : preferred_stems_cfg

    ordered_stems = String[]
    for stem in preferred_stems
        if haskey(candidate_paths, stem)
            push!(ordered_stems, stem)
        end
    end
    for stem in sort(collect(keys(candidate_paths)))
        if !(stem in ordered_stems)
            push!(ordered_stems, stem)
        end
    end

    for stem in ordered_stems
        title, label = figure_caption_and_label(stem)
        push!(blocks, make_figure_block(candidate_paths[stem], title, label))
    end

    if isempty(blocks)
        return "% No generated figure assets found."
    end

    return join(blocks, "\n\n")
end

function build_md_figure_includes(fig_dir::String)
    if !isdir(fig_dir)
        return "No generated figures directory found."
    end

    md_files = sort(filter(name -> startswith(name, "figure_bifurcation_") && endswith(name, ".md"), readdir(fig_dir)))

    lines = String[]
    for file in md_files
        push!(lines, "- reports/generated/figures/$(file)")
    end

    image_files = sort(filter(name -> (
            endswith(name, ".png") || endswith(name, ".jpg") || endswith(name, ".jpeg") || endswith(name, ".pdf")
        ), readdir(fig_dir)))

    for file in image_files
        push!(lines, "- reports/generated/figures/$(file)")
    end

    if isempty(lines)
        return "No generated figure assets found."
    end

    return join(lines, "\n")
end

function format_metric(value)
    return isnan(value) ? "\\mathrm{n/a}" : string(round(value; digits=4))
end

function latex_escape(s::AbstractString)
    out = s
    out = replace(out, "\\" => "\\textbackslash{}")
    out = replace(out, "{" => "\\{")
    out = replace(out, "}" => "\\}")
    out = replace(out, "_" => "\\_")
    out = replace(out, "%" => "\\%")
    out = replace(out, "#" => "\\#")
    out = replace(out, "&" => "\\&")
    out = replace(out, string('$') => "\\\$")
    return out
end

function getnested(obj, keys::Vector{String}, default="n/a")
    cur = obj
    for k in keys
        if cur isa AbstractDict
            if haskey(cur, k)
                cur = cur[k]
            elseif haskey(cur, Symbol(k))
                cur = cur[Symbol(k)]
            else
                return default
            end
        else
            try
                cur = getproperty(cur, Symbol(k))
            catch
                return default
            end
        end
    end
    return cur
end

function format_int_commas(x)
    x isa Integer || return string(x)
    s = reverse(string(abs(x)))
    chunks = [reverse(s[i:min(i+2, end)]) for i in 1:3:length(s)]
    out = join(reverse(chunks), ",")
    return x < 0 ? "-$(out)" : out
end

function format_float_digits(x, digits::Int; fallback="n/a")
    x isa Number || return fallback
    return string(round(Float64(x); digits=digits))
end

function format_percent(x; digits::Int=1, fallback="n/a")
    x isa Number || return fallback
    pct = round(100 * Float64(x); digits=digits)
    if digits == 0
        return string(Int(round(pct)))
    end
    return string(pct)
end

function compact_solver_name(s::AbstractString)
    m = match(r"Rodas[0-9A-Za-z]+", s)
    m === nothing && return s
    return m.match
end

function find_scm_summary_path()
    candidates = [
        joinpath("results", "scm_verify", "summary.json"),
        joinpath("results", "idealized_sbl", "summary.json"),
        joinpath("results", "idealized_sbl_smoke", "summary.json"),
    ]
    for path in candidates
        if isfile(path)
            return path
        end
    end

    discovered = String[]
    if isdir("results")
        for entry in readdir("results")
            summary_path = joinpath("results", entry, "summary.json")
            plots_dir = joinpath("results", entry, "plots")
            if isfile(summary_path) && isdir(plots_dir)
                push!(discovered, summary_path)
            end
        end
    end
    if !isempty(discovered)
        sort!(discovered; by=path -> stat(path).mtime, rev=true)
        return first(discovered)
    end

    return ""
end

function read_scm_summary_context(; config_path::String=joinpath("config", "manuscript_figures.json"))
    path = find_scm_summary_path()
    if isempty(path)
        return Dict{String,String}(
            "scm_case_name" => "n/a",
            "scm_solver_name" => "n/a",
            "scm_rhs_evaluations" => "n/a",
            "scm_surface_energy_closure_error" => "n/a",
            "scm_km_min" => "n/a",
            "scm_km_max" => "n/a",
            "scm_fold_fraction_percent" => "n/a",
            "scm_phase_figure_block" => "% SCM phase portrait figure unavailable",
            "scm_closure_manifold_figure_block" => "% SCM closure manifold figure unavailable",
            "scm_all_figures_block" => "% SCM figures unavailable",
        )
    end

    raw = read(path, String)
    summary = JSON3.read(raw)

    solver_algorithm = string(getnested(summary, ["solver_summary", "algorithm"], "n/a"))
    rhs_evals = getnested(summary, ["solver_summary", "rhs_evaluations"], "n/a")
    max_surface_error = getnested(summary, ["verification", "max_surface_energy_closure_error"], "n/a")
    km_min = getnested(summary, ["verification", "min_diffusivity"], "n/a")
    km_max = getnested(summary, ["verification", "max_diffusivity"], "n/a")
    fold_fraction = getnested(summary, ["verification", "fold_near_fraction"], "n/a")
    case_name = string(getnested(summary, ["case"], "n/a"))
    outdir = string(getnested(summary, ["outdir"], dirname(path)))

    figure_cfg = load_manuscript_figure_config(config_path)
    scm_fig_meta_cfg = get(figure_cfg, "scm_figures", Dict{String,Any}())

    SCM_FIG_META = Dict(
        "fig01" => (
            caption="Time-series evolution of surface skin temperature \\(T_s\\), surface sensible heat flux \\(H\\), and friction velocity \\(u_*\\) over the course of the simulation.",
            label="fig:scm_time_series",
        ),
        "fig02" => (
            caption="Time-height contour map representing horizontal wind speed \\(U\\), demonstrating the gradual aloft development and consolidation of the nocturnal low-level jet (LLJ).",
            label="fig:scm_wind_contour",
        ),
        "fig03" => (
            caption="Time-height contour of potential temperature \\(\\theta\\), demonstrating surface-driven nocturnal radiative cooling and progressive boundary-layer inversion growth.",
            label="fig:scm_theta_contour",
        ),
        "fig04" => (
            caption="Representative vertical profiles of horizontal wind speed \\(U\\), potential temperature \\(\\theta\\), and momentum eddy diffusivity \\(K_m\\) at diagnostic times.",
            label="fig:scm_profiles",
        ),
        "fig05" => (
            caption="Surface energy budget (SEB) components illustrating the dynamic balance of net radiation \\(R_n\\), sensible heat flux \\(H\\), soil heat flux \\(G\\), and surface-storage thermal layers.",
            label="fig:scm_surface_energy",
        ),
        "fig06" => (
            caption="Regularized slow-manifold phase portrait mapping the net TKE production-buoyancy balance \\(\\Delta\\) against the regularized coordinate \\(e_\\xi^*\\) across characteristic height bands (surface, mid-BL jet core, and upper boundary layer). The vertical reference line shows the analytical critical transition condition \\(\\Delta = \\delta / \\ell_0\\).",
            label="fig:scm_phase_delta_exi",
        ),
        "fig07" => (
            caption="The GSPT closure manifold. (a) Momentum diffusivity \\(K_m\\) vs. gradient Richardson number \\((\\mathrm{Ri}_g)\\) color-coded by shear \\(S\\). (b) \\(K_m\\) vs. \\((\\mathrm{Ri}_g)\\) color-coded by height \\(z\\). (c) Collapse of \\(K_m\\) onto the fold invariant \\(\\Delta\\). (d) Dynamic Prandtl number \\(\\mathrm{Pr}_t\\) vs. \\((\\mathrm{Ri}_g)\\).",
            label="fig:closure_manifold",
        ),
        "fig08" => (
            caption="Temporal evolution of the surface fold-proximity metric, showing the proximity of the surface state relative to the regularized manifold transition boundary.",
            label="fig:scm_fold_proximity",
        ),
    )

    phase_fig_path = joinpath(outdir, "plots", "fig06_phase_delta_exi.png")
    phase_fig_block = "% SCM phase portrait figure unavailable"
    closure_manifold_fig_block = "% SCM closure manifold figure unavailable"

    scm_plots_dir = joinpath(outdir, "plots")
    all_scm_blocks = String[]
    if isdir(scm_plots_dir)
        scm_image_files = sort(filter(name -> (
                endswith(name, ".png") || endswith(name, ".jpg") || endswith(name, ".jpeg") || endswith(name, ".pdf")
            ), readdir(scm_plots_dir)))

        # Avoid duplicate Figure 7 labels when both legacy and manifold variants exist.
        has_manifold_fig07 = any(name -> replace(name, r"\.[^.]+$" => "") == "fig07_closure_manifold", scm_image_files)
        if has_manifold_fig07
            scm_image_files = filter(name -> replace(name, r"\.[^.]+$" => "") != "fig07_diffusivity_vs_ri", scm_image_files)
        end

        for file in scm_image_files
            stem = replace(file, r"\.[^.]+$" => "")
            prefix_match = match(r"fig\d+", stem)
            prefix = prefix_match === nothing ? stem : prefix_match.match

            caption, label = if haskey(scm_fig_meta_cfg, prefix)
                meta = scm_fig_meta_cfg[prefix]
                default_label = "fig:scm_" * lowercase(replace(stem, r"[^A-Za-z0-9]+" => "_"))
                caption_val = haskey(meta, "caption") ? meta["caption"] : stem
                label_val = haskey(meta, "label") ? meta["label"] : default_label
                String(caption_val), String(label_val)
            elseif haskey(SCM_FIG_META, prefix)
                SCM_FIG_META[prefix].caption, SCM_FIG_META[prefix].label
            else
                fallback_label = "fig:scm_" * lowercase(replace(stem, r"[^A-Za-z0-9]+" => "_"))
                prettify_figure_title(stem), fallback_label
            end

            img_path = joinpath(scm_plots_dir, file)
            rel_img_path = relpath(img_path, joinpath("reports", "generated"))
            fig_latex = "\\begin{figure}[ht!]\n\\centering\n\\includegraphics[width=0.95\\linewidth]{\\detokenize{$(rel_img_path)}}\n\\caption{$(caption)}\n\\label{$(label)}\n\\end{figure}"
            push!(all_scm_blocks, fig_latex)

            if prefix == "fig06"
                phase_fig_block = fig_latex
            elseif prefix == "fig07"
                closure_manifold_fig_block = fig_latex
            end
        end
    end

    scm_all_figures_block = isempty(all_scm_blocks) ? "% SCM figures unavailable" : join(all_scm_blocks, "\n\n")

    return Dict{String,String}(
        "scm_case_name" => latex_escape(case_name),
        "scm_solver_name" => latex_escape(compact_solver_name(solver_algorithm)),
        "scm_rhs_evaluations" => format_int_commas(rhs_evals),
        "scm_surface_energy_closure_error" => format_float_digits(max_surface_error, 0),
        "scm_km_min" => format_float_digits(km_min, 3),
        "scm_km_max" => format_float_digits(km_max, 2),
        "scm_fold_fraction_percent" => format_percent(fold_fraction; digits=0),
        "scm_phase_figure_block" => phase_fig_block,
        "scm_closure_manifold_figure_block" => closure_manifold_fig_block,
        "scm_all_figures_block" => scm_all_figures_block,
    )
end

function quadratic_fit_rmse(solution_csv::String)
    if !isfile(solution_csv)
        return NaN
    end

    df = CSV.read(solution_csv, DataFrame)
    if !all(name -> name in names(df), ["U", "V", "Ts"])
        return NaN
    end

    U = Vector{Float64}(df.U)
    V = Vector{Float64}(df.V)
    Ts = Vector{Float64}(df.Ts)
    X = hcat(ones(length(U)), U, V, U .^ 2, U .* V, V .^ 2)
    coef = X \ Ts
    residual = Ts - X * coef
    return sqrt(mean(residual .^ 2))
end

function latest_solution_csv(dataset::String)
    latest_path = joinpath("results", dataset, "latest", "solution.csv")
    if isfile(latest_path)
        return latest_path
    end

    run_root = joinpath("results", dataset)
    if isdir(run_root)
        run_dirs = sort(
            filter(name -> startswith(name, "run_") && isdir(joinpath(run_root, name)), readdir(run_root));
            rev=true,
        )
        for run_dir in run_dirs
            candidate = joinpath(run_root, run_dir, "solution.csv")
            if isfile(candidate)
                return candidate
            end
        end
    end

    if dataset == "CASES99"
        legacy_root = joinpath("results", "4d_sbl")
        if isdir(legacy_root)
            legacy_dirs = sort(
                filter(name -> startswith(name, "run_") && isdir(joinpath(legacy_root, name)), readdir(legacy_root));
                rev=true,
            )
            for run_dir in legacy_dirs
                candidate = joinpath(legacy_root, run_dir, "solution.csv")
                if isfile(candidate)
                    return candidate
                end
            end
        end
    end

    return latest_path
end

function assemble_manuscript(args::Vector{String}=ARGS)
    dataset, generated_date_human, write_parameter_macros_only, check_parameter_drift, lint_prose_literals, lint_prose_strict, lint_prose_allowlist_path = parse_args(args)

    if lint_prose_literals
        count = lint_prose_literals!(dataset; strict=lint_prose_strict, allowlist_path=lint_prose_allowlist_path)
        println("[lint-prose] completed with $(count) finding(s).")
        return nothing
    end

    parameter_context, parameter_macro_path, active_params = write_parameter_macro_bundle(dataset)
    if check_parameter_drift
        verify_parameter_macro_bundle!(parameter_macro_path, dataset, active_params)
    end
    if write_parameter_macros_only
        println("Generated parameter macro bundle:")
        println(parameter_macro_path)
        return nothing
    end

    mkpath("reports/generated")

    tex_out = "reports/generated/paper.tex"
    md_out = "reports/generated/paper.md"

    tex_template_path = "templates/paper.tex.mustache"
    md_template_path = "templates/paper.md.mustache"

    tex_template = read_text(tex_template_path; fallback="\\documentclass{article}\\begin{document}Template missing.\\end{document}")
    md_template = read_text(md_template_path; fallback="# Template missing")

    symbols_context, symbols_tex_path, _ = SymbolSSOT.generate_symbols_assets()
    symbols_list_tex = isfile(symbols_tex_path) ? "\\input{" * relpath(symbols_tex_path, dirname(tex_out)) * "}" : "% List of symbols unavailable"

    theory_md = read_text("reports/generated/theory/01_state_space.md"; fallback="Theory section not generated yet.")
    archive_md = read_text("reports/generated/theory/02_archive_synthesis.md"; fallback="Archive synthesis not generated yet.")
    diag_md = read_text("reports/generated/diagnostics/03_bifurcation_sweep.md"; fallback="Diagnostics section not generated yet.")

    fig_dir = first_existing_dir(["reports/generated/figures", "figures"])
    figure_tex_includes = build_tex_figure_includes(fig_dir; tex_output_dir=dirname(tex_out))
    figure_md_includes = build_md_figure_includes(fig_dir)

    timestamp = string(Dates.now())

    section_context = Dict(
        "dataset" => dataset,
        "generated_timestamp" => timestamp,
        "generated_date_human" => generated_date_human,
        "cases99_rmse" => format_metric(quadratic_fit_rmse(latest_solution_csv("CASES99"))),
        "floss_rmse" => format_metric(quadratic_fit_rmse(latest_solution_csv("FLOSS"))),
        "sheba_rmse" => format_metric(quadratic_fit_rmse(latest_solution_csv("SHEBA"))),
    )
    merge!(section_context, read_scm_summary_context())
    merge!(section_context, parameter_context)
    merge!(section_context, symbols_context)
    template_sections_tex = build_tex_template_sections("templates/sections", section_context)
    appendix_tex = build_optional_tex_template(
        "templates/sections/mixing_length.tex.mustache",
        section_context;
        fallback="",
    )
    abstract_tex = build_optional_tex_template(
        "templates/sections/abstract.tex.mustache",
        section_context;
        fallback="",
    )

    tex_context = Dict(
        "dataset" => dataset,
        "generated_timestamp" => timestamp,
        "generated_date_human" => generated_date_human,
        "abstract_tex" => abstract_tex,
        "symbols_list_tex" => symbols_list_tex,
        "template_sections_tex" => template_sections_tex,
        "appendix_tex" => appendix_tex,
        "figure_tex_includes" => figure_tex_includes,
        "active_parameter_macros_path" => parameter_context["active_parameter_macros_path"],
    )
    merge!(tex_context, symbols_context)

    md_context = Dict(
        "dataset" => dataset,
        "generated_timestamp" => timestamp,
        "theory_section" => theory_md,
        "archive_synthesis_section" => archive_md,
        "diagnostics_section" => diag_md,
        "figure_md_includes" => figure_md_includes,
    )

    rendered_tex = render_template(tex_template, tex_context)
    rendered_md = render_template(md_template, md_context; escape_values=false)

    write(tex_out, rendered_tex)
    write(md_out, rendered_md)

    println("Generated manuscript files with section annotations:")
    println(tex_out)
    println(md_out)
    return nothing
end

function main(args::Vector{String}=ARGS)
    assemble_manuscript(args)
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end