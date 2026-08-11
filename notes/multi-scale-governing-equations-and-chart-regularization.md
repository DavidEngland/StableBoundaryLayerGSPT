# 2. Governing Equations, Chart Regularization, and Diagnostic Functionals

This section defines the smooth fast-slow architecture for the stable boundary layer (SBL) model. We introduce the regularized state space, state the standing assumptions used in the geometric analysis, derive the desingularized fast chart, and define the observation map that connects invariant-manifold structure to atmospheric diagnostics.

## 2.1 System Definition and Standing Assumptions

We work with a multiscale autonomous system written in the desingularized time variable $\tau$ on an open chart domain $\Omega_0 \subset \mathbb{R}^5$:

$$
\frac{d\mathbf{x}}{d\tau}
= \mathbf{F}(\mathbf{x};\boldsymbol{\mu},\epsilon_1,\epsilon_2)
\equiv
\begin{pmatrix}
F_{\mathrm{fast}}(\mathbf{x};\boldsymbol{\mu}) \\
\epsilon_1 F_{\mathrm{slow}}(\mathbf{x};\boldsymbol{\mu}) \\
\epsilon_1\epsilon_2 F_{\mathrm{superslow}}(\mathbf{x};\boldsymbol{\mu})
\end{pmatrix}.
$$

The state vector is

$$
\mathbf{x}
= \begin{pmatrix}
\tilde e \\
q_\theta \\
S \\
T_s \\
T_g
\end{pmatrix}
\in \Omega_0
\subset \mathbb{R}_+ \times \mathbb{R} \times \mathbb{R}_+ \times \mathbb{R}_+ \times \mathbb{R}_+.
$$

Its components are interpreted as follows:

1. $\tilde e \in \mathbb{R}_+$: desingularized turbulent kinetic energy coordinate,
2. $q_\theta \in \mathbb{R}$: kinematic turbulent heat flux $\overline{w'\theta'}$,
3. $S \in \mathbb{R}_+$: bulk vertical wind shear $\lVert \partial \mathbf{u}/\partial z \rVert$,
4. $T_s \in \mathbb{R}_+$: surface skin temperature,
5. $T_g \in \mathbb{R}_+$: deep-soil temperature.

### Standing Assumptions

Throughout this section we assume:

1. **(A1) Domain regularity.** The chart domain $\Omega_0 \subset \mathbb{R}^5$ is open and connected, and the vector field $\mathbf{F}$ is of class $C^\infty$ on $\Omega_0$.
2. **(A2) Parameter domain.** The parameter block $\boldsymbol{\mu} \in \mathcal{P}$ belongs to an open bounded set of physically admissible coefficients containing the closure, radiative, and thermodynamic constants appearing below.
3. **(A3) Positive invariance.** The physically admissible set

   $$
   \Omega_{\mathrm{phys}}
   = \{\mathbf{x} \in \Omega_0 \mid \tilde e > 0,\; S > 0,\; T_s > 0,\; T_g > 0\}
   $$

   is positively invariant under the flow.
4. **(A4) Local well-posedness.** For each initial state $\mathbf{x}(0) \in \Omega_0$, there exists a unique local trajectory $\mathbf{x}(\tau)$.
5. **(A5) Timescale separation.** The perturbation parameters satisfy

   $$
   0 < \epsilon_1 \ll 1,
   \qquad
   0 < \epsilon_2 \ll 1,
   $$

   with fast dynamics on $O(1)$ time, slow dynamics on $O(\epsilon_1^{-1})$ time, and super-slow dynamics on $O((\epsilon_1\epsilon_2)^{-1})$ time.

## 2.2 Chart Regularization and Desingularization

In the original turbulent kinetic energy variable $e$, the fast equations contain non-smooth fractional powers through the shear-production term $c_m \ell e^{1/2} S^2$ and the Kolmogorov dissipation term $e^{3/2}/\ell$. As $e \to 0^+$, differentiability is lost at the laminar boundary.

To restore smoothness, introduce the regularized chart map

$$
\phi_\delta : e \mapsto \tilde e = \sqrt{e + \delta},
\qquad \delta > 0.
$$

We analyze the dynamics on the regularized chart and then interpret the resulting geometry in the limit $\delta \to 0^+$. To desingularize the fast dynamics, use the positive time reparameterization

$$
d\tau = \left(\frac{\tilde e}{\epsilon_1}\right) dt.
$$

**Proposition 2.1 (Regularization and Diffeomorphic Equivalence).** On the physical domain $e > 0$, the map $\phi_\delta$ is a $C^\infty$ diffeomorphism onto its image. Under the positive time change

$$
d\tau = \frac{\tilde e}{\epsilon_1} dt,
$$

the fast subsystem extends to a smooth vector field in the chart variable $\tilde e$, while preserving phase trajectories, equilibrium sets, and the signs of transverse eigenvalues along the critical manifold.

**Proof.** For $\delta > 0$ and $e > 0$,

$$
\phi_\delta(e) = \sqrt{e+\delta}
$$

is smooth with derivative

$$
\phi_\delta'(e) = \frac{1}{2\sqrt{e+\delta}} > 0,
$$

so $\phi_\delta$ is a smooth diffeomorphism onto its image. In the physical variable $e$, the fast TKE equation is

$$
\epsilon_1 \frac{de}{dt}
= c_m \ell e^{1/2} S^2
- \frac{g}{\theta_0} q_\theta
- \frac{1}{\ell} e^{3/2}.
$$

Since $\tilde e^2 = e + \delta$, differentiation gives

$$
2\tilde e \frac{d\tilde e}{dt} = \frac{de}{dt},
$$

and therefore

$$
\frac{d\tilde e}{d\tau}
= \frac{dt}{d\tau}\frac{d\tilde e}{dt}
= \frac{\epsilon_1}{\tilde e}\cdot \frac{1}{2\tilde e}\frac{de}{dt}
= \frac{\epsilon_1}{2\tilde e^2}\frac{de}{dt}.
$$

Substituting the physical equation and using $e = \tilde e^2 - \delta$ yields

$$
\frac{d\tilde e}{d\tau}
= \frac{1}{2\tilde e^2}
\left(
c_m \ell \sqrt{\tilde e^2 - \delta}\,S^2
- \frac{g}{\theta_0} q_\theta
- \frac{1}{\ell}(\tilde e^2 - \delta)^{3/2}
\right).
$$

In the limiting chart $\delta \to 0^+$ this becomes

$$
\frac{d\tilde e}{d\tau}
= \frac{1}{2} c_m \ell S^2 \tilde e
- \frac{g}{2\theta_0} q_\theta
- \frac{1}{2\ell} \tilde e^3,
$$

which is polynomial in $\tilde e$. Because $d\tau/dt = \tilde e/\epsilon_1 > 0$ on $\Omega_{\mathrm{phys}}$, the reparameterization is orientation preserving. Standard results for positive time changes then imply preservation of orbits, equilibria, and transverse stability signatures. $\square$

## 2.3 Subsystem Vector Field Components

Under Assumption (A1) and Proposition 2.1, the desingularized vector field components are given explicitly as follows.

### Fast Subsystem

The fast subsystem $F_{\mathrm{fast}}(\mathbf{x}) = (\tilde F(\mathbf{x}), \tilde H(\mathbf{x}))^T$ governs rapid turbulent adjustment:

$$
F_{\mathrm{fast}}(\mathbf{x})
= \begin{pmatrix}
\frac{1}{2} c_m \ell S^2 \tilde e - \frac{g}{2\theta_0} q_\theta - \frac{1}{2\ell} \tilde e^3 \\
- c_w \, \theta_z(T_s) \, \tilde e^3 - \frac{g}{\theta_0} c_\theta \ell q_\theta^2 - \frac{C_\theta}{\ell} \tilde e^2 q_\theta
\end{pmatrix}.
$$

Here the local thermal stratification is represented by the smooth diagnostic map

$$
\theta_z(T_s) = \frac{\theta_{\mathrm{top}} - \Pi_s T_s}{\Delta z}.
$$

### Slow Subsystem

The slow subsystem $F_{\mathrm{slow}}(\mathbf{x}) = (F_S(\mathbf{x}), F_{T_s}(\mathbf{x}))^T$ governs wind shear and surface thermal evolution:

$$
F_{\mathrm{slow}}(\mathbf{x})
= \begin{pmatrix}
\frac{1}{\tilde e}\left[\mathcal{F}_{\mathrm{ls}} - \frac{\partial}{\partial z}\big(c_m \ell \tilde e S\big)\right] \\
\frac{1}{\tilde e C_s}\left[R_{\mathrm{net}}(T_s) + \rho c_p q_\theta + \frac{k_g}{d_g}(T_g - T_s)\right]
\end{pmatrix},
$$

where the net radiation is

$$
R_{\mathrm{net}}(T_s)
= R_{\mathrm{sw}}^{\downarrow} + \epsilon_a \sigma T_a^4 - \epsilon_s \sigma T_s^4.
$$

### Super-Slow Subsystem

The super-slow subsystem governs deep-soil heat conduction:

$$
F_{\mathrm{superslow}}(\mathbf{x})
= \frac{1}{\tilde e}\frac{k_g}{d_g^2}(T_s - T_g).
$$

## 2.4 Observation Mapping and Diagnostic Functionals

To connect the internal state $\mathbf{x} \in \Omega_0$ to observable diagnostics, define the smooth observation map

$$
\boldsymbol{\Pi}_{\mathrm{obs}} : \Omega_0 \to \mathcal O \subset \mathbb{R}^3,
$$

with components

$$
\boldsymbol{\Pi}_{\mathrm{obs}}(\mathbf{x})
= \begin{pmatrix}
\pi_{Ri}(\mathbf{x}) \\
\pi_H(\mathbf{x}) \\
\pi_S(\mathbf{x})
\end{pmatrix}
= \begin{pmatrix}
\frac{g}{\theta_0}\frac{\theta_z(T_s)}{S^2} \\
\rho c_p q_\theta \\
S
\end{pmatrix}.
$$

These functionals represent:

1. $\pi_{Ri}$: the gradient Richardson diagnostic,
2. $\pi_H$: the sensible heat flux,
3. $\pi_S$: the wind-shear coordinate.

### Differential Structure of $\pi_{Ri}$

The differential of the Richardson functional is

$$
D\pi_{Ri}(\mathbf{x})
= 0\,d\tilde e
+ 0\,dq_\theta
- \left(\frac{2g\,\theta_z(T_s)}{\theta_0 S^3}\right)dS
+ \left(\frac{g}{\theta_0 S^2}\frac{\partial \theta_z}{\partial T_s}\right)dT_s
+ 0\,dT_g.
$$

Hence $D\pi_{Ri}$ lies entirely in the slow cotangent subspace $\operatorname{span}\{dS,dT_s\}$, so the Richardson diagnostic is insensitive, at first order, to perturbations in the fast turbulent directions $(\tilde e,q_\theta)$.

**Proposition 2.2 (Observation Smoothness).** Under Assumptions (A1) and (A3), the map $\boldsymbol{\Pi}_{\mathrm{obs}}$ and its component functionals $(\pi_{Ri}, \pi_H, \pi_S)$ are $C^\infty$ on $\Omega_0$.

**Proof.** Each component of $\boldsymbol{\Pi}_{\mathrm{obs}}$ is a composition of smooth algebraic operations on $\Omega_0$. Because $S > 0$ on $\Omega_{\mathrm{phys}}$, the denominator in

$$
\pi_{Ri}(\mathbf{x}) = \frac{g}{\theta_0}\frac{\theta_z(T_s)}{S^2}
$$

never vanishes. The remaining components are linear in $q_\theta$ and $S$, and $\theta_z(T_s)$ is smooth by construction. Therefore $\boldsymbol{\Pi}_{\mathrm{obs}} \in C^\infty(\Omega_0, \mathcal O)$. $\square$

Section 2 now provides a smooth desingularized dynamical system, an explicit regularized chart, and a diagnostic observation framework suitable for the invariant-manifold results developed in the subsequent sections.
