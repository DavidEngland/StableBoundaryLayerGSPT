using CairoMakie
using LaTeXStrings

# Configure global theme for publication standards
set_theme!(
    Theme(
        font = "DejaVu Sans",
        fontsize = 11,
        Axis = (
            xlabelsize = 11, ylabelsize = 11,
            titlesize = 12, titlealign = :left, titlefont = :bold,
            spinewidth = 0.8, xgridstyle = :dot, ygridstyle = :dot
        ),
        Axis3 = (
            xlabelsize = 10, ylabelsize = 10, zlabelsize = 10,
            titlesize = 12, titlealign = :left, titlefont = :bold
        )
    )
)

fig = Figure(size = (950, 780))

# ==========================================
# PANEL A: Full Phase Space Geometry (3D)
# ==========================================
ax_a = Axis3(fig[1, 1],
    xlabel = L"Slow Var 1: $\Delta\theta$",
    ylabel = L"Slow Var 2: $G_0$",
    zlabel = L"Fast Var: TKE ($e$)",
    title = L"(a) Full Phase Space Geometry ($\mathcal{M}_0$)",
    elevation = 0.35, azimuth = -1.1
)

# Mesh definitions for M_0 manifold
dtheta = range(0, 5, length=40)
g0 = range(0, 5, length=40)
E = [max(0.0, 4.0 - 0.5 * dt^1.3 - 0.3 * g) for dt in dtheta, g in g0]

# Render translucent blue critical manifold surface & wireframe
surface!(ax_a, dtheta, g0, E, color = :royalblue, alpha = 0.45)
wireframe!(ax_a, dtheta, g0, E, color = (:navy, 0.2), linewidth = 0.5)

# Ground boundary plane (e = 0)
E_ground = zeros(length(dtheta), length(g0))
surface!(ax_a, dtheta, g0, E_ground, color = :gray, alpha = 0.15)

# Fold Locus C_fold (red curve)
g0_fold = range(0.5, 4.5, length=50)
dt_fold = [(2.2 - 0.15 * g)^(1/1.1) for g in g0_fold]
e_fold = [max(0.0, 4.0 - 0.5 * dt^1.3 - 0.3 * g) for (dt, g) in zip(dt_fold, g0_fold)]
lines!(ax_a, dt_fold, g0_fold, e_fold, color = :crimson, linewidth = 3, label = L"\mathcal{C}_{\text{fold}}")

# System trajectory with post-fold detachment spiral
t_traj = range(0, 1, length=100)
dt_traj = @. 0.5 + 2.8 * t_traj
g0_traj = @. 1.0 + 2.5 * t_traj
e_traj = [max(0.0, 4.0 - 0.5 * dt^1.3 - 0.3 * g) for (dt, g) in zip(dt_traj, g0_traj)]
detach_idx = 60
for i in detach_idx:length(t_traj)
    e_traj[i] *= exp(-3.0 * (t_traj[i] - t_traj[detach_idx]))
end
lines!(ax_a, dt_traj, g0_traj, e_traj, color = :black, linewidth = 2)

# Fast attraction downward arrows
arrows!(ax_a,
    [1.5, 2.5], [2.0, 1.0], [4.5, 4.5],         # Origins (x, y, z)
    [0.0, 0.0], [0.0, 0.0], [-2.0, -2.5],       # Vectors (u, v, w)
    color = :darkblue, arrowsize = 0.12
)

# ==========================================
# PANEL B: 2D Projected Illusion
# ==========================================
ax_b = Axis(fig[1, 2],
    xlabel = L"Stability Parameter ($\mathrm{Ri}$ or $\Delta\theta$)",
    ylabel = L"TKE ($e$)",
    title = L"(b) 2D Projected Illusion"
)
limits!(ax_b, 0, 1.0, -0.2, 4.0)

ri = range(0, 0.8, length=150)
e_proj_upper = [3.5 * sqrt(max(0.0, 1.0 - 1.2 * r)) for r in ri]
lines!(ax_b, ri, e_proj_upper, color = :royalblue, linewidth = 2, label = L"Stable branch ($\mathcal{M}_0$)")

# Projected fold artifact nose
ri_fold = range(0.65, 0.83, length=50)
e_fold_nose = [1.8 - 8.0 * (r - 0.83)^2 for r in ri_fold]
lines!(ax_b, ri_fold, e_fold_nose, color = :orange, linestyle = :dash, linewidth = 2, label = L"Apparent 2D fold")

# Physical boundary line and transversal termination
hlines!(ax_b, [0.0], color = :gray, linewidth = 1.2)
scatter!(ax_b, [0.83], [0.0], marker = :rect, color = :black, markersize = 8, label = L"Transversal termination")

# Callout annotation box
text!(ax_b, 0.32, 2.3,
    text = "Apparent interior fold:\nProjection artifact of det DG_slow = 0",
    fontsize = 9
)
axislegend(ax_b, position = :rt, framevisible = true)

# ==========================================
# PANEL C: Spectral Diagnostic Signatures
# ==========================================
# Left Y-Axis: Fast Eigenvalue
ax_c1 = Axis(fig[2, 1:2],
    xlabel = L"Time $t$ (leading to boundary layer transition)",
    ylabel = L"Fast Eigenvalue $\lambda_f$",
    title = L"(c) Spectral Diagnostic Signatures",
    yticklabelcolor = :darkblue, ylabelcolor = :darkblue
)
# Right Y-Axis: Slow Jacobian Determinant (Overlay)
ax_c2 = Axis(fig[2, 1:2],
    ylabel = L"Slow Jacobian $\det DG_{\text{slow}}$",
    yaxisposition = :right,
    yticklabelcolor = :crimson, ylabelcolor = :crimson
)
hidespines!(ax_c2)
hidexdecorations!(ax_c2)

t_diag = range(0, 10, length=200)
lambda_f = @. -2.5 - 0.2 * sin(t_diag)
det_G = @. 1.5 - 0.2 * t_diag

# Fast eigenvalue plot
lines!(ax_c1, t_diag, lambda_f, color = :darkblue, linewidth = 2)
hlines!(ax_c1, [0.0], color = :gray, linestyle = :dot)
ylims!(ax_c1, -4.0, 0.5)

# Slow determinant plot
lines!(ax_c2, t_diag, det_G, color = :crimson, linewidth = 2)
hlines!(ax_c2, [0.0], color = :crimson, linestyle = :dash)

# Collapse event marker
vlines!(ax_c1, [7.5], color = :black, linestyle = :dash, linewidth = 1.2)
text!(ax_c1, 7.6, -0.8, text = L"\text{Collapse Point }(\det DG_{\text{slow}} = 0)", fontsize = 9, font = :bold)

# Save high-resolution outputs for manuscript submission
mkpath("reports/generated/figures")
save("reports/generated/figures/figure_fold_illusion.pdf", fig) # Vector PDF for manuscript submission
save("reports/generated/figures/figure_fold_illusion.png", fig, px_per_unit = 2) # High-res raster preview