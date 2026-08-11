## The Asymptotic Mixing Length ($l_0$) as a Geometric Control Parameter

In classical turbulence closures, Blackadar’s asymptotic mixing length $l_0$ functions as an empirical coefficient tuned to yield realistic turbulent diffusivities. Within the 4D GSPT-SBL framework, however, $l_0$ enters the reduced dynamics analytically, governing the topology of the critical manifold $\mathcal{S}_0$.

### 1. Mathematical Setting and Assumptions

> **Assumptions**
> Consider the reduced atmospheric subsystem obtained from the regularized 4D GSPT-SBL equations under the classic Blackadar mixing-length closure:
>
> $$l(z) = \frac{\kappa z}{1 + \frac{\kappa z}{l_0}}$$
>
>
>
> with fixed physical parameters $\beta > 0$, background mixing floor $\delta > 0$, and closure constant $c_\mu > 0$. Assume the critical manifold $\mathcal{S}_0$ is defined by the reduced equilibrium relation $F(q, \Delta; l_0) = 0$, where $q$ is the velocity scale, $\Delta$ is net environmental forcing, and $e \ge 0$ is turbulent kinetic energy.

---

### 2. Formal Theorems and Corollaries

> ### **Theorem 1** (*Asymptotic Mixing Length as a Geometric Control Parameter*)
>
>
> Under the stated assumptions, $l_0 \in \mathbb{R}^+$ acts as a codimension-one bifurcation parameter governing the topology of the critical manifold $\mathcal{S}_0$. Continuous variation of $l_0$:
> 1. **Rescales Equilibrium Geometry:** Deforms the active attracting equilibrium surface through multiplicative scaling of the stable branch $q_+(\Delta) = \frac{\beta l_0 + l_0 \sqrt{\beta^2 + 4\Delta}}{2}$.
> 2. **Shifts Fold Catastrophe Invariants:** The fold locus $\mathcal{C}_{\text{fold}}$ coordinates in the reduced model satisfy the analytical relations:
>
> $$e_{\text{fold}}(l_0) = \frac{\beta^2 l_0^2}{4} - \delta, \qquad q_{\text{fold}}(l_0) = \frac{\beta l_0}{2}$$
>
>
> 3. **Parameter-Space Bifurcation Boundary:** The equality
>
> $$\delta = \frac{\beta^2 l_0^2}{4}$$
>
>
>
> defines a codimension-one bifurcation boundary in parameter space $(\delta, l_0)$. On one side of this boundary ($\delta < \frac{\beta^2 l_0^2}{4}$), the reduced critical manifold possesses a physically admissible fold ($e_{\text{fold}} > 0$), whereas on the other side ($\delta \ge \frac{\beta^2 l_0^2}{4}$), the fold lies outside the admissible domain $e \ge 0$.
>
>

> ### **Corollary 1** (*Monotonic Limit*)
>
>
> If $\delta \ge \frac{\beta^2 l_0^2}{4}$, the reduced atmospheric critical manifold $\mathcal{S}_0$ possesses no physically admissible interior fold ($e_{\text{fold}} \le 0$). Consequently, catastrophic turbulence collapse through an interior fold bifurcation of the isolated atmospheric subsystem cannot occur.

> ### **Theorem 2** (*Monotonic Deformation Theorem*)
>
>
> Let $l_0^{(1)} < l_0^{(2)}$. The corresponding critical manifolds satisfy an order-preserving geometric deformation:
>
> $$\mathcal{S}_0\left(l_0^{(1)}\right) \prec \mathcal{S}_0\left(l_0^{(2)}\right)$$
>
>
>
> where increasing $l_0$ monotonically enlarges the admissible folded region in phase space while preserving manifold topology until the codimension-one boundary $\delta = \frac{\beta^2 l_0^2}{4}$ is crossed.

---

### 3. Quantitative Mapping: Geometry to Physics

Establishing $l_0$ as a continuation parameter yields direct mappings between state-space geometry and physical atmospheric processes:

| Metric / Parameter | Mathematical Meaning | Atmospheric Dynamics / Physical Interpretation |
| --- | --- | --- |
| **$l_0$** | **Geometric deformation parameter** | **Maximum asymptotic turbulent length scale** |
| **Fold Energy ($e_{\text{fold}}$)** | Quadratic invariant ($e_{\text{fold}} \propto l_0^2$) | Background TKE threshold required to trigger abrupt collapse |
| **Velocity Scale ($q_{\text{fold}}$)** | Linear invariant ($q_{\text{fold}} \propto l_0$) | Critical wind speed scale for turbulent boundary layer maintenance |
| **Boundary Curve ($\delta = \frac{\beta^2 l_0^2}{4}$)** | Codimension-1 parameter boundary | Threshold separating abrupt, hysteresis-driven transitions from smooth decays |
| **Transversal Slope ($e=0$)** | Boundary contact slope $\sim \frac{l_0^2}{c_\mu}$ | Sensitivity of laminar-turbulent transitions to changes in environmental forcing ($\Delta$) |

---

### 4. Interpretation and Physical Consequences

$$\boxed{ \text{Blackadar's closure is simultaneously} \begin{cases} \text{a empirical turbulence closure,} \\ \text{a geometric deformation parameter of the slow manifold } \mathcal{S}_0. \end{cases} }$$

> **Interpretation.** In classical turbulence closures, the asymptotic mixing length determines the magnitude of turbulent exchange coefficients ($K_m = l \sqrt{e}$). Within the 4D GSPT-SBL framework, the same parameter additionally dictates the geometry of the reduced equilibrium manifold. Consequently, $l_0$ serves both as a closure parameter and as a geometric control parameter governing the existence, location, and disappearance of admissible fold singularities ($l_0 \longrightarrow \mathcal{S}_0$).

#### Observational Bounds and Decoupling

* **The Small-$l_0$ Limit:** Decreasing $l_0$ drives $e_{\text{fold}}$ below zero, smoothing out the interior fold catastrophe entirely. This provides an analytical explanation for why shallow or weakly turbulent stable boundary layers transition monotonically without discrete hysteresis loops.
* **Atmospheric Coupling:** Calibration against shallow nocturnal boundary-layer observations (e.g., CASES-99, SHEBA) bounds this macroscale parameter to $l_0 \approx 10\text{--}20\text{ m}$ for the present closure. Unphysically large values (e.g., $l_0 > 100\text{ m}$) generate excessive background turbulent diffusion aloft ($K_m \approx l_0 \sqrt{\delta}$), keeping the atmosphere strongly coupled to surface friction, suppressing nocturnal decoupling, and washing out the inertial acceleration necessary for Low-Level Jet (LLJ) formation.