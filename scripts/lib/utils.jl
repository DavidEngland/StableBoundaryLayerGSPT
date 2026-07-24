function _empty_figure_config()
    return Dict{String,Any}(
        "figures" => Dict{String,Any}(),
        "preferred_stems" => String[],
        "acronyms" => Dict{String,Any}(),
        "scm_figures" => Dict{String,Any}(),
    )
end

function _normalize_dict(value)::Dict{String,Any}
    if value isa Dict{String,Any}
        return value
    end
    if value isa AbstractDict
        out = Dict{String,Any}()
        for (k, v) in pairs(value)
            out[string(k)] = v
        end
        return out
    end
    return Dict{String,Any}()
end

function _normalize_string_vector(value)::Vector{String}
    if value isa AbstractVector
        return [string(v) for v in value]
    end
    return String[]
end

function _normalize_figure_config(cfg)::Dict{String,Any}
    out = _empty_figure_config()
    if !(cfg isa AbstractDict)
        return out
    end

    out["figures"] = _normalize_dict(get(cfg, "figures", Dict{String,Any}()))
    out["preferred_stems"] = _normalize_string_vector(get(cfg, "preferred_stems", String[]))
    out["acronyms"] = _normalize_dict(get(cfg, "acronyms", Dict{String,Any}()))
    out["scm_figures"] = _normalize_dict(get(cfg, "scm_figures", Dict{String,Any}()))
    return out
end

function load_manuscript_figure_config(config_path::String=joinpath("config", "manuscript_figures.json"))
    if !isfile(config_path)
        @warn "Figure configuration file not found at $(config_path). Using defaults."
        return _empty_figure_config()
    end

    parsed = try
        JSON3.read(read(config_path, String))
    catch err
        @warn "Failed to parse figure config at $(config_path): $(err). Using defaults."
        return _empty_figure_config()
    end

    normalized = _normalize_figure_config(parsed)
    for key in ("figures", "preferred_stems", "acronyms", "scm_figures")
        if !haskey(normalized, key)
            @warn "Figure config missing key $(key); using default fallback."
        end
    end
    return normalized
end
