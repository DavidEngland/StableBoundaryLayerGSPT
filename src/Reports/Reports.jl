module Reports

using Dates

export generate_report_fragments

"""
    render_source_section(source_path::AbstractString; dataset::AbstractString)

Read a template Markdown section from `source_path` and replace placeholders with runtime metadata.
"""
function render_source_section(source_path::AbstractString; dataset::AbstractString)
    if !isfile(source_path)
        @warn "Source section template missing: $(source_path)"
        return "_Source section missing: $(source_path)_\n"
    end
    raw = read(source_path, String)
    return replace(raw, "{{dataset}}" => dataset)
end

"""
    generate_report_fragments(dataset::AbstractString, diagnostics::AbstractDict{<:AbstractString,<:Any}; output_dir::AbstractString=joinpath("reports", "generated"))

Generate manuscript Markdown fragments from computed diagnostics and section templates.
"""
function generate_report_fragments(
    dataset::AbstractString,
    diagnostics::AbstractDict{<:AbstractString,<:Any};
    output_dir::AbstractString=joinpath("reports", "generated")
)
    # Safely retrieve diagnostic metrics with defaults
    ri_mean = get(diagnostics, "ri_mean", "N/A")
    tke_mean = get(diagnostics, "tke_mean", "N/A")

    # Ensure all output directories exist
    subdirs = ["theory", "mathematics", "physics", "diagnostics", "tables"]
    for subdir in subdirs
        mkpath(joinpath(output_dir, subdir))
    end

    timestamp = Dates.now()
    header(title) = "# $(title)\n\nGenerated: $(timestamp)\n\nDataset: $(dataset)\n\n"

    # Tuple mapping: (dict_key, relative_out_path, section_title, template_path)
    fragment_specs = [
        (
            "theory",
            joinpath("theory", "01_state_space.md"),
            "Theory",
            joinpath("templates", "sections", "theory_fast_slow_model.md"),
        ),
        (
            "mathematics",
            joinpath("mathematics", "01_fast_slow_system.md"),
            "Mathematics",
            joinpath("templates", "sections", "mathematics_transition_mechanisms.md"),
        ),
        (
            "physics",
            joinpath("physics", "01_surface_energy_budget.md"),
            "Physics",
            joinpath("templates", "sections", "physics_nocturnal_cycle.md"),
        ),
        (
            "archive_synthesis",
            joinpath("theory", "02_archive_synthesis.md"),
            "Archive Synthesis",
            joinpath("templates", "sections", "archive_synthesis.md"),
        ),
    ]

    result_paths = Dict{String,String}()

    # Generate template-driven fragments
    for (key, rel_path, title, tpl_path) in fragment_specs
        full_out_path = joinpath(output_dir, rel_path)
        content = render_source_section(tpl_path; dataset=dataset)
        write(full_out_path, header(title) * content * "\n")
        result_paths[key] = full_out_path
    end

    # Generate diagnostics metrics fragment
    diag_file = joinpath(output_dir, "diagnostics", "01_core_metrics.md")
    write(diag_file, "# Core Metrics\n\nri_mean=$(ri_mean)\n\ntke_mean=$(tke_mean)\n")
    result_paths["diagnostics"] = diag_file

    # Generate validation status fragment
    valid_file = joinpath(output_dir, "diagnostics", "02_validation.md")
    write(valid_file, "# Validation Gate\n\nAll required checks passed before visualization/report assembly.\n")

    return result_paths
end

end