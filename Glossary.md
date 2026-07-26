# Repository Glossary: GSPT Stable Boundary Layer Model

This glossary documents the physical concepts, mathematical constructs, state variables, and computational infrastructure used throughout the `StableBoundaryLayerGSPT` repository.

---

## 1. Boundary Layer Physics & Surface Energy

* **Stable Boundary Layer (SBL):** The lower tropospheric layer formed when the surface cools relative to the overlying air (typically overnight or over ice/snow), giving rise to negative buoyancy fluxes ($B < 0$) that suppress vertical turbulent mixing.
* **Gradient Richardson Number ($\mathrm{Ri}_g$):** A non-dimensional ratio comparing static stability (buoyancy frequency squared, $N^2$) to wind shear squared ($S^2$):

$$\mathrm{Ri}_g = \frac{N^2}{S^2} = \frac{\frac{g}{\theta_0}\frac{\partial \theta}{\partial z}}{\left(\frac{\partial U}{\partial z}\right)^2 + \left(\frac{\partial V}{\partial z}\right)^2}$$


* **Critical Richardson Number ($\mathrm{Ri}_c$):** The theoretical linear stability limit ($\approx 0.25$). Classical parcel theory predicts laminarization above $\mathrm{Ri}_c$, whereas observations confirm turbulent transport often persists at $\mathrm{Ri}_g \gg 0.25$.
* **Eddy Diffusivities ($K_m, K_h$):** Parameterized exchange coefficients for momentum ($K_m$) and heat ($K_h$) in 1D flux-gradient transport relations:

$$\tau_x = -K_m \frac{\partial U}{\partial z}, \quad H = -\rho C_p K_h \frac{\partial \theta}{\partial z}$$


* **Turbulent Prandtl Number ($\mathrm{Pr}_t$):** The non-dimensional ratio of momentum diffusivity to scalar heat diffusivity ($\mathrm{Pr}_t = K_m / K_h$). In near-neutral states $\mathrm{Pr}_t \approx 1.0$, but under strong stratification, pressure-strain redistribution maintains momentum exchange while thermal transport drops, driving $\mathrm{Pr}_t \to 2.0\text{--}5.0$.
* **Surface Energy Budget (SEB):** The thermodynamic balance between net longwave/shortwave radiation ($R_n$), sensible heat flux ($H$), latent heat flux ($E$), and conductive soil/ice heat flux ($G$) controlling surface temperature evolution:

$$C_{\mathrm{skin}} \frac{dT_s}{dt} = R_n - H - LE - G$$


* **Thermal Shift Function:** The bounded, non-linear mapping $G(T_s) = \tanh\!\left(\frac{\beta(T_a - T_s)}{T_a}\right)$ that converts surface-air temperature contrast into buoyancy suppression while avoiding unphysical exponential blow-up under extreme cooling.
* **Runaway Surface Decoupling:** A boundary layer collapse mechanism where surface radiative cooling overwhelms shear TKE production, causing turbulent heat fluxes to drop to near zero and driving surface skin temperature into a rapid, unmitigated plunge.

---

## 2. Geometric Singular Perturbation Theory (GSPT) & Dynamical Systems

* **Fast--Slow System:** A dynamical system containing state variables evolving on drastically different time scales governed by a small dimensionless ratio $0 < \varepsilon \ll 1$.
* **Shifted TKE Coordinate ($\phi$):** The primary fast state coordinate $\phi = e + \delta$, where $e$ is turbulent kinetic energy and $\delta$ is the regularized background TKE floor.
* **Critical Manifold ($\mathcal{S}_0$):** The lower-dimensional geometric surface formed by the equilibrium set of the fast subsystem in the singular limit $\varepsilon \to 0$.
* **Fold Invariant ($\Delta$):** The geometric control parameter governing the topology of the fast subsystem:

$$\Delta = \eta \gamma_{\mathrm{eff}} (U^2 + V^2) - K_{\mathrm{buoy}} \tanh\!\left(\frac{\beta(T_a - T_s)}{T_a}\right)$$



Its sign determines whether mechanical shear production exceeds buoyancy destruction, thereby selecting the attracting branch of the critical manifold $\mathcal{S}_0$.
* **Fold Point / Turning Point ($\Delta = 0$):** The non-hyperbolic bifurcation threshold where the upper stable turbulent branch meets the lower unstable branch of the critical manifold, initiating rapid transitions between attracting branches of the critical manifold.
* **Regularization Gate ($\psi$):** A smooth, $C^\infty$ multiplier function applied to the production term to prevent singular limits near $\phi \to 0$:

$$\psi = \frac{\sqrt{\phi}}{\sqrt{\phi} + \alpha_{\mathrm{safe}}}$$



Exhibits asymptotic limits $\psi \to 1$ for energetic turbulence ($\phi \gg \alpha_{\mathrm{safe}}^2$) and $\psi \to 0$ as $\phi \to 0$.
* **Hyperbolicity:** The property of a critical manifold branch characterized by non-zero real parts of fast eigenvalues, ensuring persistence under small perturbations according to Fenichel theory.
* **Normal Hyperbolicity:** The condition that contraction or expansion transverse to the manifold dominates motion tangent to it, guaranteeing the existence of invariant slow manifolds $\mathcal{S}_\varepsilon$.
* **Fenichel Reduction:** A singular perturbation technique that replaces full fast dynamics with evolution on the normally hyperbolic attracting branch of the slow manifold, reducing computational stiffness while preserving slow physical dynamics.
* **Folded Slow Manifold:** The invariant slow manifold $\mathcal{S}_\varepsilon$ obtained after regularization of the singular limit, upon which the reduced atmospheric boundary layer dynamics evolve.
* **Canard Trajectory:** A dynamical trajectory that follows an attracting branch of the critical manifold, passes near a fold point, and temporarily tracks a repelling branch before rapidly transitioning away.

---

## 3. Model Variables & Parameters

| Variable / Parameter | Mathematical Symbol | Repo / Code Key | Units | Physical Description |
| --- | --- | --- | --- | --- |
| **Turbulent Kinetic Energy** | $e$ | `x[1]` | $\mathrm{m}^2\,\mathrm{s}^{-2}$ | Fast variable governing turbulent intensity |
| **Zonal Velocity** | $U$ | `x[2]` | $\mathrm{m}\,\mathrm{s}^{-1}$ | Slow variable: cross-profile zonal wind |
| **Meridional Velocity** | $V$ | `x[3]` | $\mathrm{m}\,\mathrm{s}^{-1}$ | Slow variable: cross-profile meridional wind |
| **Surface Skin Temperature** | $T_s$ | `x[4]` | $\mathrm{K}$ | Slow variable: ground/ice skin temperature |
| **Timescale Separation Ratio** | $\varepsilon$ | `epsilon` | $-$ | Ratio of fast turbulent relaxation to slow advective scale ($\ll 1$) |
| **Background TKE Floor** | $\delta$ | `delta` | $\mathrm{m}^2\,\mathrm{s}^{-2}$ | Smooth regularization parameter preserving differentiability while preventing collapse of fast dynamics |
| **Master Mixing Length** | $\ell_0$ | `l0` | $\mathrm{m}$ | Characteristic eddy length scale |
| **Buoyant Destruction Scale** | $K_{\mathrm{buoy}}$ | `K_buoy` | $\mathrm{m}\,\mathrm{s}^{-2}$ | Scaling for thermal stratification suppression |
| **Stability Sensitivity** | $\beta$ | `beta` | $-$ | Sensitivity of non-linear buoyancy saturation |
| **Geostrophic Wind Vector** | $(U_g, V_g)$ | `Ug`, `Vg` | $\mathrm{m}\,\mathrm{s}^{-1}$ | Large-scale pressure gradient forcing vector |
| **Surface Drag Coefficient** | $\gamma_{\mathrm{eff}}$ | `gamma_eff` | $\mathrm{s}^{-1}$ | Emergent effective momentum exchange scale |

---

## 4. Computational Pipeline & SciML Stack

* **Single-Column Model (SCM):** A 1D atmospheric modeling framework that isolates vertical column thermodynamics and boundary layer turbulence while holding horizontal advection to prescribed geostrophic forcings.
* **Dual-Number Automatic Differentiation (AD):** Forward-mode differentiation provided by `ForwardDiff.jl` that computes exact analytical Jacobians $\mathbf{J}$ using dual-number perturbation algebra.
* **AD Safety:** The algorithmic formulation of vector fields using micro-regularizations ($\phi + 10^{-15}$) and smooth functions (`log1p(exp())`, `tanh()`) instead of non-differentiable logic (`max()`, `clamp()`). This guarantees:
1. $C^\infty$ smoothness across state boundaries,
2. Strict `ForwardDiff` dual-number compatibility, and
3. Analytical Jacobian consistency for implicit stiff solvers.


* **Rodas5P Solver:** A 5th-order, L-stable, stiff Rosenbrock ODE solver from `DifferentialEquations.jl` suited for fast--slow systems governed by $\varepsilon \ll 1$.

---

## 5. Observational Benchmark Campaigns

* **CASES-99 (Cooperative Atmosphere-Surface Exchange Study 1999):** Field campaign in Kansas, USA. Serves as the primary mid-latitude benchmark for nocturnal boundary layer evolution, low-level jet formation, and intermittent turbulence.
* **FLOSS (Fluxes Over Snow Surfaces):** Field campaign in North Park, Colorado, USA. Focuses on turbulence dynamics, cold surface energy balances, and stable stratifications over winter snowpack.
* **SHEBA (Surface Heat Budget of the Arctic Ocean):** Multi-month Arctic ice pack campaign. Represents extreme polar conditions characterized by persistent radiative cooling, deep surface inversions, and weak surface drag.
* **GABLS3 (GEWEX Atmospheric Boundary Layer Study 3):** Comprehensive multi-day benchmark campaign at Cabauw, Netherlands, used for assessing SCM performance during strong diurnal transitions and nocturnal low-level jets.
* **BLLAST (Boundary-Layer Late-Afternoon and Sunset Turbulence):** European field campaign in southern France targeting the decay phase of convective turbulence and the setup of early nocturnal stability.
* **SMEAR II (Station for Measuring Ecosystem-Atmosphere Relations II):** Long-term boreal forest observatory in Hyytiälä, Finland, providing multi-season datasets on stable boundary layer coupling over rough, vegetated terrain.