## 1. Vertical Shear ($S^2$) & Kinetic Energy

You correctly identified $S^2$ as the inner product of the vertical gradient of the horizontal wind vector $\vec{u} = (U, V)$:

$$\frac{\partial \vec{u}}{\partial z} = \left( \frac{\partial U}{\partial z}, \frac{\partial V}{\partial z} \right)$$

$$S^2 = \left\Vert{} \frac{\partial \vec{u}}{\partial z} \right\Vert{}_2^2 = \left(\frac{\partial U}{\partial z}\right)^2 + \left(\frac{\partial V}{\partial z}\right)^2 = \left(\frac{\partial \vec{u}}{\partial z}\right) \cdot \left(\frac{\partial \vec{u}}{\partial z}\right)$$

* **Mean Kinetic Energy (MKE):** $E_k = \frac{1}{2}(U^2 + V^2)$
* **Turbulent Production:** Shear $S^2$ acts as the mechanical engine. It extracts energy out of the large-scale Mean Kinetic Energy ($E_k$) and injects it directly into TKE ($\tilde{e}^2$) via the mechanical production term:

$$\text{Production} = \frac{1}{2} c_m \ell S^2 \tilde{e}$$

---

## 2. Geostrophic Forcing & Coriolis Cross Product

Yes, geostrophic balance fundamentally relies on the vector cross product between the Earth's rotation vector $\vec{\Omega} = \Omega \hat{k}$ and the horizontal velocity $\vec{u} = (U, V, 0)$:

$$\text{Coriolis Acceleration} = -2\vec{\Omega} \times \vec{u} = \left( f V \hat{i} - f U \hat{j} \right)$$

where $f = 2\Omega \sin\phi$ is the Coriolis parameter.

When large-scale pressure gradients $\nabla_h p$ drive the atmosphere, the geostrophic wind vector $\vec{u}_g = (U_g, V_g)$ satisfies:

$$f \hat{k} \times \vec{u}_g = -\frac{1}{\rho} \nabla_h p$$

In the slow shear equation ($\frac{dS}{d\tau}$), the forcing term $\mathcal{F}_{\text{ls}}$ represents this large-scale geostrophic pressure driving the wind shear profile against surface friction.

---

## 3. Static Stability ($N^2$) vs. Temperature Gradient ($\theta_z$)

The **Brunt-Väisälä (buoyancy) frequency** $N$ measures how strongly the atmosphere resists vertical displacement:

$$N^2 = \frac{g}{\theta_0} \frac{\partial \theta}{\partial z} = \frac{g}{\theta_0} \theta_z$$

| Environment | Stratification | $N^2$ Value | Physical Effect |
| --- | --- | --- | --- |
| **Unstable** | $\theta_z < 0$ | $N^2 < 0$ | Convective overturning (imaginary frequency). |
| **Neutral** | $\theta_z = 0$ | $N^2 = 0$ | No buoyant restoring force. |
| **Stable (Night)** | $\theta_z > 0$ | $N^2 > 0$ | Air parcels oscillate vertically at frequency $N$; suppresses turbulence. |

In night-time conditions (SBL), $\theta_z > 0$, so $N^2 > 0$. The ground cools, driving a downward heat flux ($q_\theta = \overline{w'\theta'} < 0$), which acts as a **sink** for TKE:

$$\text{Buoyancy Damping} = -\frac{g}{2\theta_0} q_\theta \quad (\text{since } q_\theta < 0, \text{ this term subtracts energy from } \tilde{e})$$

---

## 4. The Richardson Number ($Ri$) Balance

The **Gradient Richardson Number** ($Ri$) is simply the ratio of buoyant suppression ($N^2$) to mechanical shear generation ($S^2$):

$$Ri = \frac{\text{Buoyancy Resistance}}{\text{Shear Production}} = \frac{N^2}{S^2} = \frac{\frac{g}{\theta_0} \theta_z}{S^2}$$

Rearranging gives the exact balance you recalled:

$$N^2 = Ri \cdot S^2$$

---

## Summary: How They Balance in the 5D Fast TKE Equation

$$\frac{d\tilde{e}}{d\tau} = \underbrace{\frac{1}{2} c_m \ell \cdot S^2 \cdot \tilde{e}}_{\begin{array}{c} \text{Mechanical Source} \\ \text{(Wants to create TKE)} \end{array}} - \underbrace{\frac{g}{2\theta_0} q_\theta}_{\begin{array}{c} \text{Buoyant Sink } (\propto N^2) \\ \text{(Wants to kill TKE)} \end{array}} - \underbrace{\frac{1}{2\ell} \tilde{e}^3}_{\begin{array}{c} \text{Molecular Dissipation} \\ \text{(Viscous decay)} \end{array}}$$

* When **Mechanical Shear ($S^2$) dominates** ($Ri < Ri_{\text{cr}}$), $\frac{d\tilde{e}}{d\tau} > 0$ and turbulence is sustained.
* When **Buoyancy ($N^2$) dominates** ($Ri > Ri_{\text{cr}}$), buoyancy damping wipes out TKE, driving $\tilde{e} \to 0$ (the turbulence collapse event).

---

Here is the fully closed, self-contained **5D Fast-Slow-SuperSlow ODE system** expressed in desingularized time ($\tau$), along with all requisite physical closure relations and parameter definitions.

---

## 1. The Closed 5D Governing System

The system spans three distinct timescales governed by scale parameters $0 < \epsilon_2 \ll \epsilon_1 \ll 1$:

$$\begin{aligned} \text{Fast } (\tau): \quad \frac{d\tilde{e}}{d\tau} &= \underbrace{\frac{1}{2} c_m \ell S^2 \tilde{e}}_{\text{Shear Production}} - \underbrace{\frac{g}{2\theta_0} q_\theta}_{\text{Buoyancy Sink}} - \underbrace{\frac{1}{2\ell} \tilde{e}^3}_{\text{TKE Dissipation}} \\ \text{Fast } (\tau): \quad \frac{dq_\theta}{d\tau} &= \underbrace{- c_w \theta_z(T_s) \tilde{e}^3}_{\text{Gradient Generation}} - \underbrace{\frac{g}{\theta_0} c_\theta \ell q_\theta^2}_{\text{Self-Interaction}} - \underbrace{\frac{C_\theta}{\ell} \tilde{e}^2 q_\theta}_{\text{Destruction}} \\ \text{Slow } (t_{\text{slow}}): \quad \frac{dS}{d\tau} &= \frac{\epsilon_1}{\tilde{e}} \left[ \underbrace{\nu_0 (S_g - S)}_{\text{Geostrophic Drive}} - \underbrace{\gamma_m \frac{c_m \ell \tilde{e} S}{\Delta z^2}}_{\text{Turbulent Drag}} \right] \\ \text{Slow } (t_{\text{slow}}): \quad \frac{dT_s}{d\tau} &= \frac{\epsilon_1}{\tilde{e}} \frac{1}{C_s} \left[ \underbrace{R_{\text{net}}(T_s)}_{\text{Net Radiation}} + \underbrace{\rho c_p q_\theta}_{\text{Sensible Heat Flux}} + \underbrace{\frac{k_g}{d_g}(T_g - T_s)}_{\text{Soil Conductive Flux } G} \right] \\ \text{Super-Slow } (t_{\text{super-slow}}): \quad \frac{dT_g}{d\tau} &= \frac{\epsilon_1 \epsilon_2}{\tilde{e}} \frac{\kappa_g}{d_g^2} \left( T_s - T_g \right) \end{aligned}$$

---

## 2. Explicit Physical Closure Functions

To evaluate the system, the open closures $\theta_z(T_s)$, $R_{\text{net}}(T_s)$, and $\ell$ are parameterized as follows:

### A. Atmospheric Stratification Slaving ($\theta_z$)

The vertical potential temperature gradient $\theta_z = \frac{\partial \theta}{\partial z}$ is slaved to the skin temperature cooling deficit relative to the neutral background state $T_0$:


$$\theta_z(T_s) = \max\left(0, \, \frac{T_0 - T_s}{h_{\text{sbl}}}\right)$$


*where $h_{\text{sbl}}$ is the characteristic nocturnal stable boundary layer height.*

### B. Surface Net Radiation ($R_{\text{net}}$)

In clear-sky nocturnal conditions (zero solar shortwave radiation), longwave emission is linearized around background temperature $T_0$:


$$R_{\text{net}}(T_s) = R_{\text{down}} - \epsilon_s \sigma T_s^4 \approx R_0 - 4 \epsilon_s \sigma T_0^3 (T_s - T_0)$$


*where $R_0 = R_{\text{down}} - \epsilon_s \sigma T_0^4$ represents the baseline radiative cooling deficit.*

### C. Master Mixing Length ($\ell$)

Near the surface ($z$), $\ell$ is governed by Blackadar asymptotic mixing:


$$\ell = \frac{\kappa (z + z_0)}{1 + \frac{\kappa (z + z_0)}{\ell_\infty}}$$

---

## 3. Physical State & Parameter Dictionary

| Variable / Parameter | Definition | Typical Value / Units |
| --- | --- | --- |
| $\tilde{e}$ | Desingularized TKE ($\sqrt{e + \delta}$) | $\text{m s}^{-1}$ ($\delta \approx 10^{-6}$) |
| $q_\theta$ | Kinematic Heat Flux ($\overline{w'\theta'}$) | $\text{K m s}^{-1}$ |
| $S$ | Vertical Wind Shear ($\Vert{}\partial_z \vec{u}\Vert{}_2$) | $\text{s}^{-1}$ |
| $T_s$ | Ground Skin Temperature | $\text{K}$ |
| $T_g$ | Subsurface Soil Temperature | $\text{K}$ |
| $c_m, c_w, c_\theta, C_\theta$ | Dimensional WSINDy Closure Parameters | Calibrated per field site |
| $\epsilon_1, \epsilon_2$ | Time-Scale Separation Ratios | $\epsilon_1 \sim 10^{-2}, \epsilon_2 \sim 10^{-1}$ |
| $\kappa$ | von Kármán constant | $0.40$ |
| $g$ | Gravitational acceleration | $9.81 \text{ m s}^{-2}$ |
| $\theta_0$ | Reference Potential Temperature | $300.0 \text{ K}$ |
| $C_s$ | Surface Skin Heat Capacity | $1.0 \times 10^4 \text{ J m}^{-2} \text{ K}^{-1}$ |
| $k_g, \kappa_g$ | Soil Thermal Conductivity / Diffusivity | $0.4 \text{ W m}^{-1} \text{ K}^{-1}, 10^{-6} \text{ m}^2 \text{ s}^{-1}$ |
| $d_g$ | Subsurface Soil Depth | $0.10 \text{ m}$ |
| $\rho, c_p$ | Air Density / Specific Heat Capacity | $1.2 \text{ kg m}^{-3}, 1004 \text{ J kg}^{-1} \text{ K}^{-1}$ |
| $\sigma, \epsilon_s$ | Stefan-Boltzmann constant / Surface Emissivity | $5.67 \times 10^{-8} \text{ W m}^{-2} \text{ K}^{-4}, 0.98$ |

---

## 4. Un-rescaling Back to Physical Coordinates

Once integrated in fast desingularized time $\tau$, physical time $t$ and physical TKE $e$ are recovered via:

$$e(t) = \tilde{e}(\tau)^2 - \delta$$

$$t = \int_0^\tau \frac{1}{\tilde{e}(\tau')} \, d\tau'$$

