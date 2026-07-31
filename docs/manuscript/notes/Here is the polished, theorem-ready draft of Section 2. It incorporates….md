Here is the polished, theorem-ready draft of **Section 2**. It incorporates abstract system-first definitions, explicit standing assumptions, refined GSPT proposition language, clarified regularization limits, updated diagnostic functional terminology, and the addition of Proposition 2.2 (Observation Smoothness).  
## 2. Governing Equations, Chart Regularization, and Diagnostic Functionals  
This section establishes the mathematical architecture of the Stable Boundary Layer (SBL) fast-slow hierarchy. We define the regularized state space, establish standing assumptions for smoothness and domain invariance, perform fast-manifold desingularization, and construct the diagnostic observation mapping that links invariant manifold geometry to atmospheric observables.  
**2.1 System Definition and Standing Assumptions**  
We consider a multiscale autonomous dynamical system defined on an open chart domain \Omega_0 \subset \mathbb{R}^5:  
```
\frac{d\mathbf{x}}{d\tau} = \mathbf{F}(\mathbf{x}; \boldsymbol{\mu}, \epsilon_1, \epsilon_2) \equiv \begin{pmatrix} F_{\text{fast}}(\mathbf{x}; \boldsymbol{\mu}) \\ \epsilon_1 F_{\text{slow}}(\mathbf{x}; \boldsymbol{\mu}) \\ \epsilon_1 \epsilon_2 F_{\text{superslow}}(\mathbf{x}; \boldsymbol{\mu}) \end{pmatrix}

```
where \mathbf{x} \in \Omega_0 is the state vector representing the coupled atmosphere-land-surface system:  
```
\mathbf{x} = \begin{pmatrix} \tilde{e} \\ q_\theta \\ S \\ T_s \\ T_g \end{pmatrix} \in \Omega_0 \subset \mathbb{R}_+ \times \mathbb{R} \times \mathbb{R}_+ \times \mathbb{R}_+ \times \mathbb{R}_+

```
The components of \mathbf{x} comprise:  
* \tilde{e} \in \mathbb{R}_+: desingularized chart Turbulent Kinetic Energy (TKE),  
* q_\theta \in \mathbb{R}: kinematic turbulent heat flux (\overline{w'\theta'}),  
* S \in \mathbb{R}_+: bulk vertical wind shear (\Vert{}\partial \mathbf{u} / \partial z\Vert{}),  
* T_s \in \mathbb{R}_+: surface skin temperature, and  
* T_g \in \mathbb{R}_+: deep soil temperature.  
**Standing Assumptions**  
Throughout this paper, the following geometric and analytical conditions are assumed:  
* **(A1) Domain Openness & Regularity:** The chart domain \Omega_0 \subset \mathbb{R}^5 is open and connected. The vector field \mathbf{F}: \Omega_0 \times \mathcal{P} \times \mathbb{R}_+^2 \to \mathbb{R}^5 is of class C^\infty on \Omega_0.  
* **(A2) Parameter Space:** The parameter vector \boldsymbol{\mu} = (c_m, c_w, c_\theta, C_\theta, \ell, C_s, k_g, d_g, \rho, c_p, g, \theta_0)^T belongs to an open, bounded parameter domain \mathcal{P} \subset \mathbb{R}_+^{13} containing strictly positive physical constants.  
* **(A3) Positive Invariance:** The physically admissible domain \Omega_{\text{phys}} = \{\mathbf{x} \in \Omega_0 \mid \tilde{e} > 0, S > 0, T_s > 0, T_g > 0\} is positively invariant under the flow of \mathbf{F}.  
* **(A4) Existence and Uniqueness:** For every initial condition \mathbf{x}(0) \in \Omega_0, there exists a unique local trajectory \mathbf{x}(\tau) defined on an interval I \subseteq \mathbb{R}.  
* **(A5) Timescale Hierarchy:** The perturbation parameters satisfy 0 < \epsilon_1 \ll \epsilon_2 \ll 1, defining a strict separation between fast turbulent relaxation (\tau \sim O(1)), slow atmospheric and surface thermal drift (t = \epsilon_1 \tau \sim O(\epsilon_1^{-1})), and super-slow subsurface soil heat conduction (t_g = \epsilon_1 \epsilon_2 \tau).  
**2.2 Chart Regularization and Desingularization**  
In classical formulations, fast turbulent equations for TKE e contain non-smooth fractional exponents ( shear production K_m(e) S^2 = c_m \ell e^{1/2} S^2 and Kolmogorov dissipation \epsilon_D = e^{3/2}/\ell). As turbulence quenches (e \to 0), the vector field loses C^1 differentiability at the laminar boundary.  
To restore smoothness, we apply the coordinate transformation \phi_\delta: \mathbb{R}_{\ge 0} \to \mathbb{R}_{\ge 0}:  
```
\tilde{e} = \sqrt{e + \delta}

```
where \delta > 0 is a fixed regularization parameter used to construct a smooth coordinate chart. All geometric submanifolds and vector fields are established on this regularized chart and analyzed in the limit \delta \to 0^+. Combined with the chart transformation, we define a fast, state-dependent time reparameterization:  
```
d\tau = \left( \frac{\tilde{e}}{\epsilon_1} \right) dt

```
**Proposition 2.1 (Regularization and Diffeomorphic Equivalence)**  
*On the open physical domain e > 0, the chart map \phi_\delta is a C^\infty diffeomorphism onto its image. Under the positive time reparameterization d\tau = \frac{\tilde{e}}{\epsilon_1} dt, the fast subsystem extends to a smooth C^\infty(\Omega_0, \mathbb{R}^2) vector field across \tilde{e} \to 0, preserving phase trajectories, equilibrium sets, and the signs of transverse eigenvalues along the critical manifold.*  
*Proof.* For \delta > 0 and e > 0, \phi_\delta(e) = \sqrt{e + \delta} is smooth with strictly positive derivative \phi_\delta'(e) = \frac{1}{2\sqrt{e+\delta}} > 0, making it a smooth diffeomorphism. In physical coordinates e, the fast TKE equation is \epsilon_1 \frac{de}{dt} = c_m \ell e^{1/2} S^2 - \frac{g}{\theta_0} q_\theta - \frac{1}{\ell} e^{3/2}.  
Differentiating \tilde{e}^2 = e + \delta and applying the time scale \frac{d\tilde{e}}{d\tau} = \frac{\epsilon_1}{\tilde{e}} \frac{d\tilde{e}}{dt} = \frac{\epsilon_1}{2\tilde{e}^2} \frac{de}{dt} yields:  
```
\frac{d\tilde{e}}{d\tau} = \frac{1}{2\tilde{e}^2} \left( c_m \ell \sqrt{\tilde{e}^2 - \delta} \, S^2 - \frac{g}{\theta_0} q_\theta - \frac{1}{\ell} (\tilde{e}^2 - \delta)^{3/2} \right)

```
Evaluating in the limit \delta \to 0^+ gives:  
```
\frac{d\tilde{e}}{d\tau} = \frac{1}{2} c_m \ell S^2 \tilde{e} - \frac{g}{2\theta_0} q_\theta - \frac{1}{2\ell} \tilde{e}^3

```
The right-hand side is a smooth polynomial in \tilde{e} on \Omega_0. Because \frac{d\tau}{dt} = \frac{\tilde{e}}{\epsilon_1} > 0 is strictly positive for all \tilde{e} > 0, the reparameterization is a smooth orientation-preserving time change. It follows from standard dynamical systems theory that orbits, fixed points (\frac{d\tilde{e}}{d\tau} = 0), and signs of linearized eigenvalues transverse to the equilibrium set are preserved. \square  
**2.3 Subsystem Vector Field Components**  
Under Assumption (A1) and Proposition 2.1, the components of the full vector field \mathbf{F}(\mathbf{x}; \boldsymbol{\mu}, \epsilon_1, \epsilon_2) are defined explicitly as follows.  
**Fast Subsystem Vector Field (F_{\text{fast}}: \Omega_0 \to \mathbb{R}^2)**  
The fast subsystem F_{\text{fast}}(\mathbf{x}) = (\tilde{F}(\mathbf{x}), \tilde{H}(\mathbf{x}))^T governs fast turbulent relaxation:  
```
F_{\text{fast}}(\mathbf{x}) = \begin{pmatrix} \frac{1}{2} c_m \ell S^2 \tilde{e} - \frac{g}{2\theta_0} q_\theta - \frac{1}{2\ell} \tilde{e}^3 \\ - c_w \theta_z(T_s) \tilde{e}^3 - \frac{g}{\theta_0} c_\theta \ell q_\theta^2 - \frac{C_\theta}{\ell} \tilde{e}^2 q_\theta \end{pmatrix}

```
where local thermal stratification \theta_z(T_s) = \frac{\partial \theta}{\partial z}(T_s) = \frac{\theta_{\text{top}} - \Pi_s T_s}{\Delta z} is a smooth diagnostic function slaved to skin temperature.  
**Slow Subsystem Vector Field (F_{\text{slow}}: \Omega_0 \to \mathbb{R}^2)**  
The slow subsystem F_{\text{slow}}(\mathbf{x}) = (F_S(\mathbf{x}), F_{T_s}(\mathbf{x}))^T governs wind shear and skin temperature evolution:  
```
F_{\text{slow}}(\mathbf{x}) = \begin{pmatrix} \frac{1}{\tilde{e}} \left[ \mathcal{F}_{\text{ls}} - \frac{\partial}{\partial z}\left( c_m \ell \tilde{e} S \right) \right] \\ \frac{1}{\tilde{e} C_s} \left[ R_{\text{net}}(T_s) + \rho c_p q_\theta + \frac{k_g}{d_g}(T_g - T_s) \right] \end{pmatrix}

```
where R_{\text{net}}(T_s) = R_{\text{sw}}^{\downarrow} + \epsilon_a \sigma T_a^4 - \epsilon_s \sigma T_s^4 is net surface radiation.  
**Super-Slow Subsystem Vector Field (F_{\text{superslow}}: \Omega_0 \to \mathbb{R}^1)**  
The super-slow subsystem F_{\text{superslow}}(\mathbf{x}) = F_{T_g}(\mathbf{x}) governs subsurface ground heat conduction:  
```
F_{\text{superslow}}(\mathbf{x}) = \frac{1}{\tilde{e}} \frac{\kappa_g}{d_g^2} \left( T_s - T_g \right)

```
**2.4 Observation Mapping and Diagnostic Functionals**  
To link the high-dimensional internal state \mathbf{x} \in \Omega_0 to observational data, we introduce a smooth observation mapping \boldsymbol{\Pi}_{\text{obs}}: \Omega_0 \to \mathcal{O} onto an observational manifold \mathcal{O} \subset \mathbb{R}^3:  
```
\boldsymbol{\Pi}_{\text{obs}}(\mathbf{x}) = \begin{pmatrix} \pi_{Ri}(\mathbf{x}) \\ \pi_H(\mathbf{x}) \\ \pi_S(\mathbf{x}) \end{pmatrix} = \begin{pmatrix} \frac{g}{\theta_0} \frac{\theta_z(T_s)}{S^2} \\ \rho c_p q_\theta \\ S \end{pmatrix}

```
The individual components of \boldsymbol{\Pi}_{\text{obs}} are scalar-valued **diagnostic functionals**:  
* \pi_{Ri}: \Omega_0 \to \mathbb{R}_+: the Gradient Richardson diagnostic functional,  
* \pi_H: \Omega_0 \to \mathbb{R}: the Sensible Heat Flux functional, and  
* \pi_S: \Omega_0 \to \mathbb{R}_+: the Wind Shear coordinate functional.  
**Differential Structure of \pi_{Ri}**  
The differential 1-form D\pi_{Ri}(\mathbf{x}) \in T_{\mathbf{x}}^* \Omega_0 of the Gradient Richardson functional is given by:  
```
D\pi_{Ri}(\mathbf{x}) = 0\,d\tilde{e} + 0\,dq_\theta - \left(\frac{2 g \theta_z(T_s)}{\theta_0 S^3}\right) dS + \left(\frac{g}{\theta_0 S^2} \frac{\partial \theta_z}{\partial T_s}\right) dT_s + 0\,dT_g

```
The differential 1-form D\pi_{Ri} resides entirely in the slow cotangent subspace \operatorname{span}\{dS, dT_s\}, establishing that \pi_{Ri} is geometrically orthogonal to the fast turbulent directions (\tilde{e}, q_\theta).  
**Proposition 2.2 (Observation Smoothness)**  
*Under Standing Assumptions (A1)–(A2), the observation mapping \boldsymbol{\Pi}_{\text{obs}}: \Omega_0 \to \mathcal{O} and its constituent diagnostic functionals (\pi_{Ri}, \pi_H, \pi_S) are C^\infty smooth mappings on \Omega_0.*  
*Proof.* The components of \boldsymbol{\Pi}_{\text{obs}} are composed of smooth rational and polynomial functions of the state variables \mathbf{x} \in \Omega_0. Because S > 0 on \Omega_0 by Assumption (A3), the denominator in \pi_{Ri}(\mathbf{x}) = \frac{g \theta_z(T_s)}{\theta_0 S^2} is non-zero everywhere on \Omega_0. Smoothness of \theta_z(T_s) and linear dependency on q_\theta and S guarantee that \boldsymbol{\Pi}_{\text{obs}} \in C^\infty(\Omega_0, \mathcal{O}). \square  
Section 2 now provides a fully defined, smooth dynamical system \mathbf{F}(\mathbf{x}), regularized chart \tilde{e}, and smooth diagnostic functionals \pi_{Ri} ready to support Theorems 1–3 in Sections 3 and 4.  
