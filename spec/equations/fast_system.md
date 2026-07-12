# Fast System

- Equation ID: `EQ-FAST-001`
- Variables: `e` (turbulent kinetic energy, fast), `U`, `V` (horizontal wind components), `T_s` (surface skin temperature)
- State space: $\mathcal{X} = \{(e, U, V, T_s)\} \subset \mathbb{R}^4$
- Time-scale parameter: $0 < \varepsilon \ll 1$, with
	$\varepsilon = \frac{\text{turbulence adjustment time}}{\text{surface cooling time}}$

## Governing Equation

$$
\varepsilon \dot e = \mathcal{F}(e,U,V,T_s)
$$

$$
\mathcal{F}(e,U,V,T_s) = \sqrt{e+\delta}\left[\eta\,\gamma\,(U^2+V^2)-K\,G(T_s)\right] - \frac{(e+\delta)^{3/2}}{l_0}.
$$

- Mechanical production: $\eta\,\gamma\,(U^2+V^2)$
- Buoyancy destruction: $K\,G(T_s)$
- Dissipation: $(e+\delta)^{3/2}/l_0$
- Background mixing regularization: $\delta > 0$

where

$$
G(T_s)=\exp\!\left(\beta\frac{T_a-T_s}{T_a}\right)-1,
\qquad
\eta=15.0.
$$

The calibrated value $\eta=15.0$ matches `shear_production_efficiency` in `src/Dynamics/Dynamics.jl`.

## Contract

- Implementation maps to `Dynamics.fast_vector_field_F`
- Sign convention: positive shear production increases TKE
- Units: SI throughout