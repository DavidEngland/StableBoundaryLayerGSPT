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

function build_tex_figure_includes(fig_dir::String)
	if !isdir(fig_dir)
		return "% No generated figures directory found."
	end

	tex_files = sort(filter(name -> startswith(name, "figure_bifurcation_") && endswith(name, ".tex"), readdir(fig_dir)))
	if isempty(tex_files)
		return "% No bifurcation TEX figures found."
	end

	blocks = String[]
	for file in tex_files
		stem = replace(file, ".tex" => "")
		title = replace(stem, "_" => " ")
		pdf_path = joinpath(fig_dir, "$(stem).pdf")
		push!(blocks, "\\subsection*{$(title)}\n\\includegraphics[width=0.95\\linewidth]{$(pdf_path)}")
	end
	return join(blocks, "\n\n")
end

function build_md_figure_includes(fig_dir::String)
	if !isdir(fig_dir)
		return "No generated figures directory found."
	end

	md_files = sort(filter(name -> startswith(name, "figure_bifurcation_") && endswith(name, ".md"), readdir(fig_dir)))
	if isempty(md_files)
		return "No bifurcation markdown figure sidecars found."
	end

	lines = String[]
	for file in md_files
		push!(lines, "- reports/generated/figures/$(file)")
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
diag_md = read_text("reports/generated/diagnostics/03_bifurcation_sweep.md"; fallback="Diagnostics section not generated yet.")

theory_tex = "\\paragraph{Theory Source} See \\path{reports/generated/theory/01_state_space.md}"
diag_tex = "\\paragraph{Diagnostics Source} See \\path{reports/generated/diagnostics/03_bifurcation_sweep.md}"

fig_dir = "reports/generated/figures"
figure_tex_includes = build_tex_figure_includes(fig_dir)
figure_md_includes = build_md_figure_includes(fig_dir)

timestamp = string(Dates.now())

tex_context = Dict(
	"dataset" => dataset,
	"generated_timestamp" => timestamp,
	"theory_section" => theory_tex,
	"diagnostics_section" => diag_tex,
	"figure_tex_includes" => figure_tex_includes,
)

md_context = Dict(
	"dataset" => dataset,
	"generated_timestamp" => timestamp,
	"theory_section" => theory_md,
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