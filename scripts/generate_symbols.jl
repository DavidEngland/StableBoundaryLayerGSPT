#!/usr/bin/env julia
# scripts/generate_symbols.jl - Symbol Single Source of Truth (SSOT) Generator
#
# Generates LaTeX and Markdown representations of symbols defined in `spec/symbols.yaml`.
# Produces:
# - `reports/generated/sections/list_of_symbols.tex`
# - `docs/SYMBOLS.md`
# - Context dictionary for manuscript assembly

module SymbolSSOT

using YAML

export generate_symbols_assets

const REQUIRED_SYMBOL_KEYS = [
    "id",
    "symbol_tex",
    "symbol_md",
    "code_key",
    "units_tex",
    "units_md",
    "name",
    "description",
    "category",
]

# Keys allowed to be empty or "-" (e.g. dimensionless parameters)
const ALLOW_EMPTY_FIELDS = Set(["units_tex", "units_md"])

function _read_yaml(path::String)
    isfile(path) || error("Missing symbols spec file: $(path)")
    return YAML.load_file(path)
end

function _latex_escape(s::AbstractString)
    return replace(
        String(s),
        "\\" => "\\textbackslash{}",
        "{" => "\\{",
        "}" => "\\}",
        "_" => "\\_",
        "%" => "\\%",
        "#" => "\\#",
        "&" => "\\&",
        "~" => "\\textasciitilde{}",
        "\$" => "\\\$",
        "^" => "\\textasciicircum{}",
        "<" => "\\textless{}",
        ">" => "\\textgreater{}"
    )
end

function _validate_categories(categories)
    categories isa AbstractVector || error("symbols.yaml: 'categories' must be a list")
    cat_ids = String[]

    for (idx, c) in enumerate(categories)
        c isa AbstractDict || error("Category at index $(idx) must be a key-value mapping")
        haskey(c, "id") || error("Category at index $(idx) missing required key 'id'")
        haskey(c, "name") || error("Category '$(c["id"])' missing required key 'name'")

        id_str = String(c["id"])
        name_str = String(c["name"])

        c["id"] isa AbstractString || error("Category id '$(id_str)' must be a string")
        c["name"] isa AbstractString || error("Category name for '$(id_str)' must be a string")

        !isempty(strip(id_str)) || error("Category id at index $(idx) cannot be empty")
        !isempty(strip(name_str)) || error("Category name for '$(id_str)' cannot be empty")

        push!(cat_ids, id_str)
    end

    length(unique(cat_ids)) == length(cat_ids) || error("Duplicate category ids found in symbols.yaml")
    return Set(cat_ids)
end

function _validate_symbols(symbols, valid_cat_set::Set{String})
    symbols isa AbstractVector || error("symbols.yaml: 'symbols' must be a list")

    for (idx, s) in enumerate(symbols)
        s isa AbstractDict || error("Symbol entry at index $(idx) must be a key-value mapping")
        sid = haskey(s, "id") ? String(s["id"]) : "at index $(idx)"

        for k in REQUIRED_SYMBOL_KEYS
            haskey(s, k) || error("Symbol '$(sid)' missing required field '$(k)'")
            val = s[k]
            val isa AbstractString || error("Symbol '$(sid)': field '$(k)' must be a string (got $(typeof(val)))")

            if !(k in ALLOW_EMPTY_FIELDS) && isempty(strip(String(val)))
                error("Symbol '$(sid)': field '$(k)' cannot be empty")
            end
        end

        cat = String(s["category"])
        cat in valid_cat_set || error("Symbol '$(sid)' references unknown category '$(cat)'")
    end
end

function _validate_uniqueness(symbols)
    ids = String[]
    tex_symbols = String[]
    code_keys = String[]

    for s in symbols
        sid = String(s["id"])
        stex = String(s["symbol_tex"])
        ckey = String(s["code_key"])

        sid in ids && error("Duplicate symbol id found: '$(sid)'")
        stex in tex_symbols && error("Duplicate symbol_tex found: '$(stex)' (symbol id: '$(sid)')")
        ckey in code_keys && error("Duplicate code_key found: '$(ckey)' (symbol id: '$(sid)')")

        push!(ids, sid)
        push!(tex_symbols, stex)
        push!(code_keys, ckey)
    end
end

function _validate_spec(spec)
    haskey(spec, "schema_version") || error("symbols.yaml missing required top-level key 'schema_version'")
    haskey(spec, "categories") || error("symbols.yaml missing required top-level key 'categories'")
    haskey(spec, "symbols") || error("symbols.yaml missing required top-level key 'symbols'")

    valid_cat_set = _validate_categories(spec["categories"])
    _validate_symbols(spec["symbols"], valid_cat_set)
    _validate_uniqueness(spec["symbols"])
end

function _symbols_by_category(spec; sort_by_id::Bool=false)
    grouped = Dict{String,Vector{Any}}()
    for s in spec["symbols"]
        cat = String(s["category"])
        if !haskey(grouped, cat)
            grouped[cat] = Any[]
        end
        push!(grouped[cat], s)
    end

    if sort_by_id
        for (_, group) in grouped
            sort!(group; by=x -> String(x["id"]))
        end
    end

    return grouped
end

function _format_units_tex(raw_units::AbstractString)
    u = strip(String(raw_units))
    return (u == "-" || isempty(u)) ? "---" : "\\($(u)\\)"
end

function _format_units_md(raw_units::AbstractString)
    u = strip(String(raw_units))
    return (u == "-" || isempty(u)) ? "---" : "`$(u)`"
end

function _render_tex(spec; generated_path::String)
    grouped = _symbols_by_category(spec)
    categories = spec["categories"]

    lines = String[]
    push!(lines, "% Auto-generated by scripts/generate_symbols.jl. Do not edit by hand.")
    push!(lines, "% Source: $(generated_path)")
    push!(lines, "\\section*{List of Symbols}")
    push!(lines, "\\small")
    push!(lines, "\\setlength{\\tabcolsep}{5pt}")
    push!(lines, "\\renewcommand{\\arraystretch}{1.15}")
    push!(lines, "\\begin{center}")
    push!(lines, "\\begin{tabular}{p{0.14\\textwidth}p{0.34\\textwidth}p{0.18\\textwidth}p{0.24\\textwidth}}")
    push!(lines, "\\toprule")
    push!(lines, "\\textbf{Symbol} & \\textbf{Meaning} & \\textbf{Units} & \\textbf{Code Mapping} \\\\")
    push!(lines, "\\midrule")

    first_cat = true
    for cat in categories
        cat_id = String(cat["id"])
        cat_name = _latex_escape(String(cat["name"]))
        entries = get(grouped, cat_id, Any[])
        isempty(entries) && continue

        if !first_cat
            push!(lines, "\\addlinespace[0.6em]")
        end
        first_cat = false

        push!(lines, "\\multicolumn{4}{l}{\\textbf{$(cat_name)}} \\\\")
        push!(lines, "\\midrule")

        for e in entries
            symbol_tex = String(e["symbol_tex"])
            meaning = _latex_escape(String(e["name"]))
            units_tex = _format_units_tex(String(e["units_tex"]))
            code_key = _latex_escape(String(e["code_key"]))
            push!(lines, "\\($(symbol_tex)\\) & $(meaning) & $(units_tex) & \\texttt{$(code_key)} \\\\")
        end
    end

    push!(lines, "\\bottomrule")
    push!(lines, "\\end{tabular}")
    push!(lines, "\\end{center}")
    push!(lines, "\\normalsize")
    push!(lines, "")

    return join(lines, "\n")
end

function _render_markdown(spec; generated_path::String)
    grouped = _symbols_by_category(spec)
    categories = spec["categories"]

    lines = String[]
    push!(lines, "# Symbols Reference")
    push!(lines, "")
    push!(lines, "Auto-generated from `$(generated_path)`. Do not edit by hand.")
    push!(lines, "")

    for cat in categories
        cat_id = String(cat["id"])
        entries = get(grouped, cat_id, Any[])
        isempty(entries) && continue

        push!(lines, "## $(String(cat["name"]))")
        push!(lines, "")
        push!(lines, "| Symbol | Meaning | Units | Code Mapping |")
        push!(lines, "| --- | --- | --- | --- |")

        for e in entries
            symbol_md = String(e["symbol_md"])
            meaning = String(e["name"])
            units_md = _format_units_md(String(e["units_md"]))
            code_key = String(e["code_key"])
            push!(lines, "| `$(symbol_md)` | $(meaning) | $(units_md) | `$(code_key)` |")
        end
        push!(lines, "")
    end

    return join(lines, "\n")
end

function _build_context(spec)
    context = Dict{String,String}()

    for e_any in spec["symbols"]
        e = e_any
        id = String(e["id"])

        context["symbol_$(id)_tex"] = String(e["symbol_tex"])
        context["symbol_$(id)_md"] = String(e["symbol_md"])
        context["symbol_$(id)_code"] = String(e["code_key"])
        context["symbol_$(id)_name"] = String(e["name"])
        context["symbol_$(id)_description"] = String(e["description"])
        context["symbol_$(id)_units_tex"] = String(e["units_tex"])
        context["symbol_$(id)_units_md"] = String(e["units_md"])

        if haskey(e, "aliases") && e["aliases"] isa AbstractVector
            context["symbol_$(id)_aliases"] = join(String.(e["aliases"]), ", ")
        end
        if haskey(e, "references") && e["references"] isa AbstractVector
            context["symbol_$(id)_references"] = join(String.(e["references"]), ", ")
        end
    end

    return context
end

function generate_symbols_assets(; spec_path::String="spec/symbols.yaml",
    tex_out::String="reports/generated/sections/list_of_symbols.tex",
    md_out::String="docs/SYMBOLS.md")
    spec = _read_yaml(spec_path)
    _validate_spec(spec)

    mkpath(dirname(tex_out))
    mkpath(dirname(md_out))

    tex = _render_tex(spec; generated_path=spec_path)
    md = _render_markdown(spec; generated_path=spec_path)

    write(tex_out, tex)
    write(md_out, md)

    context = _build_context(spec)
    return context, tex_out, md_out
end

end # module SymbolSSOT

if abspath(PROGRAM_FILE) == @__FILE__
    context, tex_out, md_out = SymbolSSOT.generate_symbols_assets()
    println("Generated symbols artifacts:")
    println("  TeX: $(tex_out)")
    println("  MD:  $(md_out)")
    println("Loaded symbol context keys: $(length(context))")
end