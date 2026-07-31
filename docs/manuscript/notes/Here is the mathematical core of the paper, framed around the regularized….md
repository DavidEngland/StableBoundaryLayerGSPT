Here is the mathematical core of the paper, framed around the regularized energy chart and structured as a sequence of formal differential-geometric theorems.  
## 1. The Fast-Manifold Coordinate Chart  
We define the positive turbulent-energy domain \mathcal{M}^+ = \{ (e, q_\theta, S, T_s, T_g) \in \mathbb{R}^5 \mid e > 0 \}. Rather than treating variable transformations as ad hoc numerical smoothing, we introduce the mapping \phi: \mathcal{M}^+ \to \mathbb{R}_+ \times \mathbb{R}^4 defined by:  
```
\phi(e, q_\theta, S, T_s, T_g) = (\tilde{e}, q_\theta, S, T_s, T_g), \quad \text{where } \tilde{e} = \sqrt{e + \delta} \quad (\delta \ge 0)

```
For any non-negative regularization parameter \delta (with \delta = 0 on \mathcal{M}^+), \phi defines a smooth C^\infty coordinate chart on the fast manifold. Rescaling time by d\tau = (1 / \tilde{e}) \, dt yields the desingularized polynomial fast vector field \mathbf{G} = (\tilde{F}, \tilde{H})^T:  
\tilde{F}(\tilde{e}, q_\theta, \mathbf{y}) = \frac{1}{2} c_m \ell S^2 \tilde{e} - \frac{g}{2\theta_0} q_\theta - \frac{\tilde{e}^3}{2\ell} \tilde{H}(\tilde{e}, q_\theta, \mathbf{y}) = - c_w \theta_z \tilde{e}^3 - \frac{g}{\theta_0} c_\theta \ell q_\theta^2 - \frac{C_\theta}{\ell} \tilde{e}^2 q_\theta  
where \mathbf{y} = (S, T_s, T_g) \in \mathbb{R}^3 represents the slow-variable parameter block, and \theta_z = \partial \theta / \partial z. Because \mathbf{G}: \mathbb{R}^5 \to \mathbb{R}^2 is composed strictly of low-degree polynomials, it is C^\infty-smooth across the entire chart.  
## 2. Core Theorem Sequence  
**Theorem 1 (Existence and Smoothness of the Critical Manifold \mathcal{S}_0)**  
*Let \Omega \subset \mathbb{R}_+ \times \mathbb{R} \times \mathbb{R}^3 be an open domain in the chart coordinates \mathbf{x} = (\tilde{e}, q_\theta, \mathbf{y}). Let \mathbf{G}(\mathbf{x}) = (\tilde{F}(\mathbf{x}), \tilde{H}(\mathbf{x}))^T = \mathbf{0} define the fast equilibrium equations.*  
*If the desingularized fast Jacobian matrix:*  
```
J_f(\mathbf{x}) = \mathbf{D}_{(\tilde{e}, q_\theta)} \mathbf{G}(\mathbf{x}) = \begin{pmatrix} \frac{\partial \tilde{F}}{\partial \tilde{e}} & \frac{\partial \tilde{F}}{\partial q_\theta} \\ \frac{\partial \tilde{H}}{\partial \tilde{e}} & \frac{\partial \tilde{H}}{\partial q_\theta} \end{pmatrix}

```
*has full rank 2 (i.e., \det J_f(\mathbf{x}_0) \neq 0) at a point \mathbf{x}_0 = (\tilde{e}_0, q_{\theta,0}, \mathbf{y}_0) \in \Omega, then there exists an open neighborhood U \subset \mathbb{R}^3 of \mathbf{y}_0 and a unique C^\infty mapping \mathbf{h}: U \to \mathbb{R}^2 such that \mathbf{G}(\mathbf{h}(\mathbf{y}), \mathbf{y}) = \mathbf{0} for all \mathbf{y} \in U.*  
*The set:*  
```
\mathcal{S}_0 = \left\{ (\tilde{e}, q_\theta, \mathbf{y}) \in \Omega \,\,\big\vert{}\,\, (\tilde{e}, q_\theta) = \mathbf{h}(\mathbf{y}) \right\}

```
*is a smooth, embedded 3-dimensional critical manifold in \mathbb{R}^5.*  
**Proof Sketch**  
Since \mathbf{G} is a polynomial mapping in (\tilde{e}, q_\theta), it is C^\infty-smooth on \Omega. The non-singularity condition \det J_f(\mathbf{x}_0) \neq 0 satisfies the hypotheses of the Implicit Function Theorem (IFT) on \mathbf{G}(\tilde{e}, q_\theta, \mathbf{y}) = \mathbf{0}. The IFT guarantees the existence of a local C^\infty function \mathbf{h}(\mathbf{y}) expressing fast variables as functions of slow variables. Global smoothness of \mathcal{S}_0 follows by smoothly patching local graphs over open sets where \det J_f \neq 0. \blacksquare  
**Theorem 2 (Fold Characterization)**  
*Define the turning locus set \mathcal{C}_{\text{fold}} within the critical manifold \mathcal{S}_0 by:*  
```
\mathcal{C}_{\text{fold}} = \left\{ \mathbf{x} \in \mathcal{S}_0 \,\,\big\vert{}\,\, \det J_f(\mathbf{x}) = 0 \right\}

```
*Suppose the gradient condition \nabla_{\mathbf{x}} \left( \det J_f(\mathbf{x}) \right) \neq \mathbf{0} holds for all \mathbf{x} \in \mathcal{C}_{\text{fold}}. Then \mathcal{C}_{\text{fold}} is a smooth, embedded 2-dimensional codimension-one submanifold of \mathcal{S}_0 (and a codimension-3 submanifold of \mathbb{R}^5).*  
**Proof Sketch**  
Define the scalar function D(\mathbf{x}) = \det J_f(\mathbf{x}). Because J_f consists of C^\infty partial derivatives of polynomial functions, D(\mathbf{x}) is a C^\infty mapping from \mathbb{R}^5 \to \mathbb{R}. By the Regular Value Theorem, if 0 is a regular value of D\big\vert{}_{\mathcal{S}_0} (guaranteed by \nabla_{\mathbf{x}} D \neq \mathbf{0}), then D^{-1}(0) \cap \mathcal{S}_0 = \mathcal{C}_{\text{fold}} is a smooth submanifold of dimension \dim(\mathcal{S}_0) - 1 = 2. Normal hyperbolicity fails on \mathcal{C}_{\text{fold}} because at least one eigenvalue of J_f crosses zero. \blacksquare  
**Theorem 3 (Projection Theorem)**  
*Let \mathcal{S}_0 \subset \mathbb{R}^5 be a 3D critical manifold possessing the 2D fold hypersurface \mathcal{C}_{\text{fold}}. Let P: \mathbb{R}^5 \to \mathbb{R}^k (with k \le 4) be a smooth observational projection mapping.*  
*If P satisfies the transversality condition that the differential DP_p \big\vert{}_{T_p \mathcal{C}_{\text{fold}}} has constant rank r \le k for all p \in \mathcal{C}_{\text{fold}}, then:*  
1. *The image P(\mathcal{C}_{\text{fold}}) \subset \mathbb{R}^k is a smooth r-dimensional embedded manifold (or immersed boundary) in observational space.*  
2. *Apparent instability thresholds R_c = P(p) measured in projected coordinates are coordinate-dependent images of the invariant geometric object \mathcal{C}_{\text{fold}}. Under any alternative projection P_2: \mathbb{R}^5 \to \mathbb{R}^k, the observed threshold transforms via R_{c,2} = (P_2 \circ P_1^{-1})(R_{c,1}) along P_1(\mathcal{C}_{\text{fold}}).*  
3. *Apparent instability thresholds R_c = P(p) measured in projected coordinates are coordinate-dependent images of the invariant geometric object \mathcal{C}_{\text{fold}}. Under any alternative projection P_2: \mathbb{R}^5 \to \mathbb{R}^k, the observed threshold transforms via R_{c,2} = (P_2 \circ P_1^{-1})(R_{c,1}) along P_1(\mathcal{C}_{\text{fold}}).*  
4. *Apparent instability thresholds R_c = P(p) measured in projected coordinates are coordinate-dependent images of the invariant geometric object \mathcal{C}_{\text{fold}}. Under any alternative projection P_2: \mathbb{R}^5 \to \mathbb{R}^k, the observed threshold transforms via R_{c,2} = (P_2 \circ P_1^{-1})(R_{c,1}) along P_1(\mathcal{C}_{\text{fold}}).*  
**Proof Sketch**  
The restriction P\big\vert{}_{\mathcal{C}_{\text{fold}}}: \mathcal{C}_{\text{fold}} \to \mathbb{R}^k is a smooth mapping between manifolds. By the Constant Rank Theorem, if DP restricted to the tangent space T_p \mathcal{C}_{\text{fold}} has constant rank r, then P(\mathcal{C}_{\text{fold}}) locally forms an embedded r-dimensional submanifold of \mathbb{R}^k. Observed scalar boundaries are projections of points p \in \mathcal{C}_{\text{fold}}, making R_c fundamentally dependent on the mapping geometry of P. \blacksquare  
**Corollary (Resolution of the Richardson Threshold Paradox)**  
*The critical Richardson numbers Ri_{\text{crit}} reported across field campaigns (e.g., Ri_{\text{crit}} \approx 0.2 in CASES-99 vs. Ri_{\text{crit}} > 1.0 in SHEBA) are not distinct physical instability constants. Rather, they are 1D scalar images \pi_{Ri}\left( \mathcal{C}_{\text{fold}} \cap \Sigma_{\text{site}} \right) under the non-linear projection map:*  
```
\pi_{Ri}(\tilde{e}, q_\theta, S, T_s, T_g) = \frac{g}{\theta_0} \frac{\theta_z}{S^2}

```
*evaluated along campaign-specific thermodynamic constraint surfaces:*  
```
\Sigma_{\text{site}} = \left\{ \mathbf{x} \in \mathbb{R}^5 \,\,\big\vert{}\,\, \Pi_G(\mathbf{x}) = \Pi_{G, \text{site}} \right\}

```
**Physical Consequence**  
The mathematical collapse manifold \mathcal{C}_{\text{fold}} is universal. Field sites do not alter the intrinsic vector field \mathbf{G}; they merely sample different slices \Sigma_{\text{site}} of \mathcal{C}_{\text{fold}} governed by their ground energy ratio \Pi_G.  
## 3. WSINDy Identifiability Workflow Linked to Theory  
By establishing that \mathbf{G}(\tilde{e}, q_\theta, \mathbf{y}) is C^\infty-polynomial on the chart (\tilde{e}, q_\theta), the computational extraction pipeline directly targets the theoretical objects:  
```
Stage 1: Polynomial Basis Extraction (WSINDy)
   └── Identify 𝔽(ẽ, q_θ, y) and ℍ(ẽ, q_θ, y) using candidate polynomial library Θ(ẽ, q_θ, y)
   └── Verify recovered coefficients match closure constants (c_m, c_w, c_θ, C_θ)

Stage 2: Determinant Level Set
   └── Compute symbolic determinant det(Ĵ_f) = 𝔽_ẽ ℍ_q_θ - 𝔽_q_θ ℍ_ẽ
   └── Extract zero level set to reconstruct Ĉ_fold ⊂ ℝ^5

Stage 3: Bootstrap and Perturbation Bounds
   └── Add noise σ ~ 15–20% to test Hausdorff distance d_H(C_fold, Ĉ_fold) < ε

Stage 4: Projection Verification
   └── Apply π_Ri to Ĉ_fold sliced at Π_G = 0.05 (SHEBA) and Π_G = 0.30 (CASES-99)
   └── Demonstrate recovery of observed empirical thresholds Ri_obs

```
This sequence closes the loop: the chart transformation creates the exact polynomial structure that WSINDy requires, allowing data-driven inference to directly reconstruct the invariant manifold objects proven in Theorems 1–3.  
