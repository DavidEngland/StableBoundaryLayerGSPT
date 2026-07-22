module CaseDefaults

export get_case_ts_min
export normalize_case_symbol

"""Normalize case names so config logic can accept either String or Symbol."""
function normalize_case_symbol(case_name::Union{Symbol,AbstractString})::Symbol
    raw = case_name isa Symbol ? String(case_name) : String(case_name)
    canon = lowercase(strip(raw))
    if canon in ("sheba", "domec", "dome_c", "polar", "antarctic")
        return :polar
    elseif canon in ("cases99", "floss", "gabls1", "idealized_sbl", "midlat", "midlatitude")
        return :midlat
    else
        return Symbol(canon)
    end
end

"""Case-aware default lower safeguard for surface skin temperature (Kelvin)."""
function get_case_ts_min(case_name::Union{Symbol,AbstractString})::Float64
    case_sym = normalize_case_symbol(case_name)
    if case_sym === :polar
        return 200.0
    end
    return 240.0
end

end