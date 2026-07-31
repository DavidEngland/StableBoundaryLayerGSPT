Here is a mathematically closed 2D reduction of the GSPT-SBL framework that preserves the exact regularized geometry, fold invariants, and fast-slow timescale separation of the full 4D system.  
## 1. Minimal 2D Fast-Slow Dynamical System  
By holding background buoyancy destruction constant ($B_0 > 0$) and projecting horizontal momentum onto a scalar bulk shear coordinate $S = \vert{}\mathbf{u}\vert{}/h$, the 4D state space reduces to the state vector $\mathbf{x} = (e, S)^T$:  
$$\begin{aligned} \varepsilon \frac{de}{dt} &= l_0 \left( c_s S^2 - B_0 \right) \left( \frac{e+\delta}{\sqrt{e+\delta} + \alpha} \right) + \beta(e+\delta) - \frac{(e+\delta)^{3/2}}{l_0} && \text{(Fast TKE Response, } \mathcal{O}(\varepsilon)\text{)} \\ \frac{dS}{dt} &= \mu (S_g - S) - C_D S \sqrt{e+\delta} && \text{(Slow Shear Driver, } \mathcal{O}(1)\text{)} \end{aligned}$$  
## Physical Parameter Roles  
* $S_g$: Supergeostrophic target shear aloft driving the low-level jet (LLJ).  
* $\mu$: Synoptic/rotational relaxation rate ($\sim f$, Coriolis frequency).  
* $B_0$: Background thermal stratification / buoyant destruction ($B_0 = K G(T_s) > 0$).  
* $c_s$: Mechanical shear production scaling coefficient.  
* $C_D$: Surface turbulent drag coefficient depleting vertical shear.  
* $\delta, \alpha > 0$: TKE regularization floor and boundary-layer smoothing parameters.  
## 2. Geometric Manifold Analysis ($\varepsilon \to 0$)  
In the singular limit $\varepsilon \to 0$, the fast TKE coordinate relaxes to the **critical manifold** $\mathcal{M}_0$. Defining $q = \sqrt{e+\delta}$, the algebraic equation $f(q, S) = 0$ outside the $\mathcal{O}(\alpha)$ boundary region simplifies to:  
$$q \left[ l_0 (c_s S^2 - B_0) + \beta q - \frac{q^2}{l_0} \right] = 0$$  
This yields two distinct branches:  
1. **Quiescent / Laminar Branch ($\mathcal{M}_0^-$):** $q = \sqrt{\delta} \approx 0 \implies e \approx 0$.  
2. **Active Turbulent Branch ($\mathcal{M}_0^+$):** Expressed explicitly as a parabolic curve in shear space: $$c_s S^2(q) = B_0 - \frac{\beta}{l_0} q + \frac{q^2}{l_0^2}$$   
    TKE (e)  
     ▲  
     │                             Active Turbulent Branch (M₀⁺)  
     │                                ╲               ╱  
 e_burst│───────────────────────────────▲             ╱  
     │                                │             ╱  
     │                                │ Fast        ╱  
     │                                │ Jump        ╱  Decoupling /  
 e_fold│─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐          │ Up          ╱   Shear Decay  
     │                  │          │            ╱    (dS/dt < 0)  
     │   Fast Jump Down │          │           ╱  
     │   (Collapse)     ▼          │          ╱  
     │       laminar floor         │         ╱  
  0 ─┴───────*─────────────────────*────────*─────────────► Shear (S)  
            S_fold              S_trans    S_g  
             (Fold Locus C_fold) (Transcritical)  
## 3. Analytical Bifurcation Loci  
The geometry produces two critical transition points along the slow shear axis, establishing a topological **hysteresis loop** of width $\Delta S = S_{\text{trans}} - S_{\text{fold}}$:  
## Fold Locus ($\mathcal{C}_{\text{fold}}$)  
The active branch loses normal hyperbolicity where $\frac{\partial f}{\partial e} = 0$, yielding the invariant fold parameters:  
$$q_{\text{fold}} = \frac{\beta l_0}{2} \implies e_{\text{fold}} = \frac{\beta^2 l_0^2}{4} - \delta, \qquad S_{\text{fold}} = \sqrt{\frac{B_0 - \frac{\beta^2}{4}}{c_s}}$$  
If $S$ drops below $S_{\text{fold}}$, the active manifold terminates, forcing a **fast downward jump ($\mathcal{O}(\varepsilon)$)** along fast fibers to the laminar floor ($e \approx 0$).  
## Transcritical Activation ($S_{\text{trans}}$)  
On the laminar floor ($e \approx 0$), mechanical shear production balances buoyant destruction when $c_s S^2 - B_0 = 0$:  
$$S_{\text{trans}} = \sqrt{\frac{B_0}{c_s}}$$  
When $S$ exceeds $S_{\text{trans}}$, the laminar branch becomes repelling, triggering a **fast upward jump ($\mathcal{O}(\varepsilon)$)** to the active branch ($e = e_{\text{burst}}$).  
## 4. Conditions for Singular Relaxation Oscillations  
To ensure continuous intermittent bursting (a stable limit cycle) rather than convergence to a steady state, the slow nullcline $\frac{dS}{dt} = 0$ must intersect the critical manifold on its repelling middle fold segment or fail to intersect $\mathcal{M}_0^+$ altogether.  
This requires two parameter bounds on the target shear $S_g$:  
$$\underbrace{S_{\text{trans}}}_{\text{Must exceed activation threshold}} < S_g < \underbrace{S_{\text{fold}} \left( 1 + \frac{C_D q_{\text{fold}}}{\mu} \right)}_{\text{Drag must pull equilibrium below fold}}$$  
## The 4-Phase Bursting Cycle  
1. **Quiescent Phase ($S \uparrow$):** On $e \approx 0$, surface drag vanishes ($C_D S \sqrt{\delta} \approx 0$). Shear accelerates slowly under geostrophic forcing: $$\frac{dS}{dt} = \mu(S_g - S) > 0$$   
2. **Turbulent Burst ($\mathcal{O}(\varepsilon)$ Jump Up):** At $S = S_{\text{trans}}$, $e$ escapes along fast fibers to $e_+(S_{\text{trans}})$, rapidly restoring turbulent mixing.  
3. **Decoupling / Shear Decay ($S \downarrow$):** On $e = e_+(S)$, heavy turbulent drag dominates geostrophic acceleration ($C_D S \sqrt{e+\delta} > \mu (S_g - S)$), causing shear to collapse: $$\frac{dS}{dt} < 0$$   
4. **Abrupt Collapse ($\mathcal{O}(\varepsilon)$ Jump Down):** At $S = S_{\text{fold}}$, normal hyperbolicity fails ($\partial_e f = 0$). TKE undergoes a brittle fast collapse back to $e \approx 0$, restarting the slow cycle.  
