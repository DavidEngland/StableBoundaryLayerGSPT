# Coriolis-Coupled Vector Momentum Extension

- Equation ID: `EQ-COR-EXT-001`
- Status: calibrated production implementation aligned to `src/Dynamics/Dynamics.jl`
- Purpose: represent inertial turning, fold crossing, and discontinuous shear re-ignition in the 4D fast-slow SBL system

## Reduced State Variant

The production implementation uses a vector momentum state,

$$
x = (e, U, V, T_s) \in \mathbb{R}^4,
$$

where `e` remains fast and `(U,V,T_s)` remain slow.

## Coriolis-Coupled Slow Momentum

With geostrophic targets `(U_g,V_g)` and Coriolis parameter `f_c`, the slow momentum equations are

$$
\dot U = f_c(V - V_g) - \gamma \sqrt{e+\delta}\,U,
$$

$$
\dot V = -f_c(U - U_g) - \gamma \sqrt{e+\delta}\,V.
$$

This replaces the scalar forcing law with vector pressure-gradient/Coriolis balance while preserving turbulent drag through the regularized factor $\sqrt{e+\delta}$.

## Calibrated Fast Vector Field

The fast subsystem is written explicitly with $\mathcal{F}$ notation:

$$
\varepsilon \dot e = \mathcal{F}(e,U,V,T_s),
$$

$$
\mathcal{F}(e,U,V,T_s) = \sqrt{e+\delta}\left[\eta\,\gamma\,(U^2+V^2)-K\,G(T_s)\right] - \frac{(e+\delta)^{3/2}}{l_0}.
$$

The calibrated production gain is

$$
\eta = 15.0,
$$

matching `shear_production_efficiency` in `src/Dynamics/Dynamics.jl`.

## Dimensional Closure Coefficients

The drag and heat-exchange coefficients are

$$
\gamma = \gamma_{\mathrm{eff}}\,\frac{\kappa^2}{\log^2(h/z_{0m})}\,\frac{1}{h},
\qquad
C_H = \frac{\kappa^2}{\log(h/z_{0m})\log(h/z_{0h})},
$$

with the stability map

$$
G(T_s) = \exp\!\left(\beta\frac{T_a-T_s}{T_a}\right)-1.
$$

### Baseline Parameters (Calibrated Defaults)

| Parameter | Meaning | Baseline value |
| --- | --- | --- |
| $\kappa$ | von Karman constant | 0.4 |
| $z_{0m}$ | momentum roughness length | 0.05 |
| $z_{0h}$ | thermal roughness length | 0.01 |
| $l_0$ | dissipation length scale | 15.0 |
| $K$ | buoyancy-destruction gain | 0.32 |
| $\eta$ | shear production efficiency | 15.0 |

## Geometric Interpretation

After collapse, the ageostrophic wind no longer accelerates along a line; it rotates in the $(U,V)$ plane and wraps around the paraboloid-of-revolution projection of the folded critical manifold. Re-ignition occurs when this inertial return pushes the trajectory across $\mathcal{C}_{\mathrm{fold}}$, causing a fast sign inversion of $\mathcal{F}$ from negative to positive and a discontinuous jump from the laminar branch back to the turbulent manifold.

## Expected Diagnostics

- inertial hodograph rotation
- Blackadar-style overshoot relative to geostrophic balance
- branch-crossing times controlled by rotational return rather than scalar shear growth alone
- positive $\mathcal{F}$ episodes after collapse for high forcing ($U_g \ge 11$ in calibrated sweeps)

## Implementation Notes

- Julia reference implementation: `src/Dynamics/Dynamics.jl`
- Stiff solves: `Rodas5P` (default) and `Rosenbrock23` fallback
- compatibility requirement: preserve regularized positivity of $e+\delta$ and non-penetration at the laminar floor