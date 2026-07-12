# Diagnostic: Critical Manifold

- Diagnostic ID: `DIAG-CM-001`
- Source equation IDs: `EQ-FAST-001`, `EQ-SLOW-001`
- Output fields: `z`, `manifold_value`
- Implementation contract: `Geometry.critical_manifold`

## Definition

From the fast subsystem singular limit, the critical manifold is defined implicitly by

$$
\mathcal{F}(e,U,V,T_s)=0.
$$

On the active turbulent branch,

$$
e^*(U,V,T_s) = l_0\left[\eta\,\gamma\,(U^2+V^2)-K\,G(T_s)\right]-\delta,
$$

with clipping to the laminar branch when the bracketed production-destruction balance is non-positive. Reduced slow flow is computed on this manifold in variables $(U,V,T_s)$.