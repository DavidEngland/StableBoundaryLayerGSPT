#!/usr/bin/env julia

"""
    render_ssot_tex.jl

Render the SSOT mustache template into a TeX manuscript using Julia only.

Usage:
    julia --project=. scripts/render_ssot_tex.jl \
        --template templates/tex.mustache \
        --data config/ssot_data.json \
        --out reports/generated/manuscript_ssot.tex
"""

using JSON3
using Mustache

function infer_event_branch(type_label::AbstractString)
    normalized = lowercase(type_label)
    if occursin("collapse", normalized)
        return "Collapse"
    elseif occursin("recover", normalized)
        return "Recovery"
    elseif occursin("burst", normalized)
        return "Burst"
    else
        return "Active"
    end
end

function inject_derived_fields!(data::Dict{String, Any})
    meta = get(data, "meta", Dict{String, Any}())
    keywords = get(meta, "keywords", Any[])
    if keywords isa AbstractVector
        meta["keywords_csv"] = join(string.(keywords), ", ")
    else
        meta["keywords_csv"] = ""
    end
    data["meta"] = meta

    diagnostics = get(data, "diagnostics", Dict{String, Any}())
    events = get(diagnostics, "events", Any[])
    if events isa AbstractVector
        for event in events
            if event isa Dict{String, Any}
                event["event_branch"] = get(event, "event_branch", infer_event_branch(string(get(event, "type_label", ""))))
            end
        end
        diagnostics["events"] = events
    end
    data["diagnostics"] = diagnostics

    return data
end

function parse_args(args)
    template = "templates/tex.mustache"
    data = "config/ssot_data.json"
    out = "reports/generated/manuscript_ssot.tex"

    i = 1
    while i <= length(args)
        if args[i] == "--template" && i < length(args)
            template = args[i + 1]
            i += 1
        elseif args[i] == "--data" && i < length(args)
            data = args[i + 1]
            i += 1
        elseif args[i] == "--out" && i < length(args)
            out = args[i + 1]
            i += 1
        end
        i += 1
    end

    return template, data, out
end

function main()
    template_path, data_path, out_path = parse_args(ARGS)

    if !isfile(template_path)
        error("Template not found: $template_path")
    end
    if !isfile(data_path)
        error("Data file not found: $data_path")
    end

    template = read(template_path, String)
    data = JSON3.read(read(data_path, String), Dict{String, Any})
    inject_derived_fields!(data)

    rendered = Mustache.render(template, data)

    mkpath(dirname(out_path))
    write(out_path, rendered)
    println("Rendered TeX written to: $out_path")
end

main()
