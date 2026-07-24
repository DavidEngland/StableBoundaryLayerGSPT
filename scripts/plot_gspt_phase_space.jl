using CairoMakie
using LaTeXStrings

# Enable LaTeX math font rendering globally
set_theme!(theme_latexfonts())

# Create figure and axis layout
fig = Figure(size = (800, 550), fontsize = 12)

ax = Axis(
    fig[2, 1],
    xlabel = L"Net Forcing $\Delta$",
    ylabel = L"Regularized TKE amplitude $q = \sqrt{e+\delta}$",
      limits = ((-3.5, 5.0), (-0.8, 4.5)),
    xgridstyle = :dash,
    ygridstyle = :dash,
    xgridcolor = (:gray, 0.4),
    ygridcolor = (:gray, 0.4)
)

# -----------------------------------------------------------------------------
# 1. Curve & Manifold Calculations
# -----------------------------------------------------------------------------
x_laminar  = range(-3.5, 5.0, length=500)
x_repeller = range(-1.5, 0.75, length=300)
x_attractor = range(-1.5, 4.5, length=400)

y_laminar   = zeros(length(x_laminar))
y_repeller  = @. 1.2 - 0.8 * sqrt(x_repeller + 1.5)
y_attractor = @. 1.2 + 0.8 * sqrt(x_attractor + 1.5)

# -----------------------------------------------------------------------------
# 2. Plotting Manifolds & Singularities
# -----------------------------------------------------------------------------
# Laminar manifold S_0^lam
l1 = lines!(ax, x_laminar, y_laminar, color = :forestgreen, linewidth = 2.2,
            label = L"Laminar manifold $S_0^{\mathrm{lam}}$")

# Repelling slow manifold S_0^-
l2 = lines!(ax, x_repeller, y_repeller, color = :crimson, linestyle = :dash, linewidth = 2.2,
            label = L"Repelling manifold $S_0^-$")

# Attracting turbulent manifold S_0^+
l3 = lines!(ax, x_attractor, y_attractor, color = :royalblue, linewidth = 2.2,
            label = L"Attracting manifold $S_0^+$")

# Fold Singularity neighborhood (shaded background circle)
cx, cy = -1.5, 1.2
r = 0.35
θ = range(0, 2π, length=100)
poly!(ax, Point2f.(cx .+ r .* cos.(θ), cy .+ r .* sin.(θ)),
      color = (:orange, 0.35), label = "Fold neighborhood")

# Fold Singularity point
p1 = scatter!(ax, [cx], [cy], color = :crimson, strokecolor = :black, strokewidth = 1.2, markersize = 10)

# Extinction threshold point
ext_x, ext_y = 0.75, 0.0
p2 = scatter!(ax, [ext_x], [ext_y], color = :black, markersize = 10, label = "Extinction threshold")

# -----------------------------------------------------------------------------
# 3. Fast Trajectories (Vertical Arrows)
# -----------------------------------------------------------------------------
# Downward fast trajectory (collapse) at x = -1.45
arrows!(ax, [-1.45], [1.1], [0.0], [-1.0], color = :gray40, linewidth = 1.8, arrowsize = 12)
text!(ax, -1.3, 0.6, text = "Collapse\n(Fast)", color = :gray30, fontsize = 10, align = (:left, :center))

# Upward fast trajectory (re-ignition) at x = 1.8
arrows!(ax, [1.8], [0.1], [0.0], [2.4], color = :gray40, linewidth = 1.8, arrowsize = 12)
text!(ax, 1.95, 1.3, text = "Re-ignition\n(Fast)", color = :gray30, fontsize = 10, align = (:left, :center))

# -----------------------------------------------------------------------------
# 4. Callout Annotations (Pointers placing labels in whitespace)
# -----------------------------------------------------------------------------
# Fold Singularity
lines!(ax, [cx, -2.5], [cy, 1.8], color = :gray60, linewidth = 1.0)
text!(ax, -2.5, 1.85, text = "Fold Singularity\n(-1.5, 1.2)", align = (:center, :bottom),
      color = :black)

# Attracting Turbulent Manifold S_0^+
y_att_target = 1.2 + 0.8 * sqrt(3.0 + 1.5)
lines!(ax, [3.0, 2.0], [y_att_target, 3.8], color = :gray60, linewidth = 1.0)
text!(ax, 2.0, 3.85, text = "Attracting Manifold S_0+", align = (:center, :bottom),
      color = :black)

# Repelling Slow Manifold S_0^-
y_rep_target = 1.2 - 0.8 * sqrt(-0.3 + 1.5)
lines!(ax, [-0.3, 0.1], [y_rep_target, 0.75], color = :gray60, linewidth = 1.0)
text!(ax, 0.1, 0.75, text = "Repelling Manifold S_0-", align = (:left, :bottom),
      color = :black)

# Laminar Manifold S_0^lam
lines!(ax, [-2.5, -3.1], [0.0, -0.52], color = :gray60, linewidth = 1.0)
text!(ax, -3.1, -0.54, text = "Laminar Manifold S_0^lam", align = (:center, :top),
      color = :black)

# Extinction Threshold
lines!(ax, [ext_x, 1.5], [ext_y, -0.52], color = :gray60, linewidth = 1.0)
text!(ax, 1.5, -0.54, text = "Extinction Threshold\n(0.75, 0)", align = (:center, :top),
      color = :black)

# -----------------------------------------------------------------------------
# 5. Dedicated "GSPT Regimes" Box (Top-Left Empty Quadrant)
# -----------------------------------------------------------------------------
regimes_text = "GSPT Regimes\n• Δ < -1.5: Subcritical (Laminar)\n• -1.5 < Δ < 0.75: Bistable\n• Δ > 0.75: Fully Turbulent"
text!(ax, -3.3, 4.3, text = regimes_text, fontsize = 10, align = (:left, :top),
      color = :black)

# -----------------------------------------------------------------------------
# 6. Legend Outside Axis Area (Top)
# -----------------------------------------------------------------------------
Legend(
    fig[1, 1],
    ax,
    orientation = :horizontal,
    nbanks = 1,
    tellwidth = false,
    tellheight = true,
    framecolor = "#cccccc"
)

# Export publication vector/raster outputs to build-ready figures path
out_dir = joinpath("reports", "generated", "figures")
mkpath(out_dir)
save(joinpath(out_dir, "gspt_phase_space.png"), fig, px_per_unit = 3)
save(joinpath(out_dir, "gspt_phase_space.pdf"), fig)

display(fig)