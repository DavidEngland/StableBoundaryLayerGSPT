# Surface Energy

- Equation ID: `EQ-SURF-001`
- Terms: sensible flux, latent flux, mechanical production, radiative cooling
- Units: W m^-2
- Contract: implementation entrypoint is `Physics.compute_fluxes`

## Skin Temperature Equation

$$
C_s\dot T_s = R_n(T_s) - H(e,S,\Gamma) - G(T_s)
$$

- $R_n$: net radiation
- $H$: sensible heat flux
- $G$: ground heat flux

## Sensible Heat Closure

$$
H = \rho c_p K_h\Gamma, \quad K_h = c_h l_0\sqrt{e+\delta}
$$

so

$$
H = \rho c_p c_h l_0\sqrt{e+\delta}\Gamma.
$$

When the fast state is projected onto the regularized critical manifold, the closure becomes

$$
H = \rho c_p c_h l_0\sqrt{e^*(S,\Gamma,\eta)+\delta}\,\Gamma,
$$

so the surface energy budget is closed by a nonlinear map from slow variables to turbulent heat flux. This coupling is the mechanism that permits fold-induced jumps and hysteresis in the reduced atmospheric-surface system.