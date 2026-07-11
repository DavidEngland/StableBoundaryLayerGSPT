# Slow System

- Equation ID: `EQ-SLOW-001`
- Slow variables: `S`, `T_s`, `Gamma`
- Physical interpretation: geostrophic forcing, land-surface energy evolution, and inversion strength evolution

## Shear Evolution

$$
\dot S = F_g - \gamma\sqrt{e + \delta}S
$$

- $F_g$: effective pressure-gradient forcing
- $\gamma\sqrt{e + \delta}S$: turbulent drag term

## Stability Evolution

$$
\dot\Gamma = a(T_a - T_s) - b\sqrt{e + \delta}\Gamma
$$

- $a$: conversion of surface cooling to inversion growth
- $b$: turbulent erosion of inversion

## Complete Four-Variable ODE System

$$
\begin{aligned}
\varepsilon\dot e &= \sqrt{e+\delta}(\sigma S^2-K\Gamma-\alpha e), \\
\dot S &= F_g - \gamma\sqrt{e+\delta}S, \\
C_s\dot T_s &= R_n(T_s)-\rho c_p c_h l_0\sqrt{e+\delta}\Gamma-G(T_s), \\
\dot\Gamma &= a(T_a-T_s)-b\sqrt{e+\delta}\Gamma.
\end{aligned}
$$

## Planned Vector-Momentum Extension

For future inertial-oscillation studies, the scalar shear equation may be replaced by a two-component horizontal momentum subsystem,

$$
\dot U = f(V-V_g)-\gamma\sqrt{e+\delta}U, \qquad
\dot V = -f(U-U_g)-\gamma\sqrt{e+\delta}V,
$$

with production diagnosed from a vector-speed or vector-shear proxy rather than from a single scalar shear variable. This preserves the fast-slow geometry while permitting Blackadar-style rotational overshoot in the slow flow.

## Contract

- Consumed by Theory and Mathematics generators
- Timescale separation is explicit relative to fast subsystem