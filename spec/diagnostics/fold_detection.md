# Diagnostic: Fold Detection

- Diagnostic ID: `DIAG-FOLD-001`
- Required output fields: `fold_count`, `fold_locations`
- Validation target: deterministic fold count for fixed parameter set

## Fold Conditions

For the 4D fast-slow system, the fold set is defined geometrically by the fast subsystem:

$$
\mathcal{F}(e,U,V,T_s)=0, \qquad \partial_e\mathcal{F}(e,U,V,T_s)=0.
$$

The surface energy budget does not define the fold directly; it supplies the slow parameter dependence that can drive trajectories into this non-hyperbolic set. Crossing a fold indicates loss of normal hyperbolicity and fast departure from the attracting branch.