# Regularized TKE

- Equation ID: `EQ-TKE-REG-001`
- Constraint: TKE must remain non-negative
- Validation: negative TKE is a hard failure
- Contract: Validation gate must enforce this condition

## Singular Limit and Critical Manifold Seed

Setting $\varepsilon = 0$ gives

$$
\mathcal{F}(e,U,V,T_s)=\sqrt{e + \delta}\left[\eta\,\gamma\,(U^2+V^2)-K\,G(T_s)\right]-\frac{(e+\delta)^{3/2}}{l_0}=0.
$$

Because $\delta > 0$, $\sqrt{e+\delta}$ does not vanish, so

$$
e^* = l_0\Delta-\delta \quad \text{for} \quad \Delta > 0,
$$

and in the singular limit the system is clamped to the laminar branch when $\Delta \le 0$.

For solver-facing closures, the branch clip may be replaced by the smooth diagnostic regularization

$$
e^*_{\xi} = \frac{1}{2}\left(e^* + \sqrt{(e^*)^2+\xi^2}\right), \qquad \xi > 0,
$$

which is $C^\infty$ for fixed $\xi$ and converges to the clipped branch as $\xi \to 0$. This expression is diagnostic only; the prognostic model evolves the full fast equation.