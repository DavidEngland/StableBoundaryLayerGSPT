```
# Mathematical Core: Regularized Energy Chart and Geometric Structure


```
```
This section presents the mathematical core of the paper using a regularized fast-manifold chart and a theorem sequence that formalizes the geometric interpretation.

## 1. Fast-Manifold Coordinate Chart

Define the positive turbulent-energy domain

$$
\mathcal{M}^+ = \{(e, q_\theta, S, T_s, T_g) \in \mathbb{R}^5 \mid e > 0\}.
$$

Introduce the chart map

$$
\phi : \mathcal{M}^+ \to \mathbb{R}_+ \times \mathbb{R}^4,
\quad
\phi(e, q_\theta, S, T_s, T_g) = (\tilde e, q_\theta, S, T_s, T_g),
\quad
\tilde e = \sqrt{e + \delta},\; \delta \ge 0.
$$

For any nonnegative regularization parameter $\delta$ (with $\delta = 0$ on $\mathcal{M}^+$), $\phi$ is smooth ($C^\infty$). Rescale time by

$$
d\tau = \frac{1}{\tilde e}\,dt,
$$

to obtain the desingularized fast subsystem

$$
\mathbf{G} = (\tilde F, \tilde H)^T,
$$

with

$$
\tilde F(\tilde e, q_\theta, \mathbf{y})
= \frac{1}{2}c_m\ell S^2\tilde e
- \frac{g}{2\theta_0}q_\theta
- \frac{\tilde e^3}{2\ell},
$$

$$
\tilde H(\tilde e, q_\theta, \mathbf{y})
= -c_w\theta_z\tilde e^3
- \frac{g}{\theta_0}c_\theta\ell q_\theta^2
- \frac{C_\theta}{\ell}\tilde e^2 q_\theta,
$$

where $\mathbf{y}=(S,T_s,T_g)\in\mathbb{R}^3$ and $\theta_z=\partial\theta/\partial z$.

Because $\tilde F$ and $\tilde H$ are low-degree polynomials in $(\tilde e,q_\theta)$ (with smooth dependence on $\mathbf y$), $\mathbf G$ is $C^\infty$ on the chart domain.

## 2. Core Theorem Sequence

### Theorem 1 (Existence and Smoothness of the Critical Manifold $\mathcal{S}_0$)

Let $\Omega\subset\mathbb{R}_+\times\mathbb{R}\times\mathbb{R}^3$ be open in coordinates $\mathbf{x}=(\tilde e,q_\theta,\mathbf y)$. Let

$$
\mathbf G(\mathbf x)=\big(\tilde F(\mathbf x),\tilde H(\mathbf x)\big)^T=\mathbf 0
$$

define the fast equilibria. If

$$
J_f(\mathbf x)
= \mathbf D_{(\tilde e,q_\theta)}\mathbf G(\mathbf x)
= \begin{pmatrix}
\partial\tilde F/\partial\tilde e & \partial\tilde F/\partial q_\theta \\
\partial\tilde H/\partial\tilde e & \partial\tilde H/\partial q_\theta
\end{pmatrix}
$$

has full rank $2$ at $\mathbf x_0=(\tilde e_0,q_{\theta,0},\mathbf y_0)$ (equivalently $\det J_f(\mathbf x_0)\neq0$), then there exists a neighborhood $U\subset\mathbb R^3$ of $\mathbf y_0$ and a unique $C^\infty$ map $\mathbf h:U\to\mathbb R^2$ such that

$$
\mathbf G\big(\mathbf h(\mathbf y),\mathbf y\big)=\mathbf 0,\quad \mathbf y\in U.
$$

Hence

$$
\mathcal S_0
= \{(\tilde e,q_\theta,\mathbf y)\in\Omega\mid (\tilde e,q_\theta)=\mathbf h(\mathbf y)\}
$$

is a smooth embedded $3$-manifold in $\mathbb R^5$.

Proof sketch. Apply the Implicit Function Theorem to $\mathbf G(\tilde e,q_\theta,\mathbf y)=0$ at points where $\det J_f\neq0$. Since $\mathbf G$ is smooth, the local graph map $\mathbf h$ is smooth. Patching compatible local graphs yields the manifold structure on $\mathcal S_0$. $\blacksquare$

### Theorem 2 (Fold Characterization)

Define

$$
\mathcal C_{\mathrm{fold}}
= \{\mathbf x\in\mathcal S_0\mid \det J_f(\mathbf x)=0\}.
$$

Assume

$$
\nabla_{\mathcal S_0}(\det J_f)\neq \mathbf 0
\quad\text{on}\quad
\mathcal C_{\mathrm{fold}}.
$$

Then $\mathcal C_{\mathrm{fold}}$ is a smooth embedded codimension-one submanifold of $\mathcal S_0$; therefore $\dim\mathcal C_{\mathrm{fold}}=2$.

Proof sketch. Let $D(\mathbf x)=\det J_f(\mathbf x)$. Restrict to $D|_{\mathcal S_0}$. The nonvanishing tangential gradient makes $0$ a regular value of $D|_{\mathcal S_0}$, so by the Regular Value Theorem, $D^{-1}(0)\cap\mathcal S_0$ is a smooth codimension-one submanifold of $\mathcal S_0$. $\blacksquare$

### Theorem 3 (Projection Theorem)

Let $\mathcal S_0\subset\mathbb R^5$ be a $3$-manifold with fold set $\mathcal C_{\mathrm{fold}}$, and let $P:\mathbb R^5\to\mathbb R^k$ ($k\le4$) be smooth. Suppose

$$
\operatorname{rank}\left(DP_p\big|_{T_p\mathcal C_{\mathrm{fold}}}\right)=r
$$

is constant for all $p\in\mathcal C_{\mathrm{fold}}$.

Then:

1. $P(\mathcal C_{\mathrm{fold}})$ is locally an immersed $r$-dimensional submanifold of $\mathbb R^k$ (embedded where injectivity conditions hold).
2. Observed thresholds $R_c=P(p)$ are projection-dependent images of the same invariant set $\mathcal C_{\mathrm{fold}}$.

Proof sketch. The restriction $P|_{\mathcal C_{\mathrm{fold}}}$ is smooth between manifolds. The Constant Rank Theorem gives local normal forms and the claimed dimensionality of the image. $\blacksquare$

### Corollary (Richardson-Threshold Variability as Projection Effect)

Reported values of $Ri_{\mathrm{crit}}$ across campaigns are not distinct universal constants. They are campaign-specific scalar projections of intersections with site constraints:

$$
\pi_{Ri}(\tilde e,q_\theta,S,T_s,T_g)=\frac{g}{\theta_0}\frac{\theta_z}{S^2},
$$

$$
Ri_{\mathrm{crit}}\in \pi_{Ri}\big(\mathcal C_{\mathrm{fold}}\cap\Sigma_{\mathrm{site}}\big),
$$

$$
\Sigma_{\mathrm{site}}=\{\mathbf x\in\mathbb R^5\mid \Pi_G(\mathbf x)=\Pi_{G,\mathrm{site}}\}.
$$

Physical consequence. The geometric fold set $\mathcal C_{\mathrm{fold}}$ is universal for the model class; campaigns sample different constrained slices.

## 3. WSINDy Identifiability Workflow Linked to Theory

Because $\mathbf G(\tilde e,q_\theta,\mathbf y)$ is polynomial in fast variables (and smooth in slow variables), the inference pipeline aligns directly with the theorem objects.

1. Polynomial basis extraction (WSINDy)
   - Identify $\widehat{\mathcal F}(\tilde e,q_\theta,\mathbf y)$ and $\widehat{\mathcal H}(\tilde e,q_\theta,\mathbf y)$ from a candidate library $\Theta(\tilde e,q_\theta,\mathbf y)$.
   - Check recovered coefficients against closure constants $(c_m,c_w,c_\theta,C_\theta)$.
2. Determinant level set
   - Compute $\det(\widehat J_f)=\widehat{\mathcal F}_{\tilde e}\widehat{\mathcal H}_{q_\theta}-\widehat{\mathcal F}_{q_\theta}\widehat{\mathcal H}_{\tilde e}$.
   - Extract the zero set to reconstruct $\widehat{\mathcal C}_{\mathrm{fold}}\subset\mathbb R^5$.
3. Bootstrap and perturbation bounds
   - Add noise $\sigma\sim15\%$-$20\%$.
   - Quantify reconstruction error via Hausdorff distance $d_H(\mathcal C_{\mathrm{fold}},\widehat{\mathcal C}_{\mathrm{fold}})<\varepsilon$.
4. Projection verification
   - Apply $\pi_{Ri}$ to slices of $\widehat{\mathcal C}_{\mathrm{fold}}$ at representative $\Pi_G$ values (for example SHEBA-like and CASES-99-like regimes).
   - Compare projected thresholds against observed $Ri$ ranges.

This closes the loop between geometry and inference: the chart enables polynomial identifiability, and the identified model reconstructs the fold geometry behind observed stability thresholds.

## Summary

The section now establishes a clean geometric narrative:

1. A smooth regularized chart desingularizes the fast subsystem.
2. The critical manifold and fold set follow from standard smooth-manifold theorems.
3. Apparent threshold variability in observations is interpreted as projection geometry, not contradictory physics.
4. WSINDy is positioned as a direct estimator of the same invariant objects proven theoretically.

## Critique

1. Theorems are mathematically coherent, but assumptions need explicit model-domain qualifiers.
   - Clarify where $\tilde e>0$ must hold after regularization and what happens near $\tilde e=0$ in data.
2. The projection theorem should avoid implying global invertibility between projected thresholds.
   - The revised text keeps claims local unless extra hypotheses are added.
3. Corollary is compelling but still interpretive unless supported by explicit campaign-conditioned computations.
   - Add one concrete computational example per campaign class.
4. The WSINDy pipeline is clear conceptually, but identifiability and uncertainty criteria should be formalized.
   - Define sampling, noise model, regularization, and confidence intervals for fold reconstruction.

## Next Steps

1. Add an assumptions table listing smoothness, domain, rank, and transversality conditions with physical interpretation.
2. Add one worked symbolic example of $J_f$, $\det J_f$, and fold extraction in a reduced parameter slice.
3. Add a short numerical validation subsection showing campaign-style slices and projected $Ri$ ranges.
4. Add an uncertainty subsection defining bootstrap protocol, metrics, and acceptance thresholds.


```
