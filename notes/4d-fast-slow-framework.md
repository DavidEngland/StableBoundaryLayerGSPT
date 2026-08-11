# A 4D Fast-Slow Framework for the Nocturnal Stable Boundary Layer: Fold Catastrophes, Boundary Transcritical Recovery, and Emergent Dynamics

**Abstract**

The modeling of the nocturnal stable boundary layer (SBL) traditionally suffers from empirical stability functions and Monin–Obukhov Similarity Theory (MOST) breakdowns under strongly stable conditions, causing unphysical "runaway cooling" and numerical stiffness. We present a self-contained theoretical framework using Geometric Singular Perturbation Theory (GSPT) that reformulates the SBL as a 4D fast-slow dynamical system. By introducing nonlinear Kolmogorov dissipation and a $C^1$-smooth activation gate, we prove that SBL transitions are governed by a non-degenerate fold catastrophe on the critical manifold alongside a boundary transcritical recovery mechanism. We map the macroscale slow forcing directly onto classical gradient Richardson number physics ($Ri_g$), establish the positive invariance of the state space, prove the structural stability of the fold locus, and characterize a codimension-1 parameter boundary defining a topological phase transition between folded (bistable) and monotonic boundary-layer dynamics.

---

## 1. Governing Fast-Slow System Formulation

We model the coupled atmosphere-surface system on the state space:


$$\mathcal{X} = \left\{ (e, U, V, T_s) \in \mathbb{R}^4 \;\Big\vert{}\; e \ge -\delta, \; T_s > 0 \right\}$$


where $e$ is translated by a fixed background mixing parameter $\delta > 0$ representing unresolved residual mixing (e.g., gravity-wave breaking or canopy wakes). The physically admissible regularized Turbulent Kinetic Energy (TKE) variable is defined as:


$$\tilde{e} := e + \delta \ge 0$$


The state vector decomposes into a fast coordinate $e$ and a slow macroscale vector $y = (U, V, T_s) \in \mathbb{R}^3$, partitioned by the small singular perturbation parameter $0 < \epsilon \ll 1$ ($\epsilon = \tau_{\text{fast}}/\tau_{\text{slow}}$).

### 1.1 Complete ODE System

$$\begin{aligned} \epsilon \frac{de}{dt} &= F_{\text{reg}}(\tilde{e}, y) := l_0 \Delta(y) \left( \frac{\tilde{e}}{\sqrt{\tilde{e}} + \alpha} \right) + \beta \tilde{e} - \frac{\tilde{e}^{3/2}}{l_0} \\ \frac{dU}{dt} &= f(V - V_g) - \gamma \sqrt{\tilde{e}} U \\ \frac{dV}{dt} &= -f(U - U_g) - \gamma \sqrt{\tilde{e}} V \\ \frac{dT_s}{dt} &= \frac{1}{C_s} \left[ R_{\downarrow} - \sigma T_s^4 - \rho c_p C_H \sqrt{\tilde{e}} (T_s - T_a) - \frac{K_g}{d_g}(T_s - T_g) \right] \end{aligned}$$

Here, $\alpha \ll 1$ is a boundary regularizer velocity scale, $l_0$ is the master mixing length, $\beta$ is the nonlinear turbulence self-amplification parameter, and $\Delta(y)$ represents net macroscale forcing.

---

## 2. Critical Manifold Structure and the Fold Catastrophe

In the singular limit $\epsilon \to 0$, the fast variable relaxes instantaneously to the roots of $F_{\text{reg}}(\tilde{e}, y) = 0$. Outside an $\mathcal{O}(\alpha)$ boundary neighborhood of $\tilde{e}=0$, the system is well-approximated by the velocity-scale equation $q := \sqrt{\tilde{e}} \ge 0$:


$$F(q, y) = q \left[ l_0 \Delta(y) + \beta q - \frac{q^2}{l_0} \right] = 0$$

### 2.1 Manifold Branches

The algebraic equilibrium equation yields three distinct manifold sheets:

1. **Laminar Floor Branch ($\mathcal{M}_0^{\text{lam}}$):** $q_{\text{lam}} = 0 \implies e^* = -\delta$
2. **Unstable Threshold Branch ($\mathcal{M}_0^{-}$):** $q_{-}(\Delta) = \frac{\beta l_0 - l_0 \sqrt{\beta^2 + 4\Delta(y)}}{2}$
3. **Active Stable Branch ($\mathcal{M}_0^{+}$):** $q_{+}(\Delta) = \frac{\beta l_0 + l_0 \sqrt{\beta^2 + 4\Delta(y)}}{2}$

```
                   e (TKE)
                   ^
                   |         Active Stable Branch (M_0^+)
                   |        /
                   |       /  <-- Fold Catastrophe (C_fold)
                   |      *----------------------
                   |     /  Unstable Branch (M_0^-)
                   |    /
  -----------------+----------------------------> \Delta(y)
  Laminar Floor    |  Transcritical Point (\Delta = 0)
  (M_0^lam)        |  e = -\delta

```

### 2.2 Derivation of the Fold Locus ($\mathcal{C}_{\text{fold}}$)

A fold catastrophe occurs where the equilibrium condition and the loss of normal hyperbolicity hold simultaneously:


$$\begin{cases}  \dfrac{F(q, y)}{q} = l_0 \Delta(y) + \beta q - \dfrac{q^2}{l_0} = 0 & \text{(Active Branch Equilibrium)} \\ \dfrac{\partial F}{\partial q} = l_0 \Delta(y) + 2\beta q - \dfrac{3q^2}{l_0} = 0 & \text{(Loss of Normal Hyperbolicity)} \end{cases}$$

Subtracting the equilibrium condition from the derivative equation eliminates $l_0 \Delta(y)$:


$$\left( l_0 \Delta(y) + 2\beta q - \frac{3q^2}{l_0} \right) - \left( l_0 \Delta(y) + \beta q - \frac{q^2}{l_0} \right) = 0 \implies \beta q - \frac{2q^2}{l_0} = 0$$

Since $q \neq 0$ on the active branch, this identifies the non-degenerate fold curve:


$$q_{\text{fold}} = \frac{\beta l_0}{2} \implies e_{\text{fold}} = \frac{\beta^2 l_0^2}{4} - \delta, \qquad \Delta_{\text{fold}} = -\frac{\beta^2}{4}$$

> **Theorem (Structural Separation Principle):**
> The location of the fold point in the fast state coordinate ($q_{\text{fold}}$) is an **intrinsic geometric invariant** of micro-scale turbulence dynamics ($l_0, \beta$), independent of the slow variables $y = (U, V, T_s)$. The slow subsystem acts exclusively as a scalar driver through $\Delta(y)$, driving the state vector across the threshold $\Delta_{\text{fold}}$.

---

## 3. Boundary Well-Posedness, Invariance, and Structural Stability

Unregularized formulations involving $\sqrt{\tilde{e}}$ suffer from non-Lipschitz behavior ($\frac{\partial}{\partial \tilde{e}}\sqrt{\tilde{e}} \to \infty$ as $\tilde{e} \to 0^+$), violating classical Picard–Lindelöf existence and uniqueness guarantees.

### 3.1 Lipschitz Continuity

The activated production operator uses $\Psi(\tilde{e}; \alpha) = \frac{\sqrt{\tilde{e}}}{\sqrt{\tilde{e}} + \alpha}$. Evaluating the partial derivative at the boundary $\tilde{e} = 0$:


$$\left. \frac{\partial F_{\text{reg}}}{\partial \tilde{e}} \right\vert{}_{\tilde{e}=0} = \frac{l_0 \Delta(y)}{\alpha} + \beta < \infty$$


The regularized vector field $F_{\text{reg}}$ is locally Lipschitz continuous on every bounded subset of $\mathcal{X}$, satisfying the hypotheses of the Picard–Lindelöf theorem and ensuring unique forward ODE solutions.

### 3.2 Positive Invariance Proof

> **Proposition (Positive Invariance of the Physical Domain):**
> *If $\tilde{e}(0) \ge 0$, then $\tilde{e}(t) \ge 0$ for all $t \ge 0$.*
> **Proof:** At the domain boundary $\tilde{e} = 0$:
>
> $$F_{\text{reg}}(0, y) = l_0 \Delta(y) \left(\frac{0}{0+\alpha}\right) + \beta(0) - \frac{0^{3/2}}{l_0} \equiv 0$$
>
>
>
> Because $F_{\text{reg}}(0, y) = 0$ and $\frac{\partial F_{\text{reg}}}{\partial \tilde{e}}$ is everywhere bounded, the vector field is tangent to the boundary hyperplane $\partial\mathcal{X} = \{ \tilde{e} = 0 \}$. By Nagumo’s Viability Theorem, the boundary is invariant, making $[0, \infty)$ strictly positively invariant under the flow. $\blacksquare$

### 3.3 Structural Stability Theorem

> **Theorem (Preservation of Fold Geometry):**
> *For any compact set $K \subset \mathcal{X} \setminus \{ \tilde{e} = 0 \}$, the regularized operator satisfies $\Vert{} F_{\text{reg}} - F \Vert{}_{C^1(K)} = \mathcal{O}(\alpha)$ as $\alpha \to 0^+$. By Thom’s Transversality Theorem, the fold catastrophe $\mathcal{C}_{\text{fold}}$, normal hyperbolicity loss, and canard orbit geometry are structurally stable topological features preserved under the $C^\infty$ activation gate for all sufficiently small $\alpha > 0$.*

---

## 4. Transcritical Boundary Recovery and Richardson-Number Physics

### 4.1 Boundary Transcritical Bifurcation ($\Delta = 0$)

The recovery of the SBL from a collapsed laminar state is governed by a transcritical bifurcation occurring directly on the phase boundary $\tilde{e} = 0$:

$$\begin{array}{rcccl} \text{Regime} & \Delta(y) \text{ Range} & \lambda_{\text{lam}} = \left. \frac{\partial F_{\text{reg}}}{\partial q} \right\vert{}_{q=0} & \text{Boundary Stability} & \text{Physical State} \\ \hline \text{Collapsed} & \Delta < -\frac{\beta^2}{4} & l_0 \Delta < 0 & \text{Stable Attractor} & \text{Quiescent Laminar Layer} \\ \text{Hysteresis} & -\frac{\beta^2}{4} < \Delta < 0 & l_0 \Delta < 0 & \text{Stable Attractor} & \text{Bistable / Decoupled Orbit} \\ \mathbf{Transcritical} & \mathbf{\Delta = 0} & \mathbf{0} & \mathbf{\text{Stability Exchange}} & \mathbf{\text{Unstable Root } q_- \text{ Crosses Boundary}} \\ \text{Recovery} & \Delta > 0 & l_0 \Delta > 0 & \text{Strictly Repelling} & \text{Spontaneous Re-ignition} \end{array}$$

When shear production overcomes thermal stratification ($\Delta(y) > 0$), the unstable root $q_- < 0$ moves into the unphysical domain. The laminar equilibrium $q = 0$ **ceases to exist as a stable invariant set** ($\lambda_{\text{lam}} > 0$), forcing any residual noise $\tilde{e} > 0$ to grow exponentially toward $q_+$.

### 4.2 Bridge to Gradient Richardson Number ($Ri_g$)

The net forcing term $\Delta(y)$ maps directly onto classical atmospheric boundary-layer physics:


$$\Delta(y) := S^2 - N^2 = S^2 \left( 1 - Ri_g \right)$$


where $S^2 = \eta\gamma(U^2+V^2)$ is the mechanical shear frequency squared and $N^2 = KG(T_s)$ is the buoyant stratification frequency squared.

```
                   \Delta(y) = S^2 (1 - Ri_g)

      \Delta < -\beta^2/4        -\beta^2/4 < \Delta < 0          \Delta > 0
  <--------------------------|----------------------------|-------------------------->
     Ri_g > 1 + \beta^2/4S^2   1 < Ri_g < 1 + \beta^2/4S^2         Ri_g < 1
       [Laminar Collapse]           [Bistable Hysteresis]      [Spontaneous Recovery]

```

1. **Laminar Recovery Threshold ($\Delta = 0$):**
$$S^2 (1 - Ri_g) = 0 \implies Ri_g = 1$$



Recovery occurs as soon as the gradient Richardson number falls below unity ($Ri_g < 1$).
2. **Dynamic Collapse Fold ($\Delta_{\text{fold}} = -\frac{\beta^2}{4}$):**
$$S^2 (1 - Ri_g) = -\frac{\beta^2}{4} \implies Ri_c = 1 + \frac{\beta^2}{4S^2} > 1$$



The critical breakdown threshold $Ri_c$ exceeds unity due to nonlinear self-amplification ($\beta > 0$), explaining why active mixing can persist in strongly stratified layers ($Ri_g > 1$) until reaching the fold catastrophe.

---

## 5. Topological Phase Transitions in Parameter Space

The physical realizability condition $e_{\text{fold}} > 0$ defines a **codimension-1 parameter boundary**:


$$\mathcal{P}_{\text{crit}} = \left\{ (\beta, l_0, \delta) \in \mathbb{R}^3_+ \;\Bigg\vert{}\; \delta = \frac{\beta^2 l_0^2}{4} \right\}$$

```
          \delta (Background Mixing Parameter)
            ^
            |       MONOTONIC REGIME
            |   (Continuous Transition, No Hysteresis)
            |
  \delta = \beta^2 l_0^2 / 4
  ----------+-------------------------------------- Codimension-1 Boundary
            |
            |       FOLDED / BISTABLE REGIME
            |   (Catastrophic Collapse, Canards, LLJ)
            +-------------------------------------> \beta (Self-Amplification)

```

* **Folded Regime ($\delta < \frac{\beta^2 l_0^2}{4}$):** The critical manifold contains a non-degenerate fold catastrophe $\mathcal{C}_{\text{fold}}$. The system exhibits bistability, catastrophic collapse, inertial oscillations, and hysteresis.
* **Monotonic Regime ($\delta \ge \frac{\beta^2 l_0^2}{4}$):** The fold point vanishes into the unphysical domain $e < -\delta$. The critical manifold becomes monotonically increasing with respect to $\Delta(y)$, forcing smooth transitions without catastrophic jumps.

---

## 6. Emergent Atmospheric Dynamics

### 6.1 The Low-Level Jet (LLJ) as a Transient Slow Orbit

When radiative cooling pushes $\Delta(y) \le -\frac{\beta^2}{4}$, the system jumps along fast fibers from $e_{\text{fold}}$ to $\mathcal{M}_0^{\text{lam}}$ ($\tilde{e} \to 0$). Frictional drag terms vanish ($\gamma \sqrt{\tilde{e}} \to 0$), reducing the slow equations to an uncoupled linear oscillator:


$$\frac{dU}{dt} = f(V - V_g), \qquad \frac{dV}{dt} = -f(U - U_g)$$

The solution is a circular, clockwise inertial orbit in $(U, V)$ phase space centered at $(U_g, V_g)$. The wind reaches supergeostrophic speeds ($U_{\text{max}} \approx 1.5 - 2.0 \, U_g$) purely as an **orbital trajectory excursion** on the laminar floor prior to re-crossing the recovery threshold $\Delta(y) > 0$.

### 6.2 Emergent SBL Depth Functional

Rather than imposing a static boundary-layer height $h$, $h$ is defined as a **smooth state-space functional** $\mathcal{H}: \mathcal{X} \to \mathbb{R}^+$:


$$\mathcal{H}(x) = \mathcal{H}(e, U, V, T_s) := \alpha \, \phi(e) \int_0^\infty \exp\left( -\frac{\zeta}{\ell(\alpha \phi(e) \zeta)} \right) d\zeta$$


where $\phi(e) = \frac{\sqrt{e+\delta}}{\sqrt{e+\delta} + E_{\text{reg}}}$ is the slow-manifold occupancy function.

* **Turbulent State ($\phi(e) \approx 1$):** $\mathcal{H}(x)$ recovers classical Monin–Obukhov boundary layer scaling.
* **Collapsed State ($\phi(e) \to 0$):** $\mathcal{H}(x) \to 0$, uncoupling the atmosphere from surface skin friction dynamically without ad-hoc conditional logic.

---

## 7. Summary Matrix of Formal Results

| Feature / Property | Mathematical Expression | Physical / Dynamical Significance |
| --- | --- | --- |
| **Domain Invariance** | $F_{\text{reg}}(0, y) \equiv 0 \implies \tilde{e}(t) \ge 0$ | Proves non-negativity of regularized TKE via Nagumo's Theorem. |
| **Lipschitz Regularization** | $\left. \frac{\partial F_{\text{reg}}}{\partial \tilde{e}} \right\vert{}_{0} = \frac{l_0 \Delta}{\alpha} + \beta < \infty$ | Restores Picard–Lindelöf existence and uniqueness guarantees. |
| **Fold Locus** | $q_{\text{fold}} = \frac{\beta l_0}{2}, \quad \Delta_{\text{fold}} = -\frac{\beta^2}{4}$ | Non-degenerate saddle-node bifurcation; geometry separates from slow forcing. |
| **Transcritical Recovery** | $\left. \lambda_{\text{lam}} \right\vert{}_{\Delta > 0} = l_0 \Delta > 0$ | Spontaneous re-ignition driven by loss of boundary equilibrium stability. |
| **GFD Mapping** | $\Delta(y) = S^2(1 - Ri_g)$ | Direct equivalence to gradient Richardson number physics ($Ri_c > 1$). |
| **Topological Boundary** | $\delta = \frac{\beta^2 l_0^2}{4}$ | Codimension-1 boundary separating folded (bistable) and monotonic regimes. |
| **Structural Stability** | $\Vert{} F_{\text{reg}} - F \Vert{}_{C^1(K)} = \mathcal{O}(\alpha)$ | Thom's Transversality Theorem guarantees preservation of fold/canard geometry. |
| **SBL Depth Functional** | $h = \mathcal{H}(e, U, V, T_s)$ | Dynamic boundary-layer height emerging as a functional on state space. |