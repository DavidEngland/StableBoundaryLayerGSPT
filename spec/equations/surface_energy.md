# Surface Energy

- Equation ID: `EQ-SURF-001`
- Terms: sensible flux, latent flux, mechanical production, radiative cooling
- Units: W m^-2
- Contract: implementation entrypoint is `Physics.compute_fluxes`

## Skin Temperature Equation

$$
C_s\dot T_s = R_{\downarrow} - \sigma_{SB}T_s^4 - \lambda\frac{T_s-T_{\mathrm{deep}}}{d_{\mathrm{soil}}} + \rho c_p C_H\sqrt{e+\delta}(T_a-T_s)
$$

- $R_{\downarrow} - \sigma_{SB}T_s^4$: net radiative term
- $\lambda (T_s-T_{\mathrm{deep}})/d_{\mathrm{soil}}$: soil conductive loss
- $\rho c_p C_H\sqrt{e+\delta}(T_a-T_s)$: turbulent sensible heat exchange

## Sensible Heat Closure

$$
H = \rho c_p C_H\sqrt{e+\delta}(T_a-T_s).
$$

When the fast state is projected onto a diagnostic manifold approximation, the closure becomes

$$
H = \rho c_p C_H\sqrt{e^*(U,V,T_s,\xi)+\delta}\,(T_a-T_s),
$$

so the surface energy budget is closed by a nonlinear map from slow variables to turbulent heat flux. This diagnostic manifold is used for reduced-geometry interpretation and closure evaluation; the prognostic model itself evolves the full fast equation. The SEB provides the slow feedback needed for fold-induced jumps and hysteresis in the coupled atmosphere-surface system.