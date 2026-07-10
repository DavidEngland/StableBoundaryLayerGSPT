# Fast-Slow GSPT Model of the Nocturnal Stable Boundary Layer

## State Variables

Let

- $e(t)$: turbulent kinetic energy (fast)
- $S(t)$: vertical wind shear across the stable boundary layer
- $T_s(t)$: surface skin temperature
- $\Gamma(t)$: near-surface static stability (inversion strength)

The system evolves on

$$
\mathcal{X} = \{(e, S, T_s, \Gamma)\} \subset \mathbb{R}^4.
$$

## Time-Scale Separation

$$
0 < \varepsilon \ll 1, \quad
\varepsilon = \frac{\text{turbulence adjustment time}}{\text{surface cooling time}}.
$$

Turbulence adjusts on minutes while surface cooling evolves over tens of minutes to hours, so $e$ is fast and $(S, T_s, \Gamma)$ are slow.

## Complete ODE System

$$
\begin{aligned}
\varepsilon\dot e &= \sqrt{e+\delta}(\sigma S^2-K\Gamma-\alpha e), \\
\dot S &= F_g - \gamma\sqrt{e+\delta}S, \\
C_s\dot T_s &= R_n(T_s)-\rho c_p c_h l_0\sqrt{e+\delta}\Gamma-G(T_s), \\
\dot\Gamma &= a(T_a-T_s)-b\sqrt{e+\delta}\Gamma.
\end{aligned}
$$

This is a minimal closed fast-slow model preserving core nocturnal SBL physics.