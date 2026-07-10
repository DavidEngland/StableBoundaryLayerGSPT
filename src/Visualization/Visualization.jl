module Visualization

using Dates
using JSON3

export generate_figure_bundle, generate_bifurcation_figure_bundles

function _tex_document(plot_body::String)
    return """
\\documentclass[tikz,border=3pt]{standalone}
\\usepackage{pgfplots}
\\pgfplotsset{compat=1.18}
\\begin{document}
\\begin{tikzpicture}
\\begin{axis}
$(plot_body)
\\end{axis}
\\end{tikzpicture}
\\end{document}
"""
end

function _compile_tex_to_pdf(tex_path::String)
    tex_dir = dirname(tex_path)
    pdf_path = replace(tex_path, ".tex" => ".pdf")

    tectonic = Sys.which("tectonic")
    if tectonic !== nothing
        try
            run(`$(tectonic) --outdir $(tex_dir) $(tex_path)`)
            return isfile(pdf_path)
        catch
            # Fall through to pdflatex backend.
        end
    end

    pdflatex = Sys.which("pdflatex")
    if pdflatex !== nothing
        run(`$(pdflatex) -interaction=nonstopmode -halt-on-error -output-directory $(tex_dir) $(tex_path)`)
        return isfile(pdf_path)
    end

    error("No TeX compiler found. Install pdflatex or tectonic to generate PDF figures.")
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
        "paths" => Dict("pdf" => pdf_path, "tex" => tex_path, "md" => md_path, "json" => json_path),
        "provenance" => provenance,
    )

    open(json_path, "w") do io
        JSON3.pretty(io, sidecar)
    end

    mkpath("reports/generated/figures")
    cp(pdf_path, joinpath("reports/generated/figures", basename(pdf_path)); force=true)
    cp(tex_path, joinpath("reports/generated/figures", basename(tex_path)); force=true)
    cp(md_path, joinpath("reports/generated/figures", basename(md_path)); force=true)
    cp(json_path, joinpath("reports/generated/figures", basename(json_path)); force=true)

    return Dict("pdf" => pdf_path, "tex" => tex_path, "md" => md_path, "json" => json_path)
end

"""Generate TikZ/PDF figure bundles for bifurcation maps and uncertainty envelopes."""
function generate_bifurcation_figure_bundles(dataset::String, run_dir::String, provenance::AbstractDict{String,<:Any})
    mkpath("figures")

    trans_map_csv = joinpath(run_dir, "transcritical_map.csv")
    fold_map_csv = joinpath(run_dir, "fold_map.csv")
    trans_env_csv = joinpath(run_dir, "transcritical_envelope.csv")
    fold_env_csv = joinpath(run_dir, "fold_envelope.csv")

    all(isfile, [trans_map_csv, fold_map_csv, trans_env_csv, fold_env_csv]) ||
        error("Missing required bifurcation CSV artifacts in $(run_dir)")

    bundles = Dict{String,Any}()

    # Figure A: transcritical map.
    fig_a = "figure_bifurcation_transcritical_map"
    tex_a = joinpath("figures", "$(fig_a).tex")
    rel_a = relpath(trans_map_csv, dirname(tex_a))
    plot_a = """
\\addplot[
  only marks,
  mark=*,
  mark size=0.65pt,
  scatter,
  scatter src=explicit,
] table[x=S,y=Gamma,meta=Delta,col sep=comma] {$(rel_a)};
"""
    write(tex_a, _tex_document(plot_a))
    _compile_tex_to_pdf(tex_a) || error("Failed to compile $(tex_a)")
    bundles[fig_a] = _write_figure_sidecars(
        figure_id=fig_a,
        dataset=dataset,
        caption="Transcritical map in (S, Gamma) space colored by Delta.",
        description="Synthetic sweep map identifying turbulent/laminar boundary geometry.",
        source_csv=trans_map_csv,
        tex_path=tex_a,
        provenance=provenance,
    )

    # Figure B: fold map.
    fig_b = "figure_bifurcation_fold_map"
    tex_b = joinpath("figures", "$(fig_b).tex")
    rel_b = relpath(fold_map_csv, dirname(tex_b))
    plot_b = """
\\addplot[
  only marks,
  mark=*,
  mark size=0.65pt,
  scatter,
  scatter src=explicit,
] table[x=Ts,y=S,meta=H,col sep=comma] {$(rel_b)};
"""
    write(tex_b, _tex_document(plot_b))
    _compile_tex_to_pdf(tex_b) || error("Failed to compile $(tex_b)")
    bundles[fig_b] = _write_figure_sidecars(
        figure_id=fig_b,
        dataset=dataset,
        caption="Fold map in (Ts, S) space colored by manifold proxy H.",
        description="Synthetic reduced-manifold fold diagnostic map.",
        source_csv=fold_map_csv,
        tex_path=tex_b,
        provenance=provenance,
    )

    # Figure C: transcritical uncertainty envelope.
    fig_c = "figure_bifurcation_transcritical_envelope"
    tex_c = joinpath("figures", "$(fig_c).tex")
    rel_c = relpath(trans_env_csv, dirname(tex_c))
    plot_c = """
\\addplot[thick, black] table[x=S,y=gamma_c_p50,col sep=comma] {$(rel_c)};
\\addlegendentry{median}
\\addplot[dashed, blue] table[x=S,y=gamma_c_p05,col sep=comma] {$(rel_c)};
\\addlegendentry{p05}
\\addplot[dashed, red] table[x=S,y=gamma_c_p95,col sep=comma] {$(rel_c)};
\\addlegendentry{p95}
"""
    write(tex_c, _tex_document(plot_c))
    _compile_tex_to_pdf(tex_c) || error("Failed to compile $(tex_c)")
    bundles[fig_c] = _write_figure_sidecars(
        figure_id=fig_c,
        dataset=dataset,
        caption="Transcritical threshold uncertainty envelope with p05/p50/p95 bands.",
        description="Monte Carlo envelope for Gamma_c(S).",
        source_csv=trans_env_csv,
        tex_path=tex_c,
        provenance=provenance,
    )

    # Figure D: fold-point uncertainty summary.
    fig_d = "figure_bifurcation_fold_envelope"
    tex_d = joinpath("figures", "$(fig_d).tex")
    rel_d = relpath(fold_env_csv, dirname(tex_d))
    plot_d = """
\\addplot[only marks, mark=*, mark size=2.2pt, blue]
  table[x=Ts_p50,y=S_fold_p50,col sep=comma] {$(rel_d)};
\\addlegendentry{branch medians}
"""
    write(tex_d, _tex_document(plot_d))
    _compile_tex_to_pdf(tex_d) || error("Failed to compile $(tex_d)")
    bundles[fig_d] = _write_figure_sidecars(
        figure_id=fig_d,
        dataset=dataset,
        caption="Fold-point medians in (Ts, S) with branch-wise uncertainty CSV sidecars.",
        description="Summary of fold-point uncertainty for plus/minus branches.",
        source_csv=fold_env_csv,
        tex_path=tex_d,
        provenance=provenance,
    )

    return bundles
end

"""Generate figure text artifacts and machine-readable metadata sidecar."""
function generate_figure_bundle(dataset::String, diagnostics::AbstractDict{String,<:Any}, provenance::AbstractDict{String,<:Any})
    mkpath("figures")
    mkpath("reports/generated/figures")

    figure_id = "figure01"
    caption = "Phase-space diagnostic summary for $(dataset)."

    md_path = joinpath("figures", "$(figure_id).md")
    tex_path = joinpath("figures", "$(figure_id).tex")
    json_path = joinpath("figures", "$(figure_id).json")
    ri_mean = diagnostics["ri_mean"]
    tke_mean = diagnostics["tke_mean"]

    write(md_path, "# $(figure_id)\n\n$(caption)\n\nri_mean=$(ri_mean), tke_mean=$(tke_mean)\n")
    write(tex_path, "% $(figure_id)\n\\textbf{$(caption)}\\\\\nri_mean=$(ri_mean), tke_mean=$(tke_mean)\n")

    meta = Dict(
        "artifact_id" => figure_id,
        "dataset" => dataset,
        "generated" => string(Dates.now()),
        "script" => "run_pipeline.jl",
        "kind" => "figure",
        "provenance" => provenance,
    )
    open(json_path, "w") do io
        JSON3.pretty(io, meta)
    end

    cp(md_path, joinpath("reports/generated/figures", basename(md_path)); force=true)
    cp(tex_path, joinpath("reports/generated/figures", basename(tex_path)); force=true)

    return Dict("md" => md_path, "tex" => tex_path, "json" => json_path)
end

end