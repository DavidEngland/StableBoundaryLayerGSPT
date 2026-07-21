# Path Forward for NWP Using Gradient Richardson Number or MOST \zeta = z/L

## Core point
Operational NWP should not rely on the raw ratio

$$Ri_g = \frac{N^2}{S^2}$$

or on an unbounded MOST stability coordinate

$$\zeta = \frac{z}{L}$$

as a hard branching variable in turbulence logic. Both can become numerically awkward in very stable, weak-shear, or near-neutral limits. The practical goal is not to abandon existing closures immediately, but to replace singular or truncated behavior with smooth, bounded, and solver-friendly formulations.

## Recommended path forward

### 1. Legacy compatibility layer: smooth saturation
For existing models that already expect a Richardson-like variable, use a smooth saturation operator instead of a hard cap.

$$Ri_{\mathrm{eff}} = R_s \tanh\!\left(\frac{Ri_g}{R_s}\right)$$

Here, $R_s$ is a numerical smoothing scale, not a physical critical Richardson number. This keeps the API nearly unchanged while removing the sharp kink introduced by `min(Ri, Ri_c)`.

### 2. Similarity layer: bounded coordinate
If the stability function itself can be rewritten, map the state to a compact coordinate.

$$\chi = \frac{S^2 + \delta}{S^2 + \lambda N^2 + \delta} = \frac{1}{1 + \lambda Ri_g} \quad (\delta \to 0)$$

This is the cleanest way to retain a MOST-like interpretation while avoiding division-by-zero behavior and keeping derivatives bounded.

For MOST surface-layer work, the same idea applies to $\zeta = z/L$: treat it as a smooth stability coordinate, not a quantity to be hard-clipped at extreme stable values.

### 3. Intrinsic physics layer: production-difference closure
If the model can tolerate a deeper change, replace ratio-based stability control with a production-minus-buoyancy balance.

$$\Delta = S^2 - \frac{N^2}{Pr_t}$$

A smooth positive-part approximation can then drive mixing without a non-differentiable `max`:

$$\Delta_* = \frac{1}{2}\left(\Delta + \sqrt{\Delta^2 + \xi^2}\right)$$

$$K_m = l_0^2 \sqrt{\Delta_* + \delta}$$

This is the strongest option physically, but it is also the most intrusive to existing code.

## What this means for NWP

- Do not use raw `Ri = N2 / S2` as an unguarded control variable in operational code.
- Do not treat `Ri_c = 0.25` as a universal physical ceiling; use it, if at all, only as a model-specific smoothing scale.
- Do prefer smooth saturation or bounded coordinates when the goal is to preserve current turbulence structure.
- Do prefer a production-difference closure if the scheme is being modernized rather than patched.

## Practical migration order

1. Add a smooth `Ri_eff` replacement for legacy code paths.
2. Rewrite stability lookup arguments in terms of a bounded coordinate such as `chi`.
3. If the scheme is being redesigned, move to a production-difference formulation with smooth regularization.

## Bottom line
For near-term NWP implementation, the best path is a two-track strategy:

- **short term:** smooth saturation or bounded coordinate for compatibility;
- **long term:** production-difference closure for a cleaner physical basis.

That gives operational model developers a low-friction upgrade path without forcing an immediate rewrite of the entire turbulence package.
