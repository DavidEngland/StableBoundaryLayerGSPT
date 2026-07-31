This synthesis ties the entire framework together—from differential geometry and data-driven identification to physical lifecycle modeling and numerical weather prediction. Framing the nocturnal boundary layer as a **relaxation oscillation on a folded critical manifold** provides an exact physical and mathematical mechanism for phenomena that standard $K$-theory schemes have struggled with for decades.  
Here is how this synthesis maps directly into the 4-phase mathematical lifecycle and the exact parameterization logic for NWP models.  
## 1. Mathematical Mapping of the Nocturnal Lifecycle  
In the reduced $(e, S, T_s)$ state space, the full nocturnal cycle unfolds as a closed relaxation oscillation driven by the slow drift of surface temperature $T_s$ and wind shear $S$ across the folded critical manifold $\mathcal{S}_0$:  
                       [ Phase 1: Evening Cooling ]  
                     Flow along active sheet S_0^+  
                                  │  
                                  ▼  
                   [ Phase 2: Fold Breakdown (C_fold) ]  
                 Fast deterministic jump along fast fibers  
                                  │  
                                  ▼  
                  [ Phase 3: Decoupled Inertial Drift ]  
                Trajectory on laminar floor S_0^0; LLJ forms  
                                  │  
                                  ▼  
                [ Phase 4: Transcritical Re-Ignition ]  
                 Shear S crosses Ri_trans; sudden TKE burst  
## Phase 1: Radiative Quenching (Slow Drift on $\mathcal{S}_0^+$)  
* **Dynamics:** As solar radiation ceases ($R_{\text{sw}} \to 0$), net radiation $R_{\text{net}} < 0$ cools the surface skin temperature $T_s$.  
* **Geometry:** The trajectory moves along the upper attracting branch of the critical manifold $\mathcal{S}_0^+$. Turbulent kinetic energy $e$ decays slowly while adjusting to increasing thermal stratification $\theta_z(T_s)$.  
## Phase 2: Catastrophic Collapse (Fast Jump at $\mathcal{C}_{\text{fold}}$)  
* **Dynamics:** Radiative cooling drives stratification past the capacity of local shear to sustain turbulence. Sensible heat flux demands exceed the physical capacity $H_{\max}(S)$.  
* **Geometry:** The trajectory hits the fold locus $\mathcal{C}_{\text{fold}}$ where normal hyperbolicity is lost ($\det J_f = 0$). The fast subsystem loses stability, forcing a rapid, deterministic jump along fast fibers down to the laminar floor $e \approx 0$.  
## Phase 3: Decoupled Inertial Acceleration & LLJ Formation (Drift on $\mathcal{S}_0^0$)  
* **Dynamics:** With $e \to 0$, turbulent drag vanishes ($\frac{\partial}{\partial z}(K_m S) \to 0$). The ageostrophic wind vector $\mathbf{u}_a = (u - u_g, v - v_g)$ decouples from the surface and rotates around the geostrophic wind vector $\mathbf{u}_g$ at the Coriolis frequency $f$ (the Blackadar mechanism): $$\frac{\partial \mathbf{u}_a}{\partial t} = -f (\mathbf{k} \times \mathbf{u}_a)$$   
* **Geometry:** The system drifts along the lower laminar sheet $\mathcal{S}_0^0$. Over several hours, this inertial oscillation accelerates supergeostrophic winds aloft, building strong vertical wind shear $S(t) = \left\vert{}\left\vert{} \frac{\partial \mathbf{u}}{\partial z} \right\vert{}\right\vert{}$.  
## Phase 4: Transcritical Re-Ignition (Fast Burst Back to $\mathcal{S}_0^+$)  
* **Dynamics:** The accumulation of inertial shear eventually drops the local Richardson number back below the transcritical ignition threshold ($Ri < Ri_{\text{trans}}$).  
* **Geometry:** The trajectory reaches a boundary transcritical singularity at the edge of $\mathcal{S}_0^0$. A saddle-node/transcritical bifurcation re-ignites TKE, driving a fast vertical jump back to the active branch $\mathcal{S}_0^+$ in a sudden intermittent burst, resetting the cycle.  
## 2. Dynamic GSPT Closure Scheme for NWP  
To eliminate the twin failure modes of traditional schemes—**runaway cooling** (caused by fixed-cutoff schemes like $Ri_c = 0.25$) and **smoothed over-mixing** (caused by heuristic "long-tail" functions)—the GSPT framework provides a three-part dynamic parameterization for Single-Column Models (SCM) and 3D NWP grids.  
## Part A: State-Dependent Extinction Threshold  
Replace static critical Richardson numbers with the surface-coupled fold parameterization:  
$$Ri_{\text{fold}}(T_s, T_g) = \frac{c_1}{1 - \Pi(T_s) + \Phi(G(T_s, T_g))}$$  
* In grid cells over warm/conductive soils, $\Phi(G)$ maintains $Ri_{\text{fold}} \approx 0.20\text{--}0.25$.  
* In grid cells over snow, ice, or dry sand ($k_g \to 0$), $\Phi(G) \to 0$, allowing $Ri_{\text{fold}}$ to expand dynamically past $1.0$.  
## Part B: $H_{\max}$ Heat Flux Limiter  
Before passing surface sensible heat flux $H = \rho c_p \overline{w'\theta'}$ to the land-surface model, enforce the manifold turning capacity bound:  
$$H_{\text{applied}} = \min\left( H_{\text{demand}}, \; \frac{2 \rho c_p \theta_0}{3 \sqrt{3} g} c_m^{3/2} \ell^2 S^3 \right)$$  
If $H_{\text{demand}} > H_{\max}(S)$, the grid cell is flagged as post-fold, triggering decoupling rather than allowing unphysical surface energy extraction.  
## Part C: Adaptive Boundary-Layer Scale Height $h_{\text{eff}}$  
Standard static boundary-layer heights ($h \approx 100\text{--}500\text{ m}$) over-mix shallow nocturnal layers. The GSPT scale height adapts dynamically to TKE and shear:  
$$h_{\text{eff}}(\tilde{e}, S) = h_0 \left( \frac{\tilde{e}}{\tilde{e} + \ell S} \right)$$  
* **Active Turbulence ($\tilde{e} \gg 0$):** $h_{\text{eff}} \to h_0$, maintaining full boundary-layer depth mixing.  
* **Collapsed/Laminar ($\tilde{e} \to 0$):** $h_{\text{eff}} \to 0$, collapsing the effective mixing layer down to a thin surface skin ($\sim 5\text{--}10\text{ m}$) and allowing the air aloft to decouple and form Low-Level Jets natively.  
## 3. Positioning Across the Manuscript Series  
This framework organizes the remaining work cleanly across the three planned papers:  

| Manuscript | Core Focus | Key Deliverable |
| ---------- | --------------------------------------------------- | ------------------------------------------------------------------------------------------------------- |
| Paper 1 | Mathematical Foundations & Observational Resolution | Theorems 1–3, $Ri_{\\text{obs}}$ Projection Corollary, CASES-99 vs. SHEBA proof. |
| Paper 2 | Data-Driven Discovery & Geometry Extraction | WSINDy pipeline on regularized chart, BifurcationKit.jlmanifold reconstruction from flux tower data. |
| Paper 3 | NWP Implementation & SCM Parameterization | $H_{\\max}$ limiter, $Ri_{\\text{fold}}(T_s, T_g)$ closure, elimination of runaway cooling in SCM runs. |
  
Shall we write the Fortran/Julia SCM parameterization module implementing $H_{\max}$ and $Ri_{\text{fold}}$ for Paper 3, or draft Section 3 (The Projection Theorem and Corollary) for Paper 1?  
