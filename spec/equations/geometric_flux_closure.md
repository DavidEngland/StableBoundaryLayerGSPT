# Geometric Flux Closure

- Equation ID: `EQ-GFC-001`
- Purpose: translate the regularized GSPT geometry into algebraic flux closures suitable for NWP time steps
- Contract: diffusivities must remain strictly positive for any admissible state when `delta > 0`
- Smoothness: the solver-facing diagnostic manifold may use `eta > 0` to provide a `C^\infty` approximation of branch clipping

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
F_\delta = \sqrt{e + \delta}(\Delta - \alpha e) = 0,
$$

with production-stratification contrast

$$
\Delta = \sigma \left(\frac{U}{h}\right)^2 - K\Gamma.
$$

In piecewise form,

$$
e^* = \max\left(0, \frac{\Delta}{\alpha}\right).
$$

## Smooth Manifold Regularization

For implicit solvers and adjoint-based methods, the clipped branch is smoothed with `eta > 0`:

$$
e^*_{\eta} = \frac{1}{2\alpha}\left(\Delta + \sqrt{\Delta^2 + \eta^2}\right).
$$

For fixed `eta > 0` this map is `C^\infty`, and `e^*_\eta \to \max(0, \Delta/\alpha)` as `eta \to 0`.

## Combined Closure

Substitution into the diffusivity laws gives the solver-facing closure

$$
K_{m,h} = c_{m,h} l_0 \sqrt{e^*(S,\Gamma,\eta) + \delta}.
$$

Two regimes are encoded algebraically:

- transition-zone regime: `Delta > 0`, where diffusivities follow the turbulent branch and weaken continuously near the threshold
- background-mixing regime: `Delta \le 0`, where production is clipped and diffusivities collapse only to the `delta` floor rather than to zero

## Surface Coupling

The closure is coupled at the lower boundary through the surface energy budget because `K_h` depends on `Gamma`, and `Gamma` is slaved to the skin-temperature evolution. This nonlinear feedback permits brittle transitions, hysteresis, and fast jumps near the fold set when the solver crosses `\mathcal{C}_{\mathrm{fold}}`.