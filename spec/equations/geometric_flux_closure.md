# Geometric Flux Closure

- Equation ID: `EQ-GFC-001`
- Purpose: translate the regularized GSPT geometry into algebraic flux closures suitable for NWP time steps
- Contract: diffusivities must remain strictly positive for any admissible state when `delta > 0`
- Smoothness: the solver-facing diagnostic manifold may use `\xi > 0` to provide a `C^\infty` approximation of branch clipping

## Regularized Eddy Diffusivities

Momentum and sensible heat diffusivities are closed directly with the regularized TKE coordinate:

$$
K_m = c_m l_0 \sqrt{e + \delta}, \qquad K_h = c_h l_0 \sqrt{e + \delta}.
$$

This yields a minimum background diffusivity floor

$$
K_{\min} = c l_0 \sqrt{\delta},
$$

which prevents complete turbulent decoupling when the system approaches the background-mixing branch.

## Diagnostic Manifold TKE

Setting the fast equation to zero gives the critical-manifold balance

$$
\mathcal{F}(e,U,V,T_s) = \sqrt{e+\delta}\left[\eta\,\gamma\,(U^2+V^2)-K\,G(T_s)\right] - \frac{(e+\delta)^{3/2}}{l_0}=0,
$$

with production-stratification contrast

$$
\Delta = \eta\,\gamma\,(U^2+V^2)-K\,G(T_s).
$$

For active turbulence, the equilibrium branch is

$$
e^* = l_0\,\Delta-\delta,
$$

and the laminar floor branch remains near $e\approx-\delta$ under regularized positivity.

## Smooth Manifold Regularization

For implicit solvers and adjoint-based methods, the branch clipping can be smoothed with a separate mollifier `\xi > 0`:

$$
e^*_{\xi} = \max\!\left(-\delta,\,\frac{1}{2}\left[e^*+\sqrt{(e^*)^2+\xi^2}\right]\right).
$$

For fixed `\xi > 0` this map is $C^\infty$ and preserves a strictly positive $(e+\delta)$ argument in flux laws. This smoothed branch is a diagnostic approximation for closure evaluation; it is not the exact equilibrium relation of the prognostic fast ODE.

## Combined Closure

Substitution into the diffusivity laws gives the solver-facing closure

$$
K_{m,h} = c_{m,h} l_0 \sqrt{e^*(U,V,T_s,\xi) + \delta}.
$$

Two regimes are encoded algebraically:

- transition-zone regime: $\Delta > 0$, where diffusivities follow the turbulent branch and weaken continuously near the threshold
- background-mixing regime: $\Delta \le 0$, where production is clipped and diffusivities collapse only to the $\delta$ floor rather than to zero

## Calibrated Baseline Constants

The documentation baseline matches `src/Dynamics/Dynamics.jl`:

| Parameter | Value |
| --- | --- |
| $\kappa$ | 0.4 |
| $z_{0m}$ | 0.05 |
| $z_{0h}$ | 0.01 |
| $l_0$ | 15.0 |
| $K$ | 0.32 |
| $\eta$ (`shear_production_efficiency`) | 15.0 |

## Surface Coupling

The closure is coupled at the lower boundary through the surface energy budget because $K_h$ depends on $G(T_s)$ through the fast-balance state. This nonlinear feedback permits brittle transitions, hysteresis, and fast jumps near the fold set when the solver crosses $\mathcal{C}_{\mathrm{fold}}$.