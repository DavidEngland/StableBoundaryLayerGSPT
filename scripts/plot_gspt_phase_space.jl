using CairoMakie
using LaTeXStrings

# Enable LaTeX math rendering globally
set_theme!(theme_latexfonts())

# Figure and Axis Setup
fig = Figure(size=(800, 560), fontsize=12)

ax = Axis(
      fig[2, 1],
      xlabel=L"Slow forcing parameter $\Delta$",
      ylabel=L"Fast variable $q = \sqrt{e+\delta}$",
      limits=((-3.5, 5.0), (-0.4, 4.5)),
      xgridstyle=:dash,
      ygridstyle=:dash,
      xgridcolor=(:gray, 0.4),
      ygridcolor=(:gray, 0.4)
)

# -----------------------------------------------------------------------------
# 1. Mathematically Continuous Folded Critical Manifold: \Delta(q) = -1.5 + ((q - 1.2)/0.8)^2
# -----------------------------------------------------------------------------
# Attracting branch S_0^+ (q >= 1.2)
q_att = range(1.2, 3.2, length=300)
Δ_att = @. -1.5 + ((q_att - 1.2) / 0.8)^2

# Repelling branch S_0^- (0 <= q < 1.2)
q_rep = range(0.0, 1.2, length=200)
Δ_rep = @. -1.5 + ((q_rep - 1.2) / 0.8)^2

# Laminar manifold S_0^lam
Δ_lam = range(-3.5, 5.0, length=500)
q_lam = zeros(length(Δ_lam))

# -----------------------------------------------------------------------------
# 2. Plot Slow Manifolds (Primary Level: Heavy LineWidth = 3.0 pt)
# -----------------------------------------------------------------------------
lines!(ax, Δ_lam, q_lam, color=:forestgreen, linewidth=3.0,
      label=L"Laminar manifold $S_0^{\mathrm{lam}}$")

lines!(ax, Δ_rep, q_rep, color=:crimson, linestyle=:dash, linewidth=3.0,
      label=L"Repelling manifold $S_0^-$")

lines!(ax, Δ_att, q_att, color=:royalblue, linewidth=3.0,
      label=L"Attracting manifold $S_0^+$")

# Singularities & Fold Neighborhood
cx, cy = -1.5, 1.2
θ = range(0, 2π, length=100)
poly!(ax, Point2f.(cx .+ 0.35 .* cos.(θ), cy .+ 0.35 .* sin.(θ)),
      color=(:orange, 0.35), label="Fold neighborhood")

scatter!(ax, [cx], [cy], color=:crimson, strokecolor=:black, strokewidth=1.2, markersize=10)

ext_x, ext_y = 0.75, 0.0
scatter!(ax, [ext_x], [ext_y], color=:black, markersize=10, label="Extinction threshold")

# -----------------------------------------------------------------------------
# 3. Fast Jump Trajectories (Secondary Level: Thin Lines = 1.5 pt)
# -----------------------------------------------------------------------------
arrows!(ax, [-1.45], [1.1], [0.0], [-1.0], color=:gray40, linewidth=1.5, arrowsize=10)
text!(ax, -1.3, 0.6, text="Collapse\n(Fast fiber)", color=:gray30, fontsize=10, align=(:left, :center))

arrows!(ax, [1.8], [0.1], [0.0], [2.4], color=:gray40, linewidth=1.5, arrowsize=10)
text!(ax, 1.95, 1.3, text="Re-ignition\n(Fast fiber)", color=:gray30, fontsize=10, align=(:left, :center))

# -----------------------------------------------------------------------------
# 4. Annotation Bézier Leaders & Labels (Tertiary Level: LineWidth = 0.9 pt)
# -----------------------------------------------------------------------------
# Helper function for quadratic Bézier curved connectors
function draw_curved_leader!(ax, p0, p_control, p2)
      t = range(0, 1, length=30)
      pts = Point2f[(1-ti)^2 .* Point2f(p0) .+ 2*(1-ti)*ti .* Point2f(p_control) .+ ti^2 .* Point2f(p2) for ti in t]
      lines!(ax, pts, color=:gray50, linewidth=0.9)
end

# Fold Singularity Callout
draw_curved_leader!(ax, (cx, cy), (-2.2, 1.3), (-2.5, 1.85))
text!(ax, -2.5, 1.85, text=L"\text{Fold Singularity}\n(-1.5, 1.2)", align=(:center, :bottom),
      bbox=(color=:white, strokecolor=:none))

# Attracting Manifold Callout
q_target_att = 2.8
Δ_target_att = -1.5 + ((q_target_att - 1.2)/0.8)^2
draw_curved_leader!(ax, (Δ_target_att, q_target_att), (2.2, 3.2), (2.0, 3.85))
text!(ax, 2.0, 3.85, text=L"\text{Attracting Manifold } S_0^+", align=(:center, :bottom),
      bbox=(color=:white, strokecolor=:none))

# Repelling Manifold Callout
q_target_rep = 0.5
Δ_target_rep = -1.5 + ((q_target_rep - 1.2)/0.8)^2
draw_curved_leader!(ax, (Δ_target_rep, q_target_rep), (-0.1, 0.4), (0.1, 0.75))
text!(ax, 0.1, 0.75, text=L"\text{Repelling Manifold } S_0^-", align=(:left, :bottom),
      bbox=(color=:white, strokecolor=:none))

# Laminar Manifold Callout
draw_curved_leader!(ax, (-2.8, 0.0), (-2.88, 0.22), (-2.8, 0.45))
text!(ax, -2.8, 0.45, text=L"\text{Laminar Manifold } S_0^{\mathrm{lam}}", align=(:center, :bottom),
      bbox=(color=:white, strokecolor=:none))

# Extinction Threshold Callout
draw_curved_leader!(ax, (ext_x, ext_y), (0.85, 0.3), (1.1, 0.5))
text!(ax, 1.1, 0.5, text=L"\text{Extinction Threshold}\n(0.75, 0)", align=(:left, :bottom),
      bbox=(color=:white, strokecolor=:none))

# -----------------------------------------------------------------------------
# 5. Dedicated "GSPT Regimes" Box
# -----------------------------------------------------------------------------
regimes_text = L"\mathbf{GSPT\ Regimes}\\[2pt]\bullet\ \Delta < -1.5\text{: Subcritical (Laminar)}\\[1pt]\bullet\ -1.5 < \Delta < 0.75\text{: Bistable}\\[1pt]\bullet\ \Delta > 0.75\text{: Fully Turbulent}"
text!(ax, -3.3, 4.3, text=regimes_text, fontsize=10, align=(:left, :top),
      bbox=(color="#f8f9fa", strokecolor="#cccccc", corner_radius=4))

# -----------------------------------------------------------------------------
# 6. Top External Legend
# -----------------------------------------------------------------------------
Legend(
      fig[1, 1],
      ax,
      orientation=:horizontal,
      nbanks=1,
      tellwidth=false,
      tellheight=true,
      framecolor="#cccccc"
)

# Export publication-ready vector and high-DPI raster outputs
out_dir = joinpath("reports", "generated", "figures")
mkpath(out_dir)
save(joinpath(out_dir, "gspt_phase_space.png"), fig, px_per_unit=3)
save(joinpath(out_dir, "gspt_phase_space.pdf"), fig)

display(fig)