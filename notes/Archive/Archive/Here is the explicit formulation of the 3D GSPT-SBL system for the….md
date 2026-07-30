Here is the explicit formulation of the **3D GSPT-SBL system** for the state vector $\mathbf{x} = (e, S, T_s)^T$, comprising **one fast variable** (Turbulent Kinetic Energy $e$) and **two slow variables** (bulk vertical shear $S$ and skin temperature $T_s$).  
## 1. Explicit 3D Dynamical System  
$$\begin{aligned} \varepsilon \frac{de}{dt} &= l_0 \Big( c_s S^2 - B(T_s) \Big) \left( \frac{e+\delta}{\sqrt{e+\delta} + \alpha} \right) + \beta(e+\delta) - \frac{(e+\delta)^{3/2}}{l_0} && \text{(Fast TKE Response, } \mathcal{O}(\varepsilon)\text{)} \\ \frac{dS}{dt} &= \mu (S_g - S) - C_D S \sqrt{e+\delta} && \text{(Slow Shear Evolution, } \mathcal{O}(1)\text{)} \\ \frac{dT_s}{dt} &= \frac{1}{C_{\text{skin}}} \left[ R_\downarrow - \sigma_{\text{SB}} T_s^4 - \lambda (T_s - T_{\text{deep}}) - \rho c_p C_H S \sqrt{e+\delta} \, (T_s - T_a) \right] && \text{(Slow Thermal Evolution, } \mathcal{O}(1)\text{)} \end{aligned}$$  
Where the non-linear buoyant destruction function $B(T_s)$ is given by:  
$$B(T_s) = K \tanh \!\left( \beta_T \frac{T_a - T_s}{T_a} \right)$$  
## 2. Geometry of the 3D Phase Space  
## The Critical Manifold ($\mathcal{M}_0$)  
In the singular limit $\varepsilon \to 0$, setting $q = \sqrt{e+\delta}$, the fast equation defines a **2D surface embedded in 3D phase space** $(S, T_s, e)$:  
$$\mathcal{M}_0^+ : \quad c_s S^2 = B(T_s) - \frac{\beta}{l_0} q + \frac{q^2}{l_0^2}$$  
Unlike the 2D reduction (where $\mathcal{M}_0$ was a 1D curve), $\mathcal{M}_0^+$ is now a 2D surface folded over the $(S, T_s)$ slow base space.  
                  TKE Coordinate (e or q)  
                   ▲  
                   │              2D Active Sheet (M₀⁺)  
                   │              /───────────────┐  
                   │             /               /│  
                   │            /   Fold Curve  / │  (Loss of Normal  
                   │           /    C_fold     /  │   Hyperbolicity)  
                   │          / ──*───────────*   │  
                   │         /   ╱           ╱    │  
                   │        /   ╱           ╱     │  
                   │       /   ╱           ╱      ▼  
                   └──────┼───*───────────*──────────────► Shear (S)  
                         /   Folded Node   
                        /  (Canard Funnel)  
                       ▼  
                 Skin Temp (T_s)  
## The 1D Fold Curve ($\mathcal{C}_{\text{fold}}$)  
Normal hyperbolicity ($\partial_e f = 0$) fails along a **1D space curve** rather than at an isolated point:  
$$q_{\text{fold}} = \frac{\beta l_0}{2}, \qquad \mathcal{C}_{\text{fold}} = \left\{ (S, T_s, e) \;\middle\vert{}\; c_s S^2 = B(T_s) - \frac{\beta^2}{4}, \quad e = \frac{\beta^2 l_0^2}{4} - \delta \right\}$$  
## 3. Desingularized Slow Flow and Folded Singularities  
To analyze trajectories near the fold curve $\mathcal{C}_{\text{fold}}$, we project the slow dynamics onto $\mathcal{M}_0$ using implicit differentiation of $f(e, S, T_s) = 0$. Rescaling time by $\tau = t / (\partial_q f)$, the **desingularized slow flow** on the surface coordinates $(q, T_s)$ becomes:  
$$\begin{aligned} \frac{dq}{d\tau} &= -\frac{1}{\partial_S f} \left( \frac{\partial f}{\partial T_s} \dot{T}_s + \frac{\partial f}{\partial S} \dot{S} \right) \\ \frac{dT_s}{d\tau} &= \left( -\frac{\partial f}{\partial q} \right) \dot{T}_s \end{aligned}$$  
## Origin of Folded Nodes & Mixed-Mode Oscillations (MMOs)  
A **folded singularity** occurs on the fold curve $\mathcal{C}_{\text{fold}}$ where the direction of the slow vector field becomes parallel to the fast direction ($\partial_q f = 0$), requiring the numerator of $dq/d\tau$ to vanish simultaneously:  
$$\left. \left( \frac{\partial f}{\partial T_s} \dot{T}_s + \frac{\partial f}{\partial S} \dot{S} \right) \right\vert{}_{\mathcal{C}_{\text{fold}}} = 0$$  
At this location, the linearized matrix of the desingularized flow yields two real eigenvalues $\lambda_1, \lambda_2$with ratio $\mu = \lambda_1 / \lambda_2 < 1$.  
* **The Canard Funnel:** Trajectories passing near this **folded node** enter a rotational sector (a canard funnel) on the 2D surface $\mathcal{M}_0^+$.  
* **Physical Manifestation:** Instead of instantly jumping off the manifold into a burst, the 3D trajectory executes $s = \left\lfloor \frac{1-\mu}{2\mu} \right\rfloor$ **small-amplitude rotational oscillations** (micro-turbulence fluctuations) in $(S, T_s, e)$ space before either returning to the laminar state or firing a full-scale relaxation jump.  
This 3D GSPT system provides the formal mathematical framework for modeling how joint thermo-mechanical adjustments ($S$ and $T_s$ evolving simultaneously) give rise to the pre-burst "whispering" and sub-critical turbulent flurries observed prior to major nocturnal boundary layer transitions.  
