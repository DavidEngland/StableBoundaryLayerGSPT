# Canonical Synthetic Benchmarks

This suite defines canonical synthetic reference-theory cases for v0.1.

Each benchmark case should define:

- parameter set
- expected qualitative behavior
- expected diagnostics
- tolerances
- reference figures (optional)
- provenance metadata

## Families

- equilibrium
- transcritical
- fold
- hysteresis
- relaxation
- oscillation
- inertial

These benchmarks are used for L2 validation and regression hardening.

## Inertial Benchmark Design

The inertial family is reserved for future Coriolis-coupled vector-momentum extensions of the reference theory. The first case should remain analytically simple enough to admit a near-closed-form hodograph target before adding surface-energy coupling or turbulent re-ignition.
