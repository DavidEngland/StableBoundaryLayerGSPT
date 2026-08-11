Actually, you're completely right—it isn't a stretch at all. In fact, making skin temperature $T_s$ the fast variable in a 2D boundary layer model is standard physics in classical Surface Energy Balance (SEB) literature.  
If you isolate the land surface energy budget coupled to a single-layer atmosphere, you get a 2D fast-slow dynamical system that looks almost identical to the Sal'nikov model.  
## The Classic 2D Surface Energy Balance (SEB) Model  
In land-surface modeling (such as the minimal SBL models of **McNider et al. 1995** or **van de Wiel et al. 2007**), the skin layer is treated as having near-zero heat capacity ($C_s \to 0$).  
If you couple the skin temperature $T_s$ to a slow heat reservoir (like deep soil temperature $T_g$ or a slowly evolving boundary-layer wind $U$), the $2\text{D}$ governing equations become:  
$$\begin{aligned} \epsilon \frac{dT_s}{dt} &= R_{\text{down}} - \sigma T_s^4 - H(T_s, U) - \lambda_s (T_s - T_g) \\ \frac{dT_g}{dt} &= \frac{\lambda_s}{C_g} (T_s - T_g) \quad \text{(or } \frac{dU}{dt} = f_c (U_g - U) - C_D U^2 \text{)} \end{aligned}$$  
where $\epsilon = C_s \ll 1$ is the tiny heat capacity of the surface skin.  
* **Fast Variable ($T_s$):** Radiative and turbulent exchange at the skin adjust on a timescale of **seconds to minutes**.  
* **Slow Variable ($T_g$ or $U$):** Subsurface soil conduction ($T_g$) or geostrophic momentum relaxation ($U$) evolves over **hours to days**.  
## How $T_s$ Creates the Folded Manifold  
Setting $\epsilon = 0$ forces the skin temperature onto the critical manifold $S_0$, defined by the algebraic surface energy balance:  
$$f(T_s, T_g, U) \equiv R_{\text{down}} - \sigma T_s^4 - H(T_s, U) - \lambda_s (T_s - T_g) = 0$$  
The crucial non-linearity comes from the sensible heat flux $H(T_s, U)$. Because $H$ relies on stability functions (like the Richardson number $Ri_g$), as $T_s$ drops relative to the air, stratification suppresses turbulence:  
1. **High Wind / Weak Stratification:** $H$ is large and linear. $T_s$ cools smoothly.  
2. **Critical Stratification ($Ri \to Ri_{\text{crit}}$):** $H$ collapses toward zero because turbulence shuts off.  
3. **The Fold Knee:** Radiative cooling ($\sigma T_s^4$) suddenly outpaces turbulent heat supply ($H$). The derivative $\frac{\partial f}{\partial T_s}$ changes sign, creating a **fold singularity**.  
When the trajectory reaches this fold, $T_s$ experiences **runaway surface cooling**—a rapid, deterministic jump to a cold, decoupled state.  
## Comparing the Three Models  
When mapped side-by-side, you can see a clean hierarchy from astrophysics to 2D land surface models, up to full multi-layer GSPT-SBL:  

| Feature | 2D Sal'nikov Outgassing | 2D SEB Boundary Layer (e.g., van de Wiel) | 4D/5D GSPT-SBL Framework |
| -------------- | ------------------------------------------- | -------------------------------------------------------- | -------------------------------------------------------------- |
| Fast Variable | Skin Temp $T$ ($\\tau \\sim \\text{min}$) | Skin Temp $T_s$ ($\\tau \\sim \\text{min}$) | TKE $e$ & fluxes ($\\tau \\sim \\text{sec}$) |
| Slow Variable | Volatiles $c$ ($\\tau \\sim \\text{hours}$) | Deep Soil $T_g$ or Wind $U$($\\tau \\sim \\text{hours}$) | Profiles $\\theta(z), u(z), v(z)$($\\tau \\sim \\text{hours}$) |
| Non-linearity | Arrhenius $e^{-E/RT}$ | Stability functions $f(Ri_g)$ | Coupled shear-buoyancy tensor |
| Physical Event | Thermal Superheating Flare | Runaway Surface Cooling / Collapse | Global SBL Regime Transition |
  
****Why GSPT-SBL Upgrades the 2D Picture****  
The 2D SEB model with fast $T_s$ is great for explaining why surface temperatures plunge at sunset, but it treats the entire atmosphere as a single bulk slab with an ad-hoc stability function.  
GSPT-SBL takes that 2D skin-temperature fold mechanism and embeds it into the full vertical fluid column. By promoting TKE $e$ to an even faster timescale ($\tau_{\text{TKE}} \ll \tau_{\text{skin}} \ll \tau_{\text{mean}}$), GSPT-SBL creates a multi-timescale hierarchy:  
$$\tau_{\text{turbulence}} \ \ll \ \tau_{\text{skin cooling}} \ \ll \ \tau_{\text{Areal mean profile evolutions}}$$  
This is precisely what allows GSPT-SBL to capture **vertical decoupling, inertial oscillations (LLJs), and multi-height intermittent turbulence** that a 2D skin-temperature model cannot resolve.  
