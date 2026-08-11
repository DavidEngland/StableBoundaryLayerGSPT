Here is the breakdown of the four audit items—plus a key variable transformation that eliminates the fractional power singularity in WSINDy during Stage 1.  
## 1. Audit Resolutions: Closure Constants, \Pi_G, and Topology  
**Q1: Closure Constants (c_m, c_w, c_\theta, C_\theta)**  
* **Default Values:** We adopt canonical 1.5-order turbulence closure defaults: c_m \approx 0.10, \quad c_w \approx 0.30, \quad c_\theta \approx 0.20, \quad C_\theta \approx 3.20   
* **Identifiability Strategy:** In **Stages 1 and 2**, these constants are fixed to test exact geometric recovery. In **Stages 3 and 4**, we treat them as a bounded parameter hyper-cube \boldsymbol{\Theta} \subset \mathbb{R}^4. Rather than fitting arbitrary curves, we perform a global Sobol sensitivity analysis to show that varying \boldsymbol{\Theta} within literature bounds (\pm 15\%) shifts the spatial position of \mathcal{C}_{\text{fold}} smoothly without destroying its topology or the validity of the Projection Theorem.  
**Q2: Field Estimation of \Pi_G (CASES-99 vs. SHEBA)**  
We construct \Pi_G = G / R_{\text{net}} directly from flux-tower energy balance instrumentation rather than fitting thermal conductivity k:  
* **CASES-99:** Ground heat flux G at z = 0 is computed from 5 cm heat flux plates (G_5) combined with shallow soil thermistor arrays to account for soil heat storage: G(0) = G(5\text{cm}) + \int_{-0.05}^0 \rho_s c_s \frac{\partial T_g}{\partial t} \, dz With high nocturnal soil moisture, typical observed values yield \Pi_G \approx 0.20\text{--}0.35.  
* **SHEBA:** Net radiation R_{\text{net}} is measured via pyrgeometers, while snow/ice conductive flux G was recorded using multi-level thermistor strings placed through snowpack into sea ice. Due to the high thermal resistance of dry Arctic snowpack (k_{\text{snow}} \approx 0.1\text{ W m}^{-1}\text{K}^{-1}), G remains extremely small relative to radiative loss, yielding \Pi_G \approx 0.02\text{--}0.08.  
**Q3: Bifurcation Structure (Fold vs. Boundary Transcritical)**  
The fast subsystem \mathbf{x}_{\text{fast}} = (e, q_\theta) exhibits two distinct bifurcations in phase space:  
1. **Limit Point / Saddle-Node (\mathcal{C}_{\text{fold}}):** Occurs at e > 0 where \det(J_f) = 0. This is the primary physical collapse locus where the active branch \mathcal{S}_0^+ loses normal hyperbolicity and turns back.  
2. **Limit Point / Saddle-Node (\mathcal{C}_{\text{fold}}):** Occurs at e > 0 where \det(J_f) = 0. This is the primary physical collapse locus where the active branch \mathcal{S}_0^+ loses normal hyperbolicity and turns back.  
3. **Boundary-Transcritical Singularity (e = 0):** At zero TKE, turbulence production and dissipation identically vanish, making e = 0 an invariant boundary line.  
4. **Boundary-Transcritical Singularity (e = 0):** At zero TKE, turbulence production and dissipation identically vanish, making e = 0 an invariant boundary line.  
Trajectories escaping \mathcal{C}_{\text{fold}} jump rapidly down toward the quiescent branch \mathcal{S}_0^-. Near e = e_{\min} \approx 0, the vector field undergoes an exchange of stability with the laminar state. The fold locus \mathcal{C}_{\text{fold}} remains well-separated from the laminar floor e = 0, ensuring normal hyperbolicity is lost *before* the trajectory hits e = 0.  
**Q4: Fast-Slow Hierarchy and Manifold Dimensions**  
The system state is \mathbf{x} = (e, q_\theta, S, T_s, T_g) \in \mathbb{R}^5. The timescale hierarchy \epsilon_1 \ll \epsilon_2 \ll 1 separates the variables into three tiers:  
* **Fast Subsystem (2\text{D}):** \mathbf{x}_{\text{fast}} = (e, q_\theta) with timescales \tau \sim 10^1\text{--}10^2\text{ s}.  
* **Slow Subsystem (2\text{D}):** \mathbf{x}_{\text{slow}} = (S, T_s) with timescales \tau \sim 10^3\text{--}10^4\text{ s}.  
* **Super-Slow Background (1\text{D}):** z_{\text{super}} = T_g with timescale \tau \sim 10^4\text{--}10^5\text{ s}.  
This yields explicit manifold dimensions:  
* **Critical Manifold (\mathcal{S}_0):** A **3D manifold** embedded in \mathbb{R}^5, defined by \{ (e, q_\theta, S, T_s, T_g) \in \mathbb{R}^5 \mid F = 0, H = 0 \}.  
* **Fold Hyper-Surface (\mathcal{C}_{\text{fold}}):** A **2D surface** embedded in \mathcal{S}_0, defined by \{ \mathbf{x} \in \mathcal{S}_0 \mid \det(J_f) = 0 \}.  
## 2. Technical Fix for WSINDy: The Variable Transformation  
The presence of non-polynomial terms like e^{-1/2}, e^{1/2}, and e^{3/2} in the governing fast equations degrades sparse regression in WSINDy if evaluated directly in e-coordinates.  
To guarantee convergence in Stage 1 and Stage 2, we apply the state transformation:  
```
\tilde{e} = \sqrt{e} \implies e = \tilde{e}^2, \quad \frac{de}{dt} = 2\tilde{e} \frac{d\tilde{e}}{dt}

```
Substituting \tilde{e} into the fast system yields:  
\epsilon_e \frac{d\tilde{e}}{dt} = \frac{1}{2} c_m \ell S^2 - \frac{g}{2\theta_0} \left( \frac{q_\theta}{\tilde{e}} \right) - \frac{\tilde{e}^2}{2\ell} \epsilon_q \frac{dq_\theta}{dt} = - c_w \tilde{e}^2 \left(\frac{\partial \theta}{\partial z}\right) - \frac{g}{\theta_0} c_\theta \ell \left( \frac{q_\theta^2}{\tilde{e}} \right) - \frac{C_\theta}{\ell} \tilde{e} q_\theta  
\epsilon_e \frac{d\tilde{e}}{dt} = \frac{1}{2} c_m \ell S^2 - \frac{g}{2\theta_0} \left( \frac{q_\theta}{\tilde{e}} \right) - \frac{\tilde{e}^2}{2\ell} \epsilon_q \frac{dq_\theta}{dt} = - c_w \tilde{e}^2 \left(\frac{\partial \theta}{\partial z}\right) - \frac{g}{\theta_0} c_\theta \ell \left( \frac{q_\theta^2}{\tilde{e}} \right) - \frac{C_\theta}{\ell} \tilde{e} q_\theta  
Multiplying through by \tilde{e} converts the system into exact polynomial form in the state vector (\tilde{e}, q_\theta):  
\epsilon_e \tilde{e} \frac{d\tilde{e}}{dt} = \frac{1}{2} c_m \ell S^2 \tilde{e} - \frac{g}{2\theta_0} q_\theta - \frac{\tilde{e}^3}{2\ell} \epsilon_q \tilde{e} \frac{dq_\theta}{dt} = - c_w \tilde{e}^3 \left(\frac{\partial \theta}{\partial z}\right) - \frac{g}{\theta_0} c_\theta \ell q_\theta^2 - \frac{C_\theta}{\ell} \tilde{e}^2 q_\theta  
\epsilon_e \tilde{e} \frac{d\tilde{e}}{dt} = \frac{1}{2} c_m \ell S^2 \tilde{e} - \frac{g}{2\theta_0} q_\theta - \frac{\tilde{e}^3}{2\ell} \epsilon_q \tilde{e} \frac{dq_\theta}{dt} = - c_w \tilde{e}^3 \left(\frac{\partial \theta}{\partial z}\right) - \frac{g}{\theta_0} c_\theta \ell q_\theta^2 - \frac{C_\theta}{\ell} \tilde{e}^2 q_\theta  
In this coordinate system, the candidate feature library for WSINDy consists purely of low-degree monomial terms \{\tilde{e}, q_\theta, \tilde{e}^2, \tilde{e} q_\theta, q_\theta^2, \tilde{e}^3, S^2 \tilde{e}\}, completely avoiding fractional power singularities and conditioning issues during numerical inversion.  
Would you like to start drafting the explicit mathematical proof of the Projection Theorem, or shall we map out the WSINDy library formulation and test scripts in Julia?  
