#!/usr/bin/env julia

using Dates

function parse_args(args::Vector{String})
	dataset = "CASES99"

	i = 1
	while i <= length(args)
		arg = args[i]
		if arg == "--dataset" && i < length(args)
			dataset = args[i + 1]
			i += 2
		else
			error("Unknown or incomplete argument: $(arg)")
		end
	end
	return uppercase(strip(dataset))
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

	function prettify_figure_title(stem::String)
		special_titles = Dict(
			"4d_sbl_diagnostics" => "4D Stable Boundary Layer Diagnostics",
		)
		if haskey(special_titles, stem)
			return special_titles[stem]
		end

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

	blocks = String[]
	for file in tex_files
		stem = replace(file, ".tex" => "")
		title = prettify_figure_title(stem)
		pdf_path = joinpath(fig_dir, "$(stem).pdf")
		push!(blocks, "\\begin{figure}[ht!]\n\\centering\n\\includegraphics[width=0.95\\linewidth]{$(pdf_path)}\n\\caption{$(title)}\n\\end{figure}")
	end

	image_files = sort(filter(name -> (
		(endswith(name, ".png") || endswith(name, ".jpg") || endswith(name, ".jpeg") || endswith(name, ".pdf")) &&
		!startswith(name, "figure_bifurcation_")
	), readdir(fig_dir)))

	for file in image_files
		stem = replace(file, r"\.[^.]+$" => "")
		title = prettify_figure_title(stem)
		img_path = joinpath(fig_dir, file)
		push!(blocks, "\\begin{figure}[ht!]\n\\centering\n\\includegraphics[width=0.95\\linewidth]{$(img_path)}\n\\caption{$(title)}\n\\end{figure}")
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

dataset = parse_args(ARGS)

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

fig_dir = "reports/generated/figures"
figure_tex_includes = build_tex_figure_includes(fig_dir)
figure_md_includes = build_md_figure_includes(fig_dir)

timestamp = string(Dates.now())
generated_date_human = Dates.format(Dates.now(), "U d, yyyy")

section_context = Dict(
	"dataset" => dataset,
	"generated_timestamp" => timestamp,
	"generated_date_human" => generated_date_human,
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