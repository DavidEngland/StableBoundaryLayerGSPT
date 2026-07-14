#!/usr/bin/env julia

using CSV
using DataFrames
using Dates
using LinearAlgebra
using Statistics

const DEFAULT_DATASET = "CASES99"
const DEFAULT_GENERATED_DATE_HUMAN = "July 13, 2026"

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

	i = 1
	while i <= length(args)
		arg = args[i]
		if arg == "--dataset" && i < length(args)
			dataset = args[i + 1]
			i += 2
		elseif arg == "--date" && i < length(args)
			generated_date_human = args[i + 1]
			i += 2
		else
			error("Unknown or incomplete argument: $(arg)")
		end
	end
	return uppercase(String(strip(dataset))), String(strip(generated_date_human))
end

function read_text(path::String; fallback::String="")
	return isfile(path) ? read(path, String) : fallback
end

function render_template(template::String, context::Dict{String,String})
	rendered = template
	for (k, v) in context
		rendered = replace(rendered, "{{{$(k)}}}" => v)
		rendered = replace(rendered, "{{$(k)}}" => v)
	end
	return rendered
end

function build_optional_tex_template(path::String, context::Dict{String,String}; fallback::String="")
	if !isfile(path)
		return fallback
	end
	return render_template(read_text(path), context)
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
	content_templates = filter(name -> (name != wrapper_name) && !(name in front_matter_templates), all_tex_templates)

	preferred_order = [
		"theory_gspt.tex.mustache",
		"governing_equations.tex.mustache",
		"closures.tex.mustache",
		"parameters_geometry.tex.mustache",
		"comparative_metrics.tex.mustache",
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
		push!(content_blocks, render_template(template_text, context))
	end

	content_joined = join(content_blocks, "\n\n")
	if wrapper_name in all_tex_templates
		wrapper_path = joinpath(section_dir, wrapper_name)
		wrapper_text = read_text(wrapper_path)
		wrapper_context = copy(context)
		wrapper_context["content"] = content_joined
		return render_template(wrapper_text, wrapper_context)
	end

	return content_joined
end

function build_tex_figure_includes(fig_dir::String)
	if !isdir(fig_dir)
		return "% No generated figures directory found."
	end

	FIGURE_METADATA = Dict(
		"figure_bifurcation_fold_envelope" => (
			title="Bifurcation envelope under a classical fold scenario, illustrating the structural stability boundaries where the active turbulent branch \$\\mathcal{M}_{\\mathrm{act}}\$ loses normal hyperbolicity as a function of the macro-environmental forcing parameters.",
			label="fig:fold_envelope",
		),
		"figure_bifurcation_fold_map" => (
			title="Topological phase-space map of the fold bifurcation regime. Vector fields highlight the rapid attraction toward the stable manifold branch and the catastrophic jump dynamics occurring at the interior fold point.",
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
		"4d_sbl_diagnostics" => (
			title="Complete 4D time-series trajectories and phase-space projections for the nocturnal stable boundary layer simulated under CASES99 conditions. The panels illustrate the rapid initial turbulent decay followed by the slow ageostrophic development of the nocturnal low-level jet.",
			label="fig:sbl_diagnostics",
		),
		"diagnostic_regularization_comparison" => (
			title="Comparative analysis of the state-derived vertical eddy diffusivities (\$K_m, K_h\$) versus the \$C^\\infty\$ regularized hyperbolic embedded tracks (\$K_{m,\\star}, K_{h,\\star}\$) defined in Eq.~\\eqref{eq:embedded_diffusivities}. The comparison illustrates how the smooth embedding smooths out the sharp gradient kinks at the collapse threshold while ensuring a bounded closure Jacobian \$J_K\$.",
			label="fig:regularization_comparison",
		),
	)

	function figure_caption_and_label(stem::String)
		if haskey(FIGURE_METADATA, stem)
			meta = FIGURE_METADATA[stem]
			return meta.title, meta.label
		end
		return prettify_figure_title(stem), ""
	end

	function make_figure_block(path::String, caption::String, label::String)
		label_line = isempty(label) ? "" : "\n\\label{$(label)}"
		return "\\begin{figure}[ht!]\n\\centering\n\\includegraphics[width=0.95\\linewidth]{$(path)}\n\\caption{$(caption)}$(label_line)\n\\end{figure}"
	end

	function prettify_figure_title(stem::String)
		parts = split(replace(stem, "-" => "_"), "_")
		normalized = String[]
		for part in parts
			lw = lowercase(part)
			if lw == "4d"
				push!(normalized, "4D")
			elseif lw == "sbl"
				push!(normalized, "SBL")
			elseif lw == "tke"
				push!(normalized, "TKE")
			elseif lw == "gspt"
				push!(normalized, "GSPT")
			elseif lw == "nwp"
				push!(normalized, "NWP")
			else
				push!(normalized, uppercasefirst(lw))
			end
		end
		return join(normalized, " ")
	end

	tex_files = sort(filter(name -> startswith(name, "figure_bifurcation_") && endswith(name, ".tex"), readdir(fig_dir)))
	handled_stems = Set{String}()

	blocks = String[]
	for file in tex_files
		stem = replace(file, ".tex" => "")
		push!(handled_stems, stem)
		title, label = figure_caption_and_label(stem)
		pdf_path = joinpath(fig_dir, "$(stem).pdf")
		push!(blocks, make_figure_block(pdf_path, title, label))
	end

	image_files = sort(filter(name -> (
		(endswith(name, ".png") || endswith(name, ".jpg") || endswith(name, ".jpeg") || endswith(name, ".pdf"))
	), readdir(fig_dir)))

	for file in image_files
		stem = replace(file, r"\.[^.]+$" => "")
		if stem in handled_stems
			continue
		end
		title, label = figure_caption_and_label(stem)
		img_path = joinpath(fig_dir, file)
		push!(blocks, make_figure_block(img_path, title, label))
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

dataset, generated_date_human = parse_args(ARGS)

mkpath("reports/generated")

tex_out = "reports/generated/paper.tex"
md_out = "reports/generated/paper.md"

tex_template_path = "templates/paper.tex.mustache"
md_template_path = "templates/paper.md.mustache"

tex_template = read_text(tex_template_path; fallback="\\documentclass{article}\\begin{document}Template missing.\\end{document}")
md_template = read_text(md_template_path; fallback="# Template missing")

theory_md = read_text("reports/generated/theory/01_state_space.md"; fallback="Theory section not generated yet.")
archive_md = read_text("reports/generated/theory/02_archive_synthesis.md"; fallback="Archive synthesis not generated yet.")
diag_md = read_text("reports/generated/diagnostics/03_bifurcation_sweep.md"; fallback="Diagnostics section not generated yet.")

fig_dir = first_existing_dir(["reports/generated/figures", "figures"])
figure_tex_includes = build_tex_figure_includes(fig_dir)
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
template_sections_tex = build_tex_template_sections("templates/sections", section_context)
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
	"template_sections_tex" => template_sections_tex,
	"figure_tex_includes" => figure_tex_includes,
)

md_context = Dict(
	"dataset" => dataset,
	"generated_timestamp" => timestamp,
	"theory_section" => theory_md,
	"archive_synthesis_section" => archive_md,
	"diagnostics_section" => diag_md,
	"figure_md_includes" => figure_md_includes,
)

rendered_tex = render_template(tex_template, tex_context)
rendered_md = render_template(md_template, md_context)

write(tex_out, rendered_tex)
write(md_out, rendered_md)

println("Generated manuscript files:")
println(tex_out)
println(md_out)