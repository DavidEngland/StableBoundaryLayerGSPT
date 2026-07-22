#!/usr/bin/env julia
# src/Visualization/Visualization.jl
module Visualization

using Dates
using JSON3
using SHA

export generate_figure_bundle, generate_bifurcation_figure_bundles

const FIGURES_DIR = "figures"
const REPORTS_FIGURES_DIR = joinpath("reports", "generated", "figures")

"""Normalize file paths to forward slashes for TeX compiler compatibility across operating systems."""
function _tex_safe_path(path::String)
    return replace(abspath(path), '\\' => '/')
end

function _tex_document(plot_body::String; extra_axis_opts::String="")
    return """
\\documentclass[tikz,border=3pt]{standalone}
\\usepackage{pgfplots}
\\pgfplotsset{compat=1.18}
\\usepgfplotslibrary{colormaps,fillbetween}
\\begin{document}
\\begin{tikzpicture}
\\begin{axis}[
  grid=both,
  grid style={dashed, gray!30},
  tick label style={font=\\footnotesize},
  label style={font=\\small},
  $(extra_axis_opts)
]
$(plot_body)
\\end{axis}
\\end{tikzpicture}
\\end{document}
"""
end

function _compile_tex_to_pdf(tex_path::String)
    tex_dir = dirname(tex_path)
    pdf_path = replace(tex_path, ".tex" => ".pdf")
    compile_log = replace(tex_path, ".tex" => ".compile.log")

    tectonic = Sys.which("tectonic")
    pdflatex = Sys.which("pdflatex")
    compiled_ok = false

    mktempdir() do tmpdir
        if tectonic !== nothing
            try
                ok = open(compile_log, "w") do io
                    success(pipeline(`$(tectonic) --outdir $(tmpdir) $(tex_path)`, stdout=io, stderr=io))
                end
                tmp_pdf = joinpath(tmpdir, basename(pdf_path))
                if ok && isfile(tmp_pdf) && filesize(tmp_pdf) > 0
                    cp(tmp_pdf, pdf_path; force=true)
                    compiled_ok = true
                end
            catch err
                @warn "Tectonic compilation failed, attempting fallback if available" exception=err
            end
        end

        if !compiled_ok && pdflatex !== nothing
            try
                ok = open(compile_log, tectonic === nothing ? "w" : "a") do io
                    if tectonic !== nothing
                        write(io, "\n--- pdflatex fallback ---\n")
                    end
                    success(
                        pipeline(
                            `$(pdflatex) -interaction=nonstopmode -halt-on-error -output-directory $(tmpdir) $(tex_path)`,
                            stdout=io,
                            stderr=io,
                        ),
                    )
                end
                tmp_pdf = joinpath(tmpdir, basename(pdf_path))
                if ok && isfile(tmp_pdf) && filesize(tmp_pdf) > 0
                    cp(tmp_pdf, pdf_path; force=true)
                    compiled_ok = true
                end
            catch err
                @warn "PDFLaTeX compilation failed" exception=err
            end
        end
    end

    if compiled_ok
        return true
    end

    if tectonic === nothing && pdflatex === nothing
        error("No TeX compiler found. Install pdflatex or tectonic to generate PDF figures.")
    end
    error("Failed to compile $(tex_path). See $(compile_log) for diagnostics.")
end

function _sha256_file(path::String)
    return bytes2hex(sha256(read(path)))
end

function _validate_csv_columns(csv_path::String, required_columns::Vector{String})
    header = try
        open(readline, csv_path)
    catch
        error("Could not read CSV header from $(csv_path)")
    end
    present_columns = split(chomp(header), ',')
    missing_columns = setdiff(required_columns, present_columns)
    isempty(missing_columns) ||
        error("CSV $(csv_path) is missing required columns: $(join(missing_columns, ", "))")
end

function _csv_row_count(csv_path::String)
    rows = 0
    open(csv_path, "r") do io
        for _ in eachline(io)
            rows += 1
        end
    end
    return max(rows - 1, 0)
end

function _auto_each_nth(npoints::Integer)
    if npoints > 500_000
        return 10
    elseif npoints > 100_000
        return 5
    end
    return 1
end

function _build_figure(
    ;
    figure_id::String,
    dataset::String,
    caption::String,
    description::String,
    source_csv::String,
    plot_body::String,
    extra_axis_opts::String,
    provenance::AbstractDict{String,<:Any},
)
    tex_path = joinpath(FIGURES_DIR, "$(figure_id).tex")
    write(tex_path, _tex_document(plot_body; extra_axis_opts=extra_axis_opts))
    _compile_tex_to_pdf(tex_path) || error("Failed to compile $(tex_path)")
    return _write_figure_sidecars(
        figure_id=figure_id,
        dataset=dataset,
        caption=caption,
        description=description,
        source_csv=source_csv,
        tex_path=tex_path,
        provenance=provenance,
    )
end

function _write_figure_sidecars(
    ;
    figure_id::String,
    dataset::String,
    caption::String,
    description::String,
    source_csv::String,
    tex_path::String,
    provenance::AbstractDict{String,<:Any},
)
    md_path = replace(tex_path, ".tex" => ".md")
    json_path = replace(tex_path, ".tex" => ".json")
    pdf_path = replace(tex_path, ".tex" => ".pdf")

    write(
        md_path,
        "# $(figure_id)\n\n" *
        "Dataset: $(dataset)\n\n" *
        "Caption: $(caption)\n\n" *
        "Description: $(description)\n\n" *
        "Source CSV: $(source_csv)\n",
    )

    sidecar = Dict(
        "artifact_id" => figure_id,
        "dataset" => dataset,
        "caption" => caption,
        "description" => description,
        "script" => "scripts/sweep_bifurcation.jl",
        "generated" => string(Dates.now()),
        "source_csv" => source_csv,
        "source_csv_sha256" => _sha256_file(source_csv),
        "runtime" => Dict("julia_version" => string(VERSION), "hostname" => get(ENV, "HOSTNAME", "unknown")),
        "paths" => Dict("pdf" => pdf_path, "tex" => tex_path, "md" => md_path, "json" => json_path),
        "provenance" => provenance,
    )

    open(json_path, "w") do io
        JSON3.pretty(io, sidecar)
    end

    mkpath(REPORTS_FIGURES_DIR)
    for src in (pdf_path, tex_path, md_path, json_path)
        if isfile(src)
            dst = joinpath(REPORTS_FIGURES_DIR, basename(src))
            try
                cp(src, dst; force=true)
            catch err
                @warn "Failed to copy figure artifact" source=src destination=dst exception=err
            end
        end
    end

    return Dict("pdf" => pdf_path, "tex" => tex_path, "md" => md_path, "json" => json_path)
end

"""Generate TikZ/PDF figure bundles for bifurcation maps and uncertainty envelopes."""
function generate_bifurcation_figure_bundles(dataset::String, run_dir::String, provenance::AbstractDict{String,<:Any})
    mkpath(FIGURES_DIR)

    trans_map_csv = joinpath(run_dir, "transcritical_map.csv")
    fold_map_csv = joinpath(run_dir, "fold_map.csv")
    trans_env_csv = joinpath(run_dir, "transcritical_envelope.csv")
    fold_env_csv = joinpath(run_dir, "fold_envelope.csv")
    sensitivity_env_csv = joinpath(run_dir, "parameter_sensitivity_envelope.csv")

    all(isfile, [trans_map_csv, fold_map_csv, trans_env_csv, fold_env_csv, sensitivity_env_csv]) ||
        error("Missing required bifurcation CSV artifacts in $(run_dir)")

    _validate_csv_columns(trans_map_csv, ["S", "Gamma", "Delta", "distance_to_transcritical"])
    _validate_csv_columns(fold_map_csv, ["Ts", "S", "H"])
    _validate_csv_columns(trans_env_csv, ["S", "gamma_c_p05", "gamma_c_p50", "gamma_c_p95"])
    _validate_csv_columns(fold_env_csv, ["Ts_p50", "S_fold_p50"])
    _validate_csv_columns(sensitivity_env_csv, ["scale", "gamma_c_min", "gamma_c_p50", "gamma_c_max"])

    trans_map_nth = _auto_each_nth(_csv_row_count(trans_map_csv))
    fold_map_nth = _auto_each_nth(_csv_row_count(fold_map_csv))

    bundles = Dict{String,Any}()

    # Figure A: transcritical map with viridis shading and downsampling safeguard
    fig_a = "figure_bifurcation_transcritical_map"
    rel_a = _tex_safe_path(trans_map_csv)
    opts_a = "xlabel={\$S\$}, ylabel={\$\\Gamma\$}, colorbar, colormap name=viridis, title={Transcritical Transition Boundary}"
    plot_a = """
\\addplot[
  only marks,
  mark=*,
  mark size=0.65pt,
  filter discard warning=false,
  each nth point=$(trans_map_nth),
  scatter,
  scatter src=explicit,
] table[x=S,y=Gamma,meta=Delta,col sep=comma] {$(rel_a)};
"""
    bundles[fig_a] = _build_figure(
        figure_id=fig_a,
        dataset=dataset,
        caption="Transcritical map in (S, Gamma) space colored by Delta.",
        description="Synthetic sweep map identifying turbulent/laminar boundary geometry.",
        source_csv=trans_map_csv,
        plot_body=plot_a,
        extra_axis_opts=opts_a,
        provenance=provenance,
    )

    # Figure B: fold map with manifold projection labels
    fig_b = "figure_bifurcation_fold_map"
    rel_b = _tex_safe_path(fold_map_csv)
    opts_b = "xlabel={\$T_s\$ (K)}, ylabel={\$S\$}, colorbar, colormap name=viridis, title={Fold Bifurcation Manifold Projection}"
    plot_b = """
\\addplot[
  only marks,
  mark=*,
  mark size=0.65pt,
  filter discard warning=false,
  each nth point=$(fold_map_nth),
  scatter,
  scatter src=explicit,
] table[x=Ts,y=S,meta=H,col sep=comma] {$(rel_b)};
"""
    bundles[fig_b] = _build_figure(
        figure_id=fig_b,
        dataset=dataset,
        caption="Fold map in (Ts, S) space colored by manifold proxy H.",
        description="Synthetic reduced-manifold fold diagnostic map.",
        source_csv=fold_map_csv,
        plot_body=plot_b,
        extra_axis_opts=opts_b,
        provenance=provenance,
    )

    # Figure C: transcritical uncertainty envelope
    fig_c = "figure_bifurcation_transcritical_envelope"
    rel_c = _tex_safe_path(trans_env_csv)
    opts_c = "xlabel={\$S\$}, ylabel={\$\\gamma_c\$}, legend pos=north west, title={Transcritical Uncertainty Bands}"
    plot_c = """
\\addplot[name path=p95, draw=none] table[x=S,y=gamma_c_p95,col sep=comma] {$(rel_c)};
\\addplot[name path=p05, draw=none] table[x=S,y=gamma_c_p05,col sep=comma] {$(rel_c)};
\\addplot[blue!20, fill opacity=0.35] fill between[of=p95 and p05];
\\addlegendentry{p05--p95}
\\addplot[thick, black] table[x=S,y=gamma_c_p50,col sep=comma] {$(rel_c)};
\\addlegendentry{median}
"""
    bundles[fig_c] = _build_figure(
        figure_id=fig_c,
        dataset=dataset,
        caption="Transcritical threshold uncertainty envelope with shaded p05--p95 band and median curve.",
        description="Monte Carlo envelope for Gamma_c(S).",
        source_csv=trans_env_csv,
        plot_body=plot_c,
        extra_axis_opts=opts_c,
        provenance=provenance,
    )

    # Figure D: fold-point uncertainty summary
    fig_d = "figure_bifurcation_fold_envelope"
    rel_d = _tex_safe_path(fold_env_csv)
    opts_d = "xlabel={\$T_{s,\\mathrm{p50}}\$ (K)}, ylabel={\$S_{\\mathrm{fold},\\mathrm{p50}}\$}, legend pos=south east, title={Fold-Point Median Coordinates}"
    plot_d = """
\\addplot[only marks, mark=*, mark size=2.2pt, blue]
  table[x=Ts_p50,y=S_fold_p50,col sep=comma] {$(rel_d)};
\\addlegendentry{branch medians}
"""
    bundles[fig_d] = _build_figure(
        figure_id=fig_d,
        dataset=dataset,
        caption="Fold-point medians in (Ts, S) with branch-wise uncertainty CSV sidecars.",
        description="Summary of fold-point uncertainty for plus/minus branches.",
        source_csv=fold_env_csv,
        plot_body=plot_d,
        extra_axis_opts=opts_d,
        provenance=provenance,
    )

    # Figure E: transcritical distance map
    fig_e = "figure_bifurcation_transcritical_distance_map"
    rel_e = _tex_safe_path(trans_map_csv)
    opts_e = "xlabel={\$S\$}, ylabel={\$\\Gamma\$}, colorbar, colormap name=viridis, title={Transcritical Distance Field}"
    plot_e = """
\\addplot[
  only marks,
  mark=square*,
  mark size=0.65pt,
  filter discard warning=false,
  each nth point=$(trans_map_nth),
  scatter,
  scatter src=explicit,
] table[x=S,y=Gamma,meta=distance_to_transcritical,col sep=comma] {$(rel_e)};
"""
    bundles[fig_e] = _build_figure(
        figure_id=fig_e,
        dataset=dataset,
        caption="Transcritical distance field in (S, Gamma) space using absolute distance to Delta=0.",
        description="Heatmap-style scatter highlighting near-threshold regions for boundary-crossing transitions.",
        source_csv=trans_map_csv,
        plot_body=plot_e,
        extra_axis_opts=opts_e,
        provenance=provenance,
    )

    # Figure F: parameter-sensitivity envelope
    fig_f = "figure_bifurcation_parameter_sensitivity_envelope"
    rel_f = _tex_safe_path(sensitivity_env_csv)
    opts_f = "xlabel={scale multiplier}, ylabel={\$\\gamma_c\$ threshold}, legend pos=north west, title={Parameter Sensitivity Envelope}"
    plot_f = """
\\addplot[name path=gmax, draw=none] table[x=scale,y=gamma_c_max,col sep=comma] {$(rel_f)};
\\addplot[name path=gmin, draw=none] table[x=scale,y=gamma_c_min,col sep=comma] {$(rel_f)};
\\addplot[red!20, fill opacity=0.35] fill between[of=gmax and gmin];
\\addlegendentry{min--max}
\\addplot[thick, black] table[x=scale,y=gamma_c_p50,col sep=comma] {$(rel_f)};
\\addlegendentry{median}
"""
    bundles[fig_f] = _build_figure(
        figure_id=fig_f,
        dataset=dataset,
        caption="Parameter-sensitivity envelope with shaded min--max band and median curve across scale multipliers.",
        description="Sensitivity of transcritical threshold statistics to coupled parameter scaling.",
        source_csv=sensitivity_env_csv,
        plot_body=plot_f,
        extra_axis_opts=opts_f,
        provenance=provenance,
    )

    return bundles
end

"""Generate figure text artifacts and machine-readable metadata sidecar."""
function generate_figure_bundle(dataset::String, diagnostics::AbstractDict{String,<:Any}, provenance::AbstractDict{String,<:Any})
    mkpath(FIGURES_DIR)
    mkpath(REPORTS_FIGURES_DIR)

    figure_id = "figure01"
    caption = "Phase-space diagnostic summary for $(dataset)."
    ri_mean = diagnostics["ri_mean"]
    tke_mean = diagnostics["tke_mean"]

    opts = "xlabel={Ri Mean}, ylabel={TKE Mean}, title={Phase-Space Diagnostic Summary}"
    plot_body = """
\\node[draw, fill=blue!10, rounded corners, align=center] at (axis cs:0.5,0.5) {
  \\textbf{$(caption)}\\\\[4pt]
  Ri Mean: $(ri_mean)\\\\
  TKE Mean: $(tke_mean)
};
"""

    tex_path = joinpath(FIGURES_DIR, "$(figure_id).tex")
    write(tex_path, _tex_document(plot_body; extra_axis_opts=opts))
    _compile_tex_to_pdf(tex_path)

    md_path = replace(tex_path, ".tex" => ".md")
    pdf_path = replace(tex_path, ".tex" => ".pdf")
    json_path = replace(tex_path, ".tex" => ".json")

    write(md_path, "# $(figure_id)\n\n$(caption)\n\nri_mean=$(ri_mean), tke_mean=$(tke_mean)\n")

    meta = Dict(
        "artifact_id" => figure_id,
        "dataset" => dataset,
        "generated" => string(Dates.now()),
        "script" => "run_pipeline.jl",
        "kind" => "figure",
        "provenance" => provenance,
        "paths" => Dict("pdf" => pdf_path, "tex" => tex_path, "md" => md_path, "json" => json_path),
    )
    open(json_path, "w") do io
        JSON3.pretty(io, meta)
    end

    for src in (pdf_path, tex_path, md_path, json_path)
        if isfile(src)
            cp(src, joinpath(REPORTS_FIGURES_DIR, basename(src)); force=true)
        end
    end

    return Dict("pdf" => pdf_path, "md" => md_path, "tex" => tex_path, "json" => json_path)
end

end