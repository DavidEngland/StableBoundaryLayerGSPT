Here's the key: in pure hydrodynamic stability theory (like the classical Miles–Howard theorem), $Ri_c = 0.25$ is a constant derived from a fixed background flow. But in the real boundary layer, **shear and stratification are dynamically coupled through the surface energy balance**.  
When surface skin temperature $T_s$ drops, longwave radiative cooling $R_{\text{net}}(T_s)$ increases, sharpening the vertical potential temperature gradient $\partial \theta / \partial z$ right at the ground. Because buoyancy destruction scales with this thermal gradient, the critical threshold at which turbulence collapses ($Ri_{\text{fold}}$) becomes a dynamic function of surface cooling and wind speed, rather than a universal constant.  
Here is how to translate the abstract GSPT formulation into equations standard in atmospheric boundary-layer physics.  
## 1. From GSPT Control Parameter to Surface Energy Balance  
In GSPT, the non-dimensional control parameter is written as:  
$$\Pi(T_s) = \frac{\beta^2 \ell_0}{4 B(T_s)}$$  
In atmospheric terms, $B(T_s)$ represents the **buoyancy destruction rate forced by surface thermal equilibrium**. Setting up the surface energy budget:  
$$R_{\text{net}}(T_s) = H(T_s, U) + G + LE$$  
where $R_{\text{net}}(T_s) \approx \epsilon \sigma T_s^4 - R_{\text{down}}$ is net longwave radiation, $H$ is sensible heat flux, $G$ is ground heat flux, and $LE$ is latent heat flux.  
Substituting standard bulk transfer formulas for sensible heat flux $H = \rho c_p C_H U (T_a - T_s)$, the fold Richardson number $Ri_{\text{fold}}$ expressed in terms familiar to boundary-layer meteorologists is:  
$$Ri_{\text{fold}}(T_s, U) = \frac{g}{\theta_0} z_{\text{ref}} \frac{T_a - T_s(R_{\text{net}})}{U^2} \Bigg\vert{}_{\text{fold}} = \frac{1}{2 \beta_h} \left[ 1 - \frac{R_{\text{net}}(T_s) - G}{\rho c_p C_H U (T_a - T_s)} \right]$$  
where $\beta_h \approx 5$ is the standard Monin–Obukhov stability parameter ($\phi_h = 1 + \beta_h z/L$).  
## 2. Expressed via Brunt–Väisälä Frequency ($N^2$) vs. Shear ($S^2$)  
Atmospheric scientists often analyze $Ri$ as the ratio of static stability to mechanical shear:  
$$Ri = \frac{N^2}{S^2} = \frac{\frac{g}{\theta_0} \frac{\partial \theta}{\partial z}}{\left(\frac{\partial U}{\partial z}\right)^2}$$  
In a coupled SBL, thermal radiation fixes the surface heat flux demand, making $N^2$ an explicit function of $T_s$:  
$$N^2(T_s) = \frac{g}{\theta_0} \left( \frac{R_{\text{net}}(T_s) - G}{\rho c_p K_h} \right)$$  
Plugging this back into the fold condition yields:  
$$Ri_{\text{fold}}(T_s) = \frac{\frac{g}{\theta_0} \left( \frac{\epsilon \sigma T_s^4 - R_{\text{down}} - G}{\rho c_p K_h} \right)}{\left( \frac{\partial U}{\partial z} \right)^2}$$  
## Why This Equation Explains Field Campaign Scatter  
This single equation clarifies why measured collapse points scatter widely across field sites (e.g., $Ri_b \approx 0.2$ in CASES-99 vs. $Ri_b \ge 1.2$ in SHEBA over polar ice):  
* **Polar Ice / Cold Surfaces ($T_s \ll 0^\circ\text{C}$):** Ground heat flux $G$ and surface temperature $T_s$ are extremely low. $R_{\text{net}}$ radiation dominates, generating intense near-surface $N^2(T_s)$. Turbulence can collapse at much lower wind shear, shifting $Ri_{\text{fold}}$ upwards toward $1.0+$.  
* **Grassland / Warm Surfaces ($T_s \sim 280\text{ K}$):** Ground conductive heat flux $G$ buffers surface cooling, keeping $N^2(T_s)$ moderate. The fold occurs much closer to the classic hydrodynamic limit $Ri_{\text{fold}} \approx 0.2 \text{ to } 0.25$.  
Expressing $Ri_{\text{fold}}(T_s)$ this way demonstrates that observational scatter is not random instrument noise—it is the signature of a dynamic manifold shifting with surface surface energy balance.  
