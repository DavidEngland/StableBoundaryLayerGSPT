# Coriolis-Coupled Vector Momentum Extension

- Equation ID: `EQ-COR-EXT-001`
- Status: planned v0.2+ theory extension built on the v0.1 reference geometry
- Purpose: replace scalar slow-shear forcing with a two-component horizontal momentum subsystem that can capture inertial turning and hodograph overshoot

## Reduced State Variant

One reduced future variant replaces the scalar-shear slow subsystem with a vector momentum state,

$$
x = (e, U, V, T_s) \in \mathbb{R}^4,
$$

where `e` remains fast and `(U,V,T_s)` remain slow.

## Coriolis-Coupled Slow Momentum

With geostrophic targets `(U_g,V_g)` and Coriolis parameter `f`, the slow momentum equations become

$$
\dot U = f(V - V_g) - \gamma \sqrt{e+\delta}\,U,
$$

$$
\dot V = -f(U - U_g) - \gamma \sqrt{e+\delta}\,V.
$$

This replaces the scalar forcing law with a vector pressure-gradient/Coriolis balance while preserving turbulent drag through the same regularized factor `\sqrt{e+\delta}`.

## Production Proxy

The scalar production-stratification contrast is promoted to a vector-speed form,

$$
\Delta = \sigma \left(\frac{\sqrt{U^2+V^2}}{h}\right)^2 - K G(T_s),
$$

or, more generally, a vector-shear norm may be substituted when vertical structure is retained explicitly.

## Geometric Interpretation

The fast equation remains unchanged in structure, so the same critical-manifold and smoothing machinery apply. The qualitative difference is in the slow return path: after collapse, the ageostrophic wind no longer accelerates along a line but rotates in the `(U,V)` plane. Re-ignition occurs when the rotating wind state drives `\Delta` back through the transcritical threshold.

## Expected Diagnostics

- inertial hodograph rotation
- Blackadar-style overshoot relative to geostrophic balance
- branch-crossing times controlled by rotational return rather than scalar shear growth alone

## Implementation Notes

- recommended symbolic backend: `ModelingToolkit.jl` for automatic Jacobians and stiff solves
- Python/SciPy prototype path: extend `solve_ivp` state vector and momentum RHS accordingly
- compatibility requirement: preserve the same regularized flux closure and `e^*_{\eta}` machinery used by the v0.1 reference theory