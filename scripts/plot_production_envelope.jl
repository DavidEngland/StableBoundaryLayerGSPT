# Target file: scripts/plot_production_envelope.jl
using DataFrames
using CSV
using Plots

# Use a clean, professional plotting environment (GR backend for crisp vector output)
gr()

function generate_publication_figure(csv_path::String, output_img_path::String)
    # 1. Load the production dataset
    df = CSV.read(csv_path, DataFrame)

    # Sort by Ug to ensure smooth line rendering
    sort!(df, :Ug)

    # Define journal-grade font configurations (Helvetica/Arial style)
    font_family = "Helvetica"
    title_font = font(12, font_family, :bold)
    label_font = font(10, font_family)
    tick_font  = font(9, font_family)

    # Create a 2-panel layout (1 row, 2 columns)
    p = plot(layout=(1, 2), size=(900, 400), dpi=300, margin=5Plots.mm)

    # -------------------------------------------------------------------------
    # PANEL A: Equilibrium TKE vs Geostrophic Wind
    # -------------------------------------------------------------------------
    plot!(p[1], df.Ug, df.e_eq,
        linecolor=:crimson,
        linewidth=2.5,
        label=false,
        xlabel="Geostrophic Wind Speed Ug (m/s)",
        ylabel="Equilibrium TKE e_eq (m²/s²)",
        title="Critical Manifold Topography",
        titlefont=title_font,
        guidefont=label_font,
        tickfont=tick_font,
        grid=:true,
        gridalpha=0.15,
        gridstyle=:dash
    )

    # Annotate the universal collapse regime
    annotate!(p[1], [(8.0, maximum(df.e_eq)*0.2, text("100% Collapse Region\n(Radiatively Dominated)", 9, :center, :darkgray, font_family))])

    # -------------------------------------------------------------------------
    # PANEL B: Fold Diagnostic vs Geostrophic Wind
    # -------------------------------------------------------------------------
    plot!(p[2], df.Ug, df.fold_diag,
        linecolor=:royalblue,
        linewidth=2.5,
        label=false,
        xlabel="Geostrophic Wind Speed Ug (m/s)",
        ylabel="Fold Diagnostic ∂g/∂e₁ (s⁻¹)",
        title="Normal Hyperbolicity Gradient",
        titlefont=title_font,
        guidefont=label_font,
        tickfont=tick_font,
        grid=:true,
        gridalpha=0.15,
        gridstyle=:dash
    )

    # Draw a reference line at 0 where the actual fold/bifurcation sits
    hline!(p[2], [0.0], linecolor=:black, linestyle=:dot, linewidth=1.2, label=false)

    # -------------------------------------------------------------------------
    # Save and Export Assets
    # -------------------------------------------------------------------------
    png(p, output_img_path)
    println("Publication figure successfully generated at: $output_img_path")
end

# Automatically target the production output directory provided by the JSON
prod_csv = "results/production_ug_envelope/ug_scan_20260718_111815/ug_scan_summary.csv"
output_png = "figures/5d_sbl_bifurcation_envelope.png"

generate_publication_figure(prod_csv, output_png)