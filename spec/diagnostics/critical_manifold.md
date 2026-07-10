# Diagnostic: Critical Manifold

- Diagnostic ID: `DIAG-CM-001`
- Source equation IDs: `EQ-FAST-001`, `EQ-SLOW-001`
- Output fields: `z`, `manifold_value`
- Implementation contract: `Geometry.critical_manifold`

## Definition

From the fast subsystem singular limit:

$$
e^*(S,\Gamma) = \max\left(0, \frac{\sigma S^2 - K\Gamma}{\alpha}\right)
$$

Reduced slow flow is computed on this manifold in variables $(S, T_s, \Gamma)$.