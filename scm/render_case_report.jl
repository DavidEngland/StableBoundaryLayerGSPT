#!/usr/bin/env julia

using Printf
import JSON3

function usage()
    println("Usage: julia scm/render_case_report.jl --summary <summary.json> [options]")
    println("Options:")
    println("  --summary <path>     Required summary JSON from scm/run_case.jl")
    println("  --template <path>    Template path (default: templates/scm_case_report.tex.mustache)")
    println("  --out <path>         Output TeX path (default: <summary_dir>/scm_case_report.tex)")
    println("  --help               Show this help")
end

function parse_args(args::Vector{String})
    cfg = Dict{String,String}(
        "summary" => "",
        "template" => "templates/scm_case_report.tex.mustache",
        "out" => "",
    )

    i = 1
    while i <= length(args)
        a = args[i]
        if a == "--help"
            usage()
            exit(0)
        elseif a == "--summary" && i < length(args)
            cfg["summary"] = args[i + 1]
            i += 2
        elseif a == "--template" && i < length(args)
            cfg["template"] = args[i + 1]
            i += 2
        elseif a == "--out" && i < length(args)
            cfg["out"] = args[i + 1]
            i += 2
        else
            error("Unknown or incomplete argument: $(a)")
        end
    end

    cfg["summary"] == "" && error("--summary is required")
    if cfg["out"] == ""
        cfg["out"] = joinpath(dirname(cfg["summary"]), "scm_case_report.tex")
    end
    return cfg
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

function fmt_num(x)
    x isa Number || return string(x)
    if abs(x) >= 1e4 || (abs(x) > 0 && abs(x) < 1e-3)
        return @sprintf("%.3e", Float64(x))
    end
    return @sprintf("%.6f", Float64(x))
end

function fmt_tex_num(x; force_sci::Bool=false)
    x isa Number || return string(x)
    xf = Float64(x)
    if xf == 0.0
        return "0"
    end

    if force_sci || abs(xf) >= 1e4 || abs(xf) < 1e-3
        s = @sprintf("%.3e", xf)
        m, e = split(s, "e")
        expo = parse(Int, e)
        return "$(m) \\times 10^{$(expo)}"
    end

    return @sprintf("%.6f", xf)
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

function slugify(s::AbstractString)
    out = lowercase(strip(s))
    out = replace(out, r"[^a-z0-9]+" => "_")
    out = replace(out, r"_+" => "_")
    out = strip(out, '_')
    isempty(out) && return "case"
    return out
end

function render_template(template::String, context::Dict{String,String})
    rendered = template
    for (k, v) in context
        rendered = replace(rendered, "{{{$(k)}}}" => v)
        rendered = replace(rendered, "{{$(k)}}" => v)
    end
    return rendered
end

function build_plot_blocks(plot_dir::String, report_dir::String, figure_manifest)
    isdir(plot_dir) || return ""

    files = readdir(plot_dir)
    plot_files = sort(filter(f -> endswith(lowercase(f), ".png"), files))
    isempty(plot_files) && return ""

    blocks = String[]
    for (i, fname) in enumerate(plot_files)
        img_path = joinpath(plot_dir, fname)
        rel_img_path = relpath(img_path, report_dir)
        cap = if figure_manifest isa AbstractVector && i <= length(figure_manifest)
            latex_escape(string(figure_manifest[i]))
        else
            latex_escape(replace(fname, "_" => " "))
        end

        push!(blocks, "\\begin{figure}[htbp]")
        push!(blocks, "  \\centering")
        # Use detokenize so underscores and special path chars don't break includegraphics.
        push!(blocks, "  \\includegraphics[width=0.95\\linewidth]{\\detokenize{$(rel_img_path)}}")
        push!(blocks, "  \\caption{$(cap)}")
        push!(blocks, "\\end{figure}")
        push!(blocks, "")
    end

    return join(blocks, "\n")
end

function read_text(path::String)
    isfile(path) || error("File not found: $(path)")
    return read(path, String)
end

function main(args)
    cfg = parse_args(args)

    summary_path = cfg["summary"]
    template_path = cfg["template"]
    out_path = cfg["out"]

    raw = read_text(summary_path)
    summary = JSON3.read(raw)

    case_name = string(getnested(summary, ["case"], "unknown_case"))
    outdir = string(getnested(summary, ["outdir"], dirname(summary_path)))
    outdir_slug = slugify(basename(outdir))
    report_slug = string(outdir_slug, "_", slugify(splitext(basename(out_path))[1]))

    figure_manifest = getnested(summary, ["figure_manifest"], Any[])
    figure_items = String[]
    if figure_manifest isa AbstractVector
        for item in figure_manifest
            push!(figure_items, "  \\item " * latex_escape(string(item)))
        end
    else
        push!(figure_items, "  \\item Figure manifest unavailable")
    end

    payload_path = string(getnested(summary, ["artifacts", "payload_jld2"], "not generated"))
    plot_dir = joinpath(outdir, "plots")
    plot_blocks = build_plot_blocks(plot_dir, dirname(out_path), figure_manifest)

    context = Dict{String,String}(
        "summary_path" => latex_escape(summary_path),
        "case_name" => latex_escape(case_name),
        "case_name_slug" => slugify(case_name),
        "report_slug" => report_slug,
        "outdir" => latex_escape(outdir),
        "n_times" => string(getnested(summary, ["n_times"], "n/a")),
        "n_profiles" => string(getnested(summary, ["n_profiles"], "n/a")),
        "solver_algorithm" => latex_escape(string(getnested(summary, ["solver_summary", "algorithm"], "n/a"))),
        "solver_retcode" => latex_escape(string(getnested(summary, ["solver_summary", "retcode"], "n/a"))),
        "solver_accepted_steps" => string(getnested(summary, ["solver_summary", "accepted_steps"], "n/a")),
        "solver_rejected_steps" => string(getnested(summary, ["solver_summary", "rejected_steps"], "n/a")),
        "solver_rhs_evaluations" => string(getnested(summary, ["solver_summary", "rhs_evaluations"], "n/a")),
        "solver_abstol" => fmt_tex_num(getnested(summary, ["solver_summary", "abstol"], "n/a"); force_sci=true),
        "solver_reltol" => fmt_tex_num(getnested(summary, ["solver_summary", "reltol"], "n/a"); force_sci=true),
        "param_Ug" => fmt_num(getnested(summary, ["parameters", "Ug"], "n/a")),
        "param_Vg" => fmt_num(getnested(summary, ["parameters", "Vg"], "n/a")),
        "param_f" => fmt_num(getnested(summary, ["parameters", "f"], "n/a")),
        "param_z0m" => fmt_num(getnested(summary, ["parameters", "z0m"], "n/a")),
        "param_z0h" => fmt_num(getnested(summary, ["parameters", "z0h"], "n/a")),
        "param_theta_a" => fmt_num(getnested(summary, ["parameters", "theta_a"], "n/a")),
        "param_T_deep" => fmt_num(getnested(summary, ["parameters", "T_deep"], "n/a")),
        "param_R_down" => fmt_num(getnested(summary, ["parameters", "R_down"], "n/a")),
        "param_lambda_s" => fmt_num(getnested(summary, ["parameters", "lambda_s"], "n/a")),
        "param_d_soil" => fmt_num(getnested(summary, ["parameters", "d_soil"], "n/a")),
        "param_k_min_surf" => fmt_num(getnested(summary, ["parameters", "k_min_surf"], "n/a")),
        "param_theta_top_bc" => latex_escape(string(getnested(summary, ["parameters", "theta_top_bc"], "n/a"))),
        "param_theta_top" => fmt_num(getnested(summary, ["parameters", "theta_top"], "n/a")),
        "param_lambda_top" => fmt_num(getnested(summary, ["parameters", "lambda_top"], "n/a")),
        "verification_max_surface_energy_closure_error" => fmt_tex_num(getnested(summary, ["verification", "max_surface_energy_closure_error"], "n/a"); force_sci=true),
        "verification_fold_near_fraction_percent" => fmt_num(100 * Float64(getnested(summary, ["verification", "fold_near_fraction"], 0.0))),
        "verification_min_diffusivity" => fmt_tex_num(getnested(summary, ["verification", "min_diffusivity"], "n/a")),
        "verification_max_diffusivity" => fmt_tex_num(getnested(summary, ["verification", "max_diffusivity"], "n/a")),
        "verification_min_ri" => fmt_tex_num(getnested(summary, ["verification", "min_ri"], "n/a")),
        "verification_max_ri" => fmt_tex_num(getnested(summary, ["verification", "max_ri"], "n/a")),
        "artifact_time_series_csv" => latex_escape(string(getnested(summary, ["artifacts", "time_series_csv"], "n/a"))),
        "artifact_summary_json" => latex_escape(summary_path),
        "artifact_payload_jld2" => latex_escape(payload_path),
        "figure_manifest_items" => join(figure_items, "\n"),
        "plots_include_blocks" => plot_blocks,
    )

    template = read_text(template_path)
    rendered = render_template(template, context)

    mkpath(dirname(out_path))
    write(out_path, rendered)

    println("Rendered SCM case report:")
    println("  summary : $(summary_path)")
    println("  template: $(template_path)")
    println("  output  : $(out_path)")
end

if abspath(PROGRAM_FILE) == @__FILE__
    main(ARGS)
end
