# Diagnostic: Transcritical Exchange

- Diagnostic ID: `DIAG-TC-001`
- Source equation IDs: `EQ-FAST-001`, `EQ-TKE-REG-001`
- Transition surface:

$$
\Delta = \sigma S^2 - K\Gamma = 0
$$

- Local eigenvalue model:

$$
\lambda = -\sqrt{\alpha\Delta}
$$

- Early warning outputs: `slowing_down_index`, `variance_growth`, `autocorrelation_lag1`
- Physical note: transcritical approach alone does not imply hysteresis