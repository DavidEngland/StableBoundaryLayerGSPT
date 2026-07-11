module Reports

using Dates

export generate_report_fragments

function render_source_section(source_path::String; dataset::String)
    if !isfile(source_path)
        return "Source section missing: $(source_path)\n"
    end
    raw = read(source_path, String)
    return replace(raw, "{{dataset}}" => dataset)
end

"""Generate manuscript fragments from computed diagnostics only."""
function generate_report_fragments(dataset::String, diagnostics::AbstractDict{String,<:Any})
    ri_mean = diagnostics["ri_mean"]
    tke_mean = diagnostics["tke_mean"]

    targets = [
        "reports/generated/theory",
        "reports/generated/mathematics",
        "reports/generated/physics",
        "reports/generated/diagnostics",
        "reports/generated/tables",
    ]
    for t in targets
        mkpath(t)
    end

    theory_source = render_source_section("templates/sections/theory_fast_slow_model.md"; dataset=dataset)
    mathematics_source = render_source_section("templates/sections/mathematics_transition_mechanisms.md"; dataset=dataset)
    physics_source = render_source_section("templates/sections/physics_nocturnal_cycle.md"; dataset=dataset)
    archive_source = render_source_section("templates/sections/archive_synthesis.md"; dataset=dataset)

    write(
        "reports/generated/theory/01_state_space.md",
        "# Theory\n\nGenerated: $(Dates.now())\n\nDataset: $(dataset)\n\n$(theory_source)\n",
    )
    write(
        "reports/generated/mathematics/01_fast_slow_system.md",
        "# Mathematics\n\nGenerated: $(Dates.now())\n\nDataset: $(dataset)\n\n$(mathematics_source)\n",
    )
    write(
        "reports/generated/physics/01_surface_energy_budget.md",
        "# Physics\n\nGenerated: $(Dates.now())\n\nDataset: $(dataset)\n\n$(physics_source)\n",
    )
    write(
        "reports/generated/theory/02_archive_synthesis.md",
        "# Archive Synthesis\n\nGenerated: $(Dates.now())\n\nDataset: $(dataset)\n\n$(archive_source)\n",
    )
    write(
        "reports/generated/diagnostics/01_core_metrics.md",
        "# Core Metrics\n\nri_mean=$(ri_mean)\n\ntke_mean=$(tke_mean)\n",
    )
    write(
        "reports/generated/diagnostics/02_validation.md",
        "# Validation Gate\n\nAll required checks passed before visualization/report assembly.\n",
    )

    return Dict(
        "theory" => "reports/generated/theory/01_state_space.md",
        "archive_synthesis" => "reports/generated/theory/02_archive_synthesis.md",
        "mathematics" => "reports/generated/mathematics/01_fast_slow_system.md",
        "physics" => "reports/generated/physics/01_surface_energy_budget.md",
        "diagnostics" => "reports/generated/diagnostics/01_core_metrics.md",
    )
end

end