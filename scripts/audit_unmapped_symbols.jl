#!/usr/bin/env julia
# scripts/audit_unmapped_symbols.jl
# This script scans TeX mustache templates for math tokens and reports those
# that are not mapped in the canonical symbols specification `spec/symbols.yaml`.
using YAML

# 1. Load canonical TeX symbols from SSOT.
symbols_spec = YAML.load_file("spec/symbols.yaml")
known_tex = Set(String[s["symbol_tex"] for s in symbols_spec["symbols"]])

# 2. Gather templates and initialize report container.
template_dir = "templates/sections"
template_files = sort([
    joinpath(template_dir, name)
    for name in readdir(template_dir)
    if endswith(name, ".mustache")
])
unmapped = Dict{String, Vector{String}}()

# Minimal ignore lists to suppress common non-symbol noise from math mode.
ignore_tokens = Set([
    "i", "j", "k", "m", "n",
    "s^{-1}", "s^{-2}", "m^2", "m^{-1}", "m^{-2}", "K^{-1}",
])

ignore_macros = Set([
    "\\begin", "\\end", "\\left", "\\right", "\\text", "\\textbf", "\\textit",
    "\\label", "\\ref", "\\eqref", "\\cite", "\\citep", "\\citet",
    "\\frac", "\\sqrt", "\\partial", "\\operatorname", "\\mathbf",
    "\\min", "\\max", "\\inf", "\\sup", "\\lim", "\\int", "\\sum", "\\prod",
    "\\to", "\\sim", "\\approx", "\\le", "\\ge", "\\neq", "\\mid", "\\middle",
    "\\dot", "\\cdot", "\\dots", "\\boxed", "\\downarrow", "\\uparrow", "\\coloneqq",
    "\\equiv", "\\implies", "\\in", "\\gg", "\\ll", "\\longrightarrow", "\\propto", "\\prec", "\\subset", "\\times",
    "\\tanh", "\\ln",
    "\\qquad", "\\quad",
])

function strip_comments(text::String)
    # Remove LaTeX comments while preserving escaped \%.
    return replace(text, r"(?m)(?<!\\)%.*$" => "")
end

function extract_math_segments(text::String)
    cleaned = strip_comments(text)
    segments = String[]

    # Inline and display math delimiters.
    for pat in (
        r"(?s)\$\$(.+?)\$\$",
        r"(?s)(?<!\$)\$(?!\$)(.+?)(?<!\$)\$(?!\$)",
        r"(?s)\\\((.+?)\\\)",
        r"(?s)\\\[(.+?)\\\]",
    )
        for m in eachmatch(pat, cleaned)
            push!(segments, m.captures[1])
        end
    end

    # Common math environments.
    envs = [
        "equation", "equation*", "align", "align*", "gather", "gather*",
        "multline", "multline*", "aligned", "split",
    ]
    for env in envs
        pat = Regex("(?s)\\\\begin\\{" * env * "\\}(.+?)\\\\end\\{" * env * "\\}")
        for m in eachmatch(pat, cleaned)
            push!(segments, m.captures[1])
        end
    end

    return segments
end

function normalize_token(token::AbstractString)
    t = strip(token)
    t = replace(t, r"\s+" => "")
    return t
end

function strip_trailing_power(token::String)
    t = token
    while true
        m = match(r"\^(?:\{[^{}]+\}|[A-Za-z0-9*+-]+)$", t)
        m === nothing && break
        t = t[1:prevind(t, first(m.offset))]
    end
    return t
end

function should_ignore(token::String)
    occursin(r"^[A-Za-z]$", token) && !(token in known_tex) && return true
    startswith(token, "\\SBL") && return true
    occursin(r"^[A-Za-z]_(?:\d+|N)$", token) && return true
    occursin(r"^\\[A-Za-z]+_(?:\d+|N)$", token) && return true
    token in ignore_tokens && return true
    token in ignore_macros && return true

    macro_root = match(r"^\\[A-Za-z]+", token)
    if macro_root !== nothing && macro_root.match in ignore_macros
        return true
    end

    startswith(token, "\\text{") && return true
    startswith(token, "\\label{") && return true
    startswith(token, "\\ref{") && return true
    startswith(token, "\\eqref{") && return true
    startswith(token, "\\cite") && return true
    occursin(r"^\\mathbb\{R\}$", token) && return true
    occursin(r"^\\mathcal\{[OFH]\}$", token) && return true
    occursin(r"^C\^(?:0|1|\{\\infty\})$", token) && return true
    token in Set(["\\mathrm{m}", "\\mathrm{s}", "\\mathrm{K}", "\\mathrm{J}", "\\mathrm{W}", "\\mathrm{SB}"]) && return true
    return false
end

# 3. Extract math tokens from math content only.
math_regex = r"""
\\[A-Za-z]+(?:\{[^{}]+\})?(?:_(?:\{[^{}]+\}|[A-Za-z0-9]+))?(?:\^(?:\{[^{}]+\}|[A-Za-z0-9*]+))?
|
[A-Za-z](?:_(?:\{[^{}]+\}|[A-Za-z0-9]+))?(?:\^(?:\{[^{}]+\}|[A-Za-z0-9*]+))?
"""x

for file in template_files
    content = read(file, String)
    segments = extract_math_segments(content)

    for seg in segments
        for m in eachmatch(math_regex, seg)
            token = normalize_token(m.match)
            isempty(token) && continue
            base_token = strip_trailing_power(token)

            if should_ignore(token) || should_ignore(base_token)
                continue
            end

            if (token in known_tex) || (base_token in known_tex)
                continue
            end

            candidate = base_token
            if !(candidate in known_tex)
                files = get!(unmapped, candidate, String[])
                short = basename(file)
                if !(short in files)
                    push!(files, short)
                end
            end
        end
    end
end

println("--- Unmapped Math Candidates ---")
if isempty(unmapped)
    println("  none")
else
    for k in sort(collect(keys(unmapped)))
        println("  ", k, " => ", sort(unmapped[k]))
    end
end