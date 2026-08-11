The **GSPT-SBL framework** is a mathematically rigorous 4D (or reduced 2D) **fast–slow dynamical system** that models the nocturnal Stable Boundary Layer (SBL). By applying **Geometric Singular Perturbation Theory (GSPT)**, the model replaces heuristic algebraic switching rules with explicit manifold geometry to capture sudden, "catastrophic" shifts in atmospheric stability, such as the abrupt extinction of turbulence at sunset.  
## 1. System Structure and Timescale Separation  
The framework decomposes the boundary layer into a multi-timescale hierarchy governed by a small parameter **$\epsilon \ll 1$**, representing the ratio between fast and slow processes.  
* **Fast Subsystem (TKE, $e$):** The relaxation of Turbulent Kinetic Energy, adjusting to local forces in seconds to minutes.  
* **Slow Subsystem ($U, V, T_s$):** The evolution of horizontal winds and surface skin temperature, which respond over hours to geostrophic forcing and radiative cooling.  
## 2. The Geometric Manifold and Fold Catastrophe  
The behavior of the SBL is organized by a **critical manifold ($S_0$)**, an S-shaped (folded) equilibrium surface where fast TKE is in balance with slow variables.  
* **Active vs. Laminar Branches:** The manifold features an attracting "active" turbulent sheet and a "laminar" floor ($e \approx 0$).  
* **Runaway Surface Cooling:** When radiative loss outpaces the heat supply from turbulence, the system reaches a **fold knee ($\mathcal{C}_{\text{fold}}$)** where normal hyperbolicity is lost. The trajectory must then execute a rapid, deterministic **fast jump** down to the laminar branch, resulting in thermal decoupling.  
* **Turbulent Breakout:** Recovery occurs via a **transcritical activation threshold**. As wind shear builds aloft (forming a Low-Level Jet), the system crosses a point where the laminar branch becomes repelling, triggering an explosive TKE burst.  
## 3. Reconceptualizing the Richardson Number ($Ri_b$)  
A primary contribution of GSPT-SBL is the redefinition of the **Bulk Richardson number** from a static universal constant ($Ri_c \approx 0.25$) into a **dynamic diagnostic coordinate**.  
* **State-Dependent Thresholds:** The collapse threshold ($Ri_{\text{fold}}$) is not a fixed number but a function of the slowly evolving surface temperature ($T_s$). As surface inversions deepen, the "fold knee" deforms, continuously shifting the value of $Ri_b$ required to trigger a collapse.  
* **Resolving Observational "Scatter":** This geometric evolution provides a deterministic explanation for why field campaigns like **CASES-99 and SHEBA** report collapse points ranging from $Ri_b \approx 0.2$ to over $1.2$—it is the signature of a moving fold boundary rather than measurement error.  
## 4. Mathematical and Numerical Regularization  
To bridge the gap between theory and Numerical Weather Prediction (NWP), the framework implements several **regularization "safeguards"**:  
* **Safeguard Gating:** A smooth **activation gate ($\Psi$)** and a background TKE floor ($\delta$) ensure the state space remains forward-invariant, preventing solver crashes or unphysical complex values during turbulence collapse.  
* **Fold Invariant ($\Delta$):** To resolve the non-uniqueness of the dimensionless Richardson number, the framework utilizes a dimensional invariant ($\Delta$) that preserves the absolute competition between mechanical production and buoyant destruction.  
* **Master Mixing Length ($l_0$):** In this framework, $l_0$ is promoted to a **codimension-one bifurcation parameter** that dictates the energy level at which the boundary layer structurally decouples.  
## 5. Universal Taxonomy  
The GSPT-SBL framework demonstrates that the sudden transitions in Earth's atmosphere are mathematically identical to phenomena in other fields. For example, the **"runaway surface cooling"** of the SBL is the thermodynamic equivalent of the **"canard explosion"** seen in astrophysical outgassing (Sal'nikov model) or the rapid firing of a neuron's action potential (Hodgkin-Huxley model).  
