using JSON

function load_figure_config(config_path::String=joinpath("config", "manuscript_figures.json"))
    if !isfile(config_path)
        @warn "Figure configuration file not found at $(config_path). Using empty default metadata."
        return Dict{String, Any}("figures" => Dict(), "preferred_stems" => String[], "acronyms" => Dict())
    end
    return JSON.parsefile(config_path)
end

function build_tex_figure_includes(fig_dir::String;
                                   tex_output_dir::String=joinpath("reports", "generated"),
                                   config_path::String=joinpath("config", "manuscript_figures.json"))
    if !isdir(fig_dir)
        return "% No generated figures directory found."
    end

    # Load external JSON configuration
    cfg = load_figure_config(config_path)
    fig_metadata = get(cfg, "figures", Dict{String, Any}())
    preferred_stems = Vector{String}(get(cfg, "preferred_stems", String[]))
    acronyms = get(cfg, "acronyms", Dict{String, Any}())

    function prettify_figure_title(stem::String)
        parts = split(replace(stem, "-" => "_"), "_")
        normalized = String[]
        for part in parts
            lw = lowercase(part)
            if haskey(acronyms, lw)
                push!(normalized, acronyms[lw])
            else
                push!(normalized, uppercasefirst(lw))
            end
        end
        return join(normalized, " ")
    end

    function figure_caption_and_label(stem::String)
        if haskey(fig_metadata, stem)
            meta = fig_metadata[stem]
            title = get(meta, "title", prettify_figure_title(stem))
            label = get(meta, "label", "")
            return title, label
        end
        return prettify_figure_title(stem), ""
    end

    function make_figure_block(path::String, caption::String, label::String)
        rel_path = relpath(path, tex_output_dir)
        label_line = isempty(label) ? "" : "\n\\label{$(label)}"
        return "\\begin{figure}[ht!]\n\\centering\n\\includegraphics[width=0.95\\linewidth]{$(rel_path)}\n\\caption{$(caption)}$(label_line)\n\\end{figure}"
    end

    tex_files = sort(filter(name -> startswith(name, "figure_bifurcation_") && endswith(name, ".tex"), readdir(fig_dir)))
    handled_stems = Set{String}()
    candidate_paths = Dict{String,String}()

    for file in tex_files
        stem = replace(file, ".tex" => "")
        push!(handled_stems, stem)
        pdf_path = joinpath(fig_dir, "$(stem).pdf")
        if isfile(pdf_path)
            candidate_paths[stem] = pdf_path
        end
    end

    image_files = sort(filter(name -> (
            (endswith(name, ".png") || endswith(name, ".jpg") || endswith(name, ".jpeg") || endswith(name, ".pdf"))
        ), readdir(fig_dir)))

    for file in image_files
        stem = replace(file, r"\.[^.]+$" => "")
        if stem in handled_stems
            continue
        end
        candidate_paths[stem] = joinpath(fig_dir, file)
    end

    ordered_stems = String[]
    for stem in preferred_stems
        if haskey(candidate_paths, stem)
            push!(ordered_stems, stem)
        end
    end
    for stem in sort(collect(keys(candidate_paths)))
        if !(stem in ordered_stems)
            push!(ordered_stems, stem)
        end
    end

    blocks = String[]
    for stem in ordered_stems
        title, label = figure_caption_and_label(stem)
        push!(blocks, make_figure_block(candidate_paths[stem], title, label))
    end

    if isempty(blocks)
        return "% No generated figure assets found."
    end

    return join(blocks, "\n\n")
end