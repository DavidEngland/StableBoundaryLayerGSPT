# Slow System

- Equation ID: `EQ-SLOW-001`
- Slow variables: `U`, `V`, `T_s`
- Physical interpretation: geostrophic forcing, inertial rotation, and land-surface thermodynamic evolution

## Momentum Evolution

$$
\dot U = f_c(V-V_g)-\gamma\sqrt{e+\delta}U,
$$

$$
\dot V = -f_c(U-U_g)-\gamma\sqrt{e+\delta}V.
$$

- $f_c$: Coriolis parameter
- $(U_g,V_g)$: geostrophic forcing target
- $\gamma\sqrt{e+\delta}(U,V)$: regularized turbulent drag

## Surface Thermodynamic Evolution

$$
C_{\mathrm{skin}}\dot T_s = R_{\downarrow}-\sigma_{SB}T_s^4-\lambda\frac{T_s-T_{\mathrm{deep}}}{d_{\mathrm{soil}}}+\rho c_p C_H\sqrt{e+\delta}(T_a-T_s)
$$

## Complete 4D ODE System

$$
\begin{aligned}
\varepsilon\dot e &= \mathcal{F}(e,U,V,T_s), \\
\dot U &= f_c(V-V_g)-\gamma\sqrt{e+\delta}U, \\
\dot V &= -f_c(U-U_g)-\gamma\sqrt{e+\delta}V, \\
C_{\mathrm{skin}}\dot T_s &= R_{\downarrow}-\sigma_{SB}T_s^4-\lambda\frac{T_s-T_{\mathrm{deep}}}{d_{\mathrm{soil}}}+\rho c_p C_H\sqrt{e+\delta}(T_a-T_s).
\end{aligned}
$$

where

$$
\mathcal{F}(e,U,V,T_s)=\sqrt{e+\delta}\left[\eta\,\gamma\,(U^2+V^2)-K\,G(T_s)\right]-\frac{(e+\delta)^{3/2}}{l_0}.
$$

## Contract

- Consumed by Theory and Mathematics generators
- Timescale separation is explicit relative to fast subsystem