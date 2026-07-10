# Diagnostic: Fold Detection

- Diagnostic ID: `DIAG-FOLD-001`
- Required output fields: `fold_count`, `fold_locations`
- Validation target: deterministic fold count for fixed parameter set

## Fold Conditions

For reduced slow manifold relation $H(T_s, S)=0$, fold points satisfy:

$$
H = 0, \quad \frac{\partial H}{\partial T_s} = 0.
$$

Crossing a fold indicates branch loss of attraction and fast jump to laminar branch.