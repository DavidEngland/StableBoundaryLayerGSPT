# Diagnostic: Transcritical Exchange

- Diagnostic ID: `DIAG-TC-001`
- Source equation IDs: `EQ-FAST-001`, `EQ-TKE-REG-001`
- Transition surface:

$$
\Delta = \eta\,\gamma\,(U^2+V^2) - K\,G(T_s) = 0
$$

- Local eigenvalue model:

$$
\lambda_f = \partial_e\mathcal{F}\big|_{\mathcal{M}_0}
$$

- Early warning outputs: `slowing_down_index`, `variance_growth`, `autocorrelation_lag1`
- Physical note: transcritical approach alone does not imply hysteresis