# Fast System

- Equation ID: `EQ-FAST-001`
- Variables: `e` (turbulent kinetic energy, fast), `S` (vertical shear), `T_s` (surface skin temperature), `Gamma` (near-surface stability)
- State space: $\mathcal{X} = \{(e, S, T_s, \Gamma)\} \subset \mathbb{R}^4$
- Time-scale parameter: $0 < \varepsilon \ll 1$, with
	$\varepsilon = \frac{\text{turbulence adjustment time}}{\text{surface cooling time}}$

## Governing Equation

$$
\varepsilon \dot e = \sqrt{e + \delta}(\sigma S^2 - K\Gamma - \alpha e)
$$

- Mechanical production: $\sigma S^2$
- Buoyancy destruction: $K\Gamma$
- Dissipation: $\alpha e$
- Background mixing regularization: $\delta > 0$

Define

$$
\Delta = \sigma S^2 - K\Gamma
$$

so the fast equation can be written as

$$
\varepsilon \dot e = \sqrt{e + \delta}(\Delta - \alpha e).
$$

## Contract

- Implementation maps to `Dynamics.integrate_system`
- Sign convention: positive shear production increases TKE
- Units: SI throughout