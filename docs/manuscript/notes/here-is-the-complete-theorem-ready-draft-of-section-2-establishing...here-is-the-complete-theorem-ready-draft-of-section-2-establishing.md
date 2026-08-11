Here is the complete, theorem-ready draft of **Section 2**, establishing the state vector, chart regularizations, decomposed fast-slow vector fields, and diagnostic observation operators.  
## 2. Governing Equations, Chart Regularization, and Diagnostic Functionals  
To establish a mathematically rigorous foundation for the Stable Boundary Layer (SBL) fast-slow hierarchy, this section defines the physical state vector, domain constraints, timescale separation, chart desingularization, and diagnostic observation mappings.  
**2.1 State Vector, Domains, and Timescale Hierarchy**  
We consider an open chart domain \Omega_0 \subset \mathbb{R}^5 representing the thermodynamic and mechanical state of a single-column boundary layer coupled to a subsurface soil reservoir. The system state is defined by the state vector \mathbf{x} \in \Omega_0:  
```
\mathbf{x} = \begin{pmatrix} \tilde{e} \\ q_\theta \\ S \\ T_s \\ T_g \end{pmatrix} \in \Omega_0 \subset \mathbb{R}_+ \times \mathbb{R} \times \mathbb{R}_+ \times \mathbb{R}_+ \times \mathbb{R}_+

```
where:  
* \tilde{e} \in \mathbb{R}_+ is the desingularized chart Turbulent Kinetic Energy (TKE),  
* q_\theta \in \mathbb{R} is the kinematic turbulent heat flux (\overline{w'\theta'}),  
* S \in \mathbb{R}_+ is the bulk vertical wind shear (\Vert{}\partial \mathbf{u} / \partial z\Vert{}),  
* T_s \in \mathbb{R}_+ is the surface skin temperature, and  
* T_g \in \mathbb{R}_+ is the deep soil temperature.  
**Parameter Space and Regularity**  
The system is parameterized by a vector of physical closure constants and soil properties \boldsymbol{\mu} \in \mathcal{P} \subset \mathbb{R}^k, where \mathcal{P} is an open parameter domain containing positive closure constants (c_m, c_w, c_\theta, C_\theta, \ell, C_s, k_g, d_g, \rho, c_p, g, \theta_0). All physical parameters are assumed to be bounded and smooth (C^\infty).  
**Timescale Separation**  
The physics of the nocturnal boundary layer naturally partitioned into three distinct temporal scales governed by two non-dimensional scale ratios 0 < \epsilon_1 \ll \epsilon_2 \ll 1:  
1. **Fast Scale (\tau \sim O(1)):** Turbulent adjustment of TKE (\tilde{e}) and non-equilibrium heat flux (q_\theta), operating on sub-minute timescales (\tau_{\text{fast}} \approx 10^1\text{--}10^2\text{ s}).  
2. **Slow Scale (t = \epsilon_1 \tau \sim O(\epsilon_1^{-1})):** Environmental forcing of vertical shear (S) via geostrophic pressure gradients and surface thermal evolution (T_s) via radiative cooling (\tau_{\text{slow}} \approx 10^3\text{--}10^4\text{ s}).  
3. **Super-Slow Scale (t_g = \epsilon_2 t = \epsilon_1 \epsilon_2 \tau):** Conductive heat diffusion through the subsurface soil column (T_g) (\tau_{\text{superslow}} \approx 10^4\text{--}10^5\text{ s}).  
**2.2 Fast-Manifold Chart Regularization and Desingularization**  
In classical turbulent boundary layer formulations, the fast equations for TKE e contain non-smooth fractional powers (e.g., shear production K_m(e) S^2 = c_m \ell e^{1/2} S^2 and Kolmogorov dissipation \epsilon_D = e^{3/2}/\ell). As turbulence quenches (e \to 0), the vector field loses C^1 smoothness, preventing the direct application of standard Geometric Singular Perturbation Theory (GSPT) and Fenichel persistence theorems.  
To resolve this singularity, we apply a smooth chart map \phi_\delta: \mathbb{R}_{\ge 0} \to \mathbb{R}_{\ge 0} defined by:  
```
\tilde{e} = \sqrt{e + \delta}, \quad \delta \ge 0

```
Under the active chart (\delta \to 0^+ for e > 0), we introduce a fast state-dependent time rescaling:  
```
d\tau = \left( \frac{\tilde{e}}{\epsilon_1} \right) dt

```
The mathematical properties and validity of this transformation are formalized below.  
**Proposition 2.1 (Regularized Fast System)**  
*Let \mathbf{x} \in \Omega_0. Under the coordinate chart map \tilde{e} = \sqrt{e + \delta} and the fast time-rescaling d\tau = \frac{\tilde{e}}{\epsilon_1} dt, the fast subsystem extends to a smooth C^\infty(\Omega_0, \mathbb{R}^2) vector field across the laminar boundary \tilde{e} \to 0, preserving all equilibrium sets and normal hyperbolicity away from the fold locus.*  
*Proof.* In original e coordinates, the fast TKE equation is:  
```
\epsilon_1 \frac{de}{dt} = c_m \ell e^{1/2} S^2 - \frac{g}{\theta_0} q_\theta - \frac{1}{\ell} e^{3/2}

```
Differentiating \tilde{e}^2 = e + \delta yields 2 \tilde{e} \frac{d\tilde{e}}{dt} = \frac{de}{dt}. Substituting into the rescaled fast time derivative \frac{d\tilde{e}}{d\tau} = \frac{\epsilon_1}{\tilde{e}} \frac{d\tilde{e}}{dt} gives:  
```
\frac{d\tilde{e}}{d\tau} = \frac{\epsilon_1}{2 \tilde{e}^2} \frac{de}{dt} = \frac{1}{2 \tilde{e}^2} \left( c_m \ell \sqrt{\tilde{e}^2 - \delta} \, S^2 - \frac{g}{\theta_0} q_\theta - \frac{1}{\ell} (\tilde{e}^2 - \delta)^{3/2} \right)

```
Taking the regularized limit \delta \to 0^+ yields:  
```
\frac{d\tilde{e}}{d\tau} = \frac{1}{2 \tilde{e}^2} \left( c_m \ell \tilde{e} S^2 - \frac{g}{\theta_0} q_\theta - \frac{1}{\ell} \tilde{e}^3 \right) = \frac{1}{2} c_m \ell S^2 \tilde{e} - \frac{g}{2\theta_0} q_\theta - \frac{1}{2\ell} \tilde{e}^3

```
The fractional power terms e^{1/2} and e^{3/2} are transformed into smooth polynomial terms \tilde{e} and \tilde{e}^3. Consequently, the right-hand side is C^\infty smooth on \Omega_0. Because time rescaling is a positive strictly monotonic transformation for \tilde{e} > 0, the topology of phase trajectories, equilibrium sets (\frac{d\tilde{e}}{d\tau} = 0), and spectral stability signs are strictly preserved. \square  
**2.3 Decomposed Fast-Slow Vector Field**  
Using the regularized chart coordinate \tilde{e} and fast time scale \tau, the full 5D dynamical system is expressed as a smooth autonomous vector field \mathbf{F}: \Omega_0 \times \mathcal{P} \times \mathbb{R}_+^2 \to \mathbb{R}^5:  
```
\frac{d\mathbf{x}}{d\tau} = \mathbf{F}(\mathbf{x}; \boldsymbol{\mu}, \epsilon_1, \epsilon_2) \equiv \begin{pmatrix} F_{\text{fast}}(\mathbf{x}; \boldsymbol{\mu}) \\ \epsilon_1 F_{\text{slow}}(\mathbf{x}; \boldsymbol{\mu}) \\ \epsilon_1 \epsilon_2 F_{\text{superslow}}(\mathbf{x}; \boldsymbol{\mu}) \end{pmatrix}

```
**Fast Vector Field (F_{\text{fast}}: \Omega_0 \to \mathbb{R}^2)**  
The fast subsystem governs turbulent kinetic energy and non-equilibrium kinematic heat flux:  
```
F_{\text{fast}}(\mathbf{x}; \boldsymbol{\mu}) = \begin{pmatrix} \tilde{F}(\mathbf{x}) \\ \tilde{H}(\mathbf{x}) \end{pmatrix} = \begin{pmatrix} \frac{1}{2} c_m \ell S^2 \tilde{e} - \frac{g}{2\theta_0} q_\theta - \frac{1}{2\ell} \tilde{e}^3 \\ - c_w \theta_z(T_s) \tilde{e}^3 - \frac{g}{\theta_0} c_\theta \ell q_\theta^2 - \frac{C_\theta}{\ell} \tilde{e}^2 q_\theta \end{pmatrix}

```
where local stratification \theta_z(T_s) = \frac{\partial \theta}{\partial z}(T_s) = \frac{\theta_{\text{top}} - \Pi_s T_s}{\Delta z} is a smooth diagnostic function slaved to surface skin temperature.  
**Slow Vector Field (F_{\text{slow}}: \Omega_0 \to \mathbb{R}^2)**  
The slow subsystem governs momentum shear evolution and surface skin thermodynamics:  
```
F_{\text{slow}}(\mathbf{x}; \boldsymbol{\mu}) = \begin{pmatrix} F_S(\mathbf{x}) \\ F_{T_s}(\mathbf{x}) \end{pmatrix} = \begin{pmatrix} \frac{1}{\tilde{e}} \left[ \mathcal{F}_{\text{ls}} - \frac{\partial}{\partial z}\left( c_m \ell \tilde{e} S \right) \right] \\ \frac{1}{\tilde{e} C_s} \left[ R_{\text{net}}(T_s) + \rho c_p q_\theta + \frac{k_g}{d_g}(T_g - T_s) \right] \end{pmatrix}

```
where R_{\text{net}}(T_s) = R_{\text{sw}}^{\downarrow} + \epsilon_a \sigma T_a^4 - \epsilon_s \sigma T_s^4 represents net surface radiation.  
**Super-Slow Vector Field (F_{\text{superslow}}: \Omega_0 \to \mathbb{R}^1)**  
The super-slow component models subsurface ground conduction:  
```
F_{\text{superslow}}(\mathbf{x}; \boldsymbol{\mu}) = F_{T_g}(\mathbf{x}) = \frac{1}{\tilde{e}} \frac{\kappa_g}{d_g^2} \left( T_s - T_g \right)

```
**2.4 Observation Operators and Diagnostic Functionals**  
Field campaigns and numerical weather prediction models do not observe the internal fast-slow state vector \mathbf{x} \in \Omega_0 directly. Instead, physical measurements are extracted via smooth observation operators mapping state space to an observational manifold \mathcal{O} \subset \mathbb{R}^m.  
We define the primary observation mapping \boldsymbol{\Pi}_{\text{obs}}: \Omega_0 \to \mathcal{O} as:  
```
\boldsymbol{\Pi}_{\text{obs}}(\mathbf{x}) = \begin{pmatrix} \pi_{Ri}(\mathbf{x}) \\ \pi_H(\mathbf{x}) \\ \pi_S(\mathbf{x}) \end{pmatrix} = \begin{pmatrix} \frac{g}{\theta_0} \frac{\theta_z(T_s)}{S^2} \\ \rho c_p q_\theta \\ S \end{pmatrix}

```
**The Gradient Richardson Operator \pi_{Ri}**  
The central observational functional analyzed in this work is the Gradient Richardson diagnostic mapping \pi_{Ri}: \Omega_0 \to \mathbb{R}_+. In differential covector notation, its gradient D\pi_{Ri}(\mathbf{x}) \in T_{\mathbf{x}}^* \Omega_0 is given by:  
```
D\pi_{Ri}(\mathbf{x}) = 0\,d\tilde{e} + 0\,dq_\theta - \left(\frac{2 g \theta_z(T_s)}{\theta_0 S^3}\right) dS + \left(\frac{g}{\theta_0 S^2} \frac{\partial \theta_z}{\partial T_s}\right) dT_s + 0\,dT_g

```
Note that D\pi_{Ri} lies entirely in the subspace spanned by the slow differentials \{dS, dT_s\}, establishing a key structural property: **the diagnostic operator \pi_{Ri} is orthogonal to the fast turbulent coordinates (\tilde{e}, q_\theta)**.  
**Dependency Alignment**  
With Section 2 formally defined, every downstream object now possesses a precise mathematical definition:  
```
\begin{aligned} \text{Critical Manifold } \mathcal{S}_0 &\equiv \left\{ \mathbf{x} \in \Omega_0 \,\,\big\vert{}\,\, F_{\text{fast}}(\mathbf{x}) = \mathbf{0} \right\} \\ \text{Fold Locus } \mathcal{C}_{\text{fold}} &\equiv \left\{ \mathbf{x} \in \mathcal{S}_0 \,\,\big\vert{}\,\, \det \left( D_{\mathbf{x}_{\text{fast}}} F_{\text{fast}}(\mathbf{x}) \right) = 0 \right\} \\ \text{Observed Threshold } Ri_{\text{fold}} &\equiv \pi_{Ri}\left( \mathcal{C}_{\text{fold}} \cap \Sigma_{\text{site}} \right) \end{aligned}

```
How would you like to proceed: review this Section 2 draft for any final mathematical polishing, or move directly to drafting Section 3 (The Critical Manifold \mathcal{S}_0 and Theorems 1–2)?  
