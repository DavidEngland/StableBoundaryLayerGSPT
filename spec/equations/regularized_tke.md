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

For solver-facing closures, the branch clip may be replaced by the smooth regularization

$$
e^*_{\eta} = \frac{1}{2\alpha}\left(\Delta + \sqrt{\Delta^2 + \eta^2}\right), \qquad \eta > 0,
$$

which is $C^\infty$ for fixed $\eta$ and converges to $\max(0, \Delta/\alpha)$ as $\eta \to 0$.