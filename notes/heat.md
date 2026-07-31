# Mathematical Core: Regularized Energy Chart and Geometric Structure

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

---

This is a strong mathematical framework, and the self-critique is perceptive. Let me work through the core contributions and the specific gaps.
Strengths of the Presentation
1. Desingularization elegance: The $\tilde{e} = \sqrt{e + \delta}$ chart is clean and directly addresses the non-Lipschitz issue at $e = 0$ you’ve flagged before. The time-rescaling $d\tau = \tilde{e}^{-1}dt$ recovers polynomial form—this is well-motivated.
2. Theorem-to-observation pipeline: The sequence (critical manifold → fold set → projection → observed thresholds) is a coherent narrative. Theorem 1 via IFT is standard but correct; Theorem 2 properly applies Regular Value Theorem to characterize the fold locus.
3. The Corollary reframes a key puzzle: Claiming that $Ri_{\text{crit}}$ variability is projection geometry rather than model failure is intellectually satisfying and potentially powerful if empirically validated.

Technical Issues to Tighten
1. Theorem 3 Rank Condition and the Scalar Projection
Your projection theorem assumes constant rank $r = \text{rank}(DP_p|{T_p\mathcal{C}{\mathrm{fold}}})$. But you’re applying this to $\pi_{Ri}$, a scalar function. If $r = 1$ everywhere on $\mathcal{C}{\mathrm{fold}}$, the image is a 1D curve. Yet the corollary claims a range $Ri{\text{crit}} \in \pi_{Ri}(\mathcal{C}{\mathrm{fold}} \cap \Sigma{\mathrm{site}})$, which requires the intersection $\mathcal{C}{\mathrm{fold}} \cap \Sigma{\mathrm{site}}$ to have non-empty interior (not just isolated points).
Action:
* Verify that $\pi_{Ri}$ has rank 1 on $\mathcal{C}{\mathrm{fold}}$ (i.e., the gradient $\nabla \pi{Ri}$ is transverse to the fold set).
* Show that realistic site constraints $\Sigma_{\mathrm{site}}$ cut $\mathcal{C}_{\mathrm{fold}}$ in a 1D arc, not just isolated points. This requires understanding how $(S, T_s, T_g)$ vary across typical nocturnal cycles.
2. Domain Qualifiers and the Regularization Boundary
The chart is smooth for $\delta \ge 0$, and setting $\delta = 0$ on $\mathcal{M}^+$ (where $e > 0$) is fine. But:
* In data: Real $e$ touches zero during calm/intermittent periods. Do you require $e > \epsilon_{\min}$ for the theory to hold, or can you push to arbitrarily small $e$ as long as $\delta$ is active?
* In the SCM: How does the fold extraction algorithm handle near-zero $e$? Does it reject data, filter, or trust the regularization?
Action:
* Specify a minimal-energy threshold $e_{\min}$ or equivalently $\tilde{e}_{\min}$. Relate this to observational noise and model truncation.
* State this explicitly in an Assumptions table.
3. Definition and Operationalization of $\Sigma_{\mathrm{site}}$
The corollary rests on the idea that campaigns sample different slices: $$\Sigma_{\mathrm{site}} = {\mathbf{x} \in \mathbb{R}^5 \mid \Pi_G(\mathbf{x}) = \Pi_{G,\mathrm{site}}}.$$
But $\Pi_G$ (presumably some geophysical invariant like typical surface heat flux magnitude, wind shear, or heating/cooling regimes) is not defined in the document. And the mapping from campaign metadata to $\Sigma_{\mathrm{site}}$ is handwavy.
Action:
* Define $\Pi_G$ explicitly. Examples: characteristic geostrophic wind speed, surface sensible heat flux range, cloud cover classification.
* Show (even crudely) how CASES-99, FLOSS, SHEBA, and BLLAST occupy different $\Sigma_{\mathrm{site}}$ slices in the $(S, T_s, T_g, \ldots)$ space.
* Compute or cite the resulting $\pi_{Ri}$ ranges for each campaign-conditioned slice.
4. Transversality and Smoothness in Theorem 2
You assume: $$\nabla_{\mathcal{S}0}(\det J_f) \neq \mathbf{0} \quad \text{on} \quad \mathcal{C}{\mathrm{fold}}.$$
This is a transversality condition. For polynomial $\mathbf{G}$, $\det J_f$ is a polynomial of degree $\le 4$ in $(\tilde{e}, q_\theta)$, so this is likely satisfied generically. But you should:
Action:
* Verify this numerically on the Option 2 fold-catastrophe model. Compute $\det J_f$ and its restricted gradient on the computed $\mathcal{C}_{\mathrm{fold}}$.
* If the condition fails at isolated points, state that and show the geometry remains valid (codimension ≥ 2 singularities don’t break the manifold structure).

Concrete Next Steps (in priority order)
Tier 1: Worked Symbolic Example
Reduce to a 2D system (e.g., set $S, T_s, T_g$ to constants and study just $\tilde{e}$ and $q_\theta$ dynamics):
$$\tilde{F} = \frac{1}{2}c_m\ell S_0^2 \tilde{e} - \frac{g}{2\theta_0}q_\theta - \frac{\tilde{e}^3}{2\ell},$$ $$\tilde{H} = -c_w\theta_{z,0}\tilde{e}^3 - \frac{g}{\theta_0}c_\theta\ell q_\theta^2 - \frac{C_\theta}{\ell}\tilde{e}^2 q_\theta.$$
Compute $J_f$ explicitly, find $\det J_f = 0$, and extract the fold curve in the $(\tilde{e}, q_\theta)$-plane. Show its shape (e.g., a parabola or higher-order curve). This is publishable as a worked example and validates Theorems 1–2.
Tier 2: Numerical Fold Reconstruction from Option 2 GSPT
Use your verified Option 2 fold-catastrophe model: $$\tilde{e}^2 = \frac{\beta^2}{4} - \Delta,$$ where $\Delta$ is the bifurcation parameter. For fixed $(S, T_s, T_g)$, compute:
* The manifold $\mathcal{S}_0$ as the zero set of $\mathbf{G}$.
* The fold set $\mathcal{C}_{\mathrm{fold}}$ as the singular set of $J_f$.
* The projection $\pi_{Ri}$ of $\mathcal{C}_{\mathrm{fold}}$ and show the resulting $Ri$ range.
Compare against CASES-99 and SHEBA observed $Ri$ values. This validates the Corollary.
Tier 3: WSINDy Identifiability Protocol
Formalize the inference pipeline:
1. Sampling: Given noisy time series $(e(t), q_\theta(t), S(t), \ldots)$ from observations or an SCM run.
2. Polynomial Basis: Construct the library $\Theta = {1, \tilde{e}, q_\theta, \tilde{e}^2, q_\theta^2, \tilde{e}q_\theta, \tilde{e}^3, \ldots}$ up to degree $d_{\max}$.
3. Weak SINDy: Solve $$\min_{\boldsymbol{\theta}} \left| \int \tilde{F}(t) , \phi_i(\tilde{e}(t), q_\theta(t)) , dt - \sum_j \theta_{ij} \int \theta_j(t) \phi_i dt \right|_2^2 + \lambda | \boldsymbol{\theta} |_0$$ to identify $\widehat{\mathcal{F}}$ and $\widehat{\mathcal{H}}$.
4. Determinant Recovery: Compute $\widehat{\det J_f}$ and extract $\widehat{\mathcal{C}}_{\mathrm{fold}}$ as its zero set.
5. Bootstrap Confidence: Perturb the data by noise (15–20%) and re-run 100 times. Compute Hausdorff distance distribution for $\widehat{\mathcal{C}}_{\mathrm{fold}}$ around the true fold.
Tier 4: Assumptions Table
Assumption	Domain	Physical Interpretation	Verification
$\tilde{e} > \tilde{e}_{\min}$	All theorems	Avoids TKE floor and numerical singularities	Specify $\tilde{e}_{\min}$ based on observational noise; check data histograms
$\det J_f(\mathbf{x}_0) \neq 0$	Thm 1	Local uniqueness of equilibrium; generically satisfied	Verify numerically on reduced model
$\nabla_{\mathcal{S}_0}(\det J_f) \neq \mathbf{0}$	Thm 2	Fold is a smooth codimension-1 locus	Compute gradient on $\mathcal{C}_{\mathrm{fold}}$; if violated at isolated points, codim ≥ 2
Rank$(DP_p|{T_p\mathcal{C}{\mathrm{fold}}}) = 1$ (for $\pi_{Ri}$)	Thm 3	Richardson projection is transverse; image is a curve	Verify $\nabla \pi_{Ri}$ is not tangent to $\mathcal{C}_{\mathrm{fold}}$
$\mathbf{G}$ is polynomial in $(\tilde{e}, q_\theta)$	WSINDy	Enables sparse identification; Theorem 3 connects to data	Inherited from fold-catastrophe reduction; check Option 2 form
Pacing for Manuscript
Given that you have three papers planned:
* Paper 1 (observational geometry): Present Theorems 1–2 + Corollary with the worked example and Tier 2 numerical validation.
* Paper 2 (WSINDy + Sturm-Liouville): Introduce Theorem 3 + the Tier 3 identifiability protocol; validate on CASES-99.
* Paper 3 (supervisor function): Use the fold geometry as the backbone for $\Phi$.
This structure keeps Papers 1 and 2 self-contained while building naturally to Paper 3.

Bottom line: The mathematical core is sound, but it needs empirical anchors. The Tier 1 and Tier 2 steps are high-priority and publishable sub-contributions. Tier 3 can be deferred to Paper 2 if you’re in a hurry, but Tier 4 (Assumptions table) should be in Paper 1.
Would you like me to help code up the Tier 1 worked example (symbolic fold extraction in 2D), or draft the Assumptions table in the notation you’re using?

---

Dynamics of the Stable Boundary Layer: A GSPT Framework for Fold Characterization and Regime Transitions

This briefing document synthesizes a comprehensive mathematical and physical framework for the Stable Boundary Layer (SBL) using Geometric Singular Perturbation Theory (GSPT). It centers on the "Fold Characterization Theorem" to resolve long-standing discrepancies in atmospheric turbulence observations.

Executive Summary

The central thesis of the provided research is that the "Richardson threshold paradox"—the wide variability of critical Richardson numbers (Ri_{\text{crit}} \approx 0.2 to 1.2+) observed across field campaigns—is a deterministic consequence of projecting a multidimensional folded manifold onto a scalar diagnostic.

Critical Takeaways:

* Thresholds are Projections: Richardson numbers are not universal invariants but coordinates on a higher-dimensional folded equilibrium manifold.
* Geometric Transitions: Turbulence collapse is defined as a loss of normal hyperbolicity along a "fold locus" (\mathcal{C}_{\text{fold}}).
* Dimensional Hierarchy: The SBL is best understood as a hierarchy of fast-slow systems, where moving from 2D to 5D models reveals increasingly complex phenomena such as "pre-burst turbulence whispering" and "Mixed-Mode Oscillations" (MMOs).
* NWP Transformation: Current Numerical Weather Prediction (NWP) models suffer from "runaway cooling" or "over-mixing" because they rely on static diagnostic thresholds. Upgrading to manifold-based closures preserves nocturnal cold pools and Low-Level Jets (LLJ).

1. The Mathematical Core: Fold Characterization and Projection

The foundational framework utilizes a regularized fast-manifold coordinate chart to desingularize the turbulent-energy domain (\mathcal{M}^+). This allows for a rigorous formalization of the geometric structure of the SBL.

Core Theorem Sequence

Theorem	Focus	Physical/Mathematical Result
Theorem 1	Existence and Smoothness	Establishes the critical manifold (\mathcal{S}_0) as a smooth embedded 3-manifold in \mathbb{R}^5 where fast equilibria (\dot{e}=0, \dot{q}_\theta=0) reside.
Theorem 2	Fold Characterization	Defines the fold set \mathcal{C}_{\text{fold}} where the fast Jacobian (J_f) has a zero determinant. It proves \mathcal{C}_{\text{fold}} is a smooth embedded codimension-one submanifold of \mathcal{S}_0 (dimension 2).
Theorem 3	Projection Theorem	Proves that observed thresholds (R_c) are projection-dependent images of the invariant set \mathcal{C}_{\text{fold}}. Thresholds are locally immersed submanifolds of \mathbb{R}^k.

The Regularized Chart

To resolve singularities, the TKE domain is mapped via: \tilde e = \sqrt{e + \delta},\; \delta \ge 0 This regularization, combined with time rescaling (d\tau = \frac{1}{\tilde e}\,dt), yields a desingularized fast subsystem where the critical manifold and its fold points follow from standard smooth-manifold theorems.

2. Resolving the Richardson Threshold Paradox

The "Paradox" refers to inconsistent Ri_{\text{crit}} values across campaigns like CASES-99 (Kansas) and SHEBA (Arctic).

Geometric Interpretation of "Scatter"

The variability in reported Ri_{\text{crit}} is the physical signature of the fold boundary deforming in response to surface thermodynamics.

* CASES-99: High soil thermal conductivity (G > 0) buffers cooling, keeping the fold point near classical limits (Ri_{\text{fold}} \approx 0.2 to 0.3).
* SHEBA: Snow/ice has near-zero conductivity (G \to 0), allowing intense radiative cooling to build thermal inversions. This deforms the manifold, pushing the extinction threshold far upward (Ri_{\text{fold}} > 1.0).

The Dynamic Ri_{\text{fold}} Equation

The extinction threshold is not a constant but a function of slowly changing surface forcing: Ri_{\text{fold}}(T_s) = \frac{c_s}{1 - \Pi(T_s)} where \Pi(T_s) = \frac{\beta^2 \ell_0}{4 B(T_s)} is a non-dimensional GSPT control parameter sensitive to the surface buoyancy destruction factor B(T_s).

3. Dimensional Hierarchy of the GSPT-SBL Framework

The complexity of the SBL is captured through a dimensional expansion, where each level adds specific physical mechanisms.

Dimension	State Vector (\mathbf{x})	Geometric Object	Physical Phenomenon
2D SBL	(e, S)	1D Critical Curve	Hysteresis loops; basic collapse and recovery thresholds.
3D SBL	(e, S, T_s)	2D Critical Surface	Folded nodes; canard funnels; "pre-burst turbulence whispering."
4D SBL	(e, S, T_s, \Delta)	3D Critical Manifold	Cusp catastrophe; global regime switching (Convective \leftrightarrow Stable).
5D SBL	(e, q_\theta, S, T_s, T_g)	4D Critical Hyper-manifold	Soil-heat buffering; non-equilibrium heat transport; Mixed-Mode Oscillations (MMOs).

Singularities and Intermittency

* Folded Nodes: In 3D systems, the fold locus is a curve. Near a folded node, trajectories perform small-amplitude oscillations (SAOs) before a full burst.
* Canard Explosions: These represent metastable thermal superheating, where a system follows a repelling (unstable) branch for a duration before "exploding" into a large-amplitude relaxation cycle.
* MMOs: Mixed-Mode Oscillations provide a mathematical origin for "bursting" and "turbulence whispering" (low-amplitude intermittency) observed during calm nocturnal conditions.

4. Computational Implementation and Methodology

The framework moves from numerical exploration to rigorous manifold reconstruction using a Julia-native architecture.

The Identification Pipeline (WSINDy and BifurcationKit)

1. Polynomial Basis Extraction (WSINDy): Identifies coefficients from candidate libraries and checks them against closure constants (c_m, c_w, c_\theta, C_\theta).
2. Manifold Reconstruction: Extracted determinants (\det \widehat J_f) are used to reconstruct \widehat{\mathcal C}_{\text{fold}}.
3. Continuation (BifurcationKit.jl): Tracks 1D fold curves and 2D cusp surfaces. It explicitly detects Co-dimension 2 singular points such as Cusp Points (where smooth transitions become catastrophic collapses).
4. Automatic Differentiation (ForwardDiff.jl): Essential for computing higher-order derivatives (F_e, F_{ee}, F_{eee}) without the noise inherent in finite-difference methods.

Fenichel Theory Defense

To address "finite-\epsilon" objections (where \epsilon \approx 10^{-3} to 10^{-2}), the framework utilizes Fenichel's Persistence Theorem:

* Away from Folds: The smooth invariant manifold S_\epsilon persists within \mathcal{O}(\epsilon) distance of S_0.
* At Fold Breakdown: The breakdown of Fenichel persistence is precisely the mechanism that generates canards and MMOs.

5. Implications for Numerical Weather Prediction (NWP)

The GSPT-SBL framework offers five targeted pathways to fix biases in GCMs, NWP, and LES models:

1. Dynamic Thresholds: Replace static Ri_c = 0.25 with Ri_{\text{fold}}(T_s), allowing collapse points to shift with radiative cooling.
2. Prognostic Budgets: Move from algebraic flux-gradient relationships to multi-moment prognostic closures for TKE (e) and heat flux (q_\theta).
3. Stochastic Forcing: Target noise specifically at fold "knees" to trigger realistic probabilistic intermittent turbulence in coarse-grid models.
4. Energy-Consistent Coupling: Limit sensible heat flux by the manifold's turning-point capacity (H_{\max}) to prevent unphysical runaway cooling.
5. Adaptive SFS Models: Use Subfilter-Scale closures in LES to handle the "gray zone" where eddies shrink below mesh resolution, preserving wave-shear interactions.

Comparison of Closure Approaches

* Fixed-Cutoff: Causes premature collapse, leading to runaway surface cooling and severe cold-bias errors.
* Long-Tail Functions: Artificially extend mixing to prevent cooling but smooth out the fold catastrophe, destroying Low-Level Jet formation.
* Manifold-Based: Preserves sharp thermal decoupling and shear-driven recoveries natively as geometric consequences of manifold topology.

