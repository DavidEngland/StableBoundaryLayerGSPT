# Regularized TKE

- Equation ID: `EQ-TKE-REG-001`
- Constraint: TKE must remain non-negative
- Validation: negative TKE is a hard failure
- Contract: Validation gate must enforce this condition

## Singular Limit and Critical Manifold Seed

Setting $\varepsilon = 0$ gives

$$
\sqrt{e + \delta}(\Delta - \alpha e) = 0.
$$

Because $\delta > 0$, $\sqrt{e+\delta}$ does not vanish, so

$$
e^* = \frac{\Delta}{\alpha} \quad \text{for} \quad \Delta > 0,
$$

and in the singular limit we clamp to laminar branch $e^* = 0$ when $\Delta \le 0$.