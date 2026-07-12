# Fast-Slow GSPT Model of the Nocturnal Stable Boundary Layer

## State Variables

Let

- $e(t)$: turbulent kinetic energy (fast)
- $U(t),V(t)$: horizontal wind components
- $T_s(t)$: surface skin temperature

The system evolves on

$$
\mathcal{X} = \{(e, U, V, T_s)\} \subset \mathbb{R}^4.
$$

## Time-Scale Separation

$$
0 < \varepsilon \ll 1, \quad
\varepsilon = \frac{\text{turbulence adjustment time}}{\text{surface cooling time}}.
$$

Turbulence adjusts on minutes while momentum and surface cooling evolve over tens of minutes to hours, so $e$ is fast and $(U,V,T_s)$ are slow.

## Complete ODE System

$$
\begin{aligned}
\varepsilon\dot e &= \mathcal{F}(e,U,V,T_s), \\
\dot U &= f_c(V-V_g)-\gamma\sqrt{e+\delta}U, \\
\dot V &= -f_c(U-U_g)-\gamma\sqrt{e+\delta}V, \\
C_{\mathrm{skin}}\dot T_s &= R_{\downarrow}-\sigma_{SB}T_s^4-\lambda\frac{T_s-T_{\mathrm{deep}}}{d_{\mathrm{soil}}}+\rho c_p C_H\sqrt{e+\delta}(T_a-T_s).
\end{aligned}
$$

This is a minimal closed fast-slow model preserving core nocturnal SBL physics.

The fast field is

$$
\mathcal{F}(e,U,V,T_s)=\sqrt{e+\delta}\left[\eta\,\gamma\,(U^2+V^2)-K\,G(T_s)\right]-\frac{(e+\delta)^{3/2}}{l_0}.
$$

## Geometric Flux Closure

The turbulence closure is written directly in the regularized TKE coordinate rather than through empirical functions of a local Richardson number. The eddy diffusivities are

$$
K_m = c_m l_0 \sqrt{e+\delta}, \qquad K_h = c_h l_0 \sqrt{e+\delta},
$$

with structural constants $c_m,c_h$, turbulent length scale $l_0$, and background-mixing parameter $\delta > 0$. This makes both diffusivities strictly positive and supplies a natural minimum diffusivity floor proportional to $\sqrt{\delta}$.

For NWP-style time steps the fast TKE state may be projected to a diagnostic manifold, giving the active turbulent branch

$$
e^* = l_0\Delta-\delta, \qquad \Delta = \eta\,\gamma\,(U^2+V^2)-K\,G(T_s).
$$

To retain smooth gradients for implicit solvers and variational data assimilation, the clipped branch may be replaced by the $C^\infty$ diagnostic regularization

$$
e^*_{\xi} = \frac{1}{2}\left(e^*+\sqrt{(e^*)^2+\xi^2}\right), \qquad \xi \ll 1.
$$

This smoothed branch is used for closure evaluation and initialization; the prognostic model itself evolves the full fast ODE. Substituting back into the diffusivity law yields the geometric closure

$$
K_{m,h} = c_{m,h} l_0 \sqrt{e^*(U,V,T_s,\xi) + \delta},
$$

which resolves a weakly stable transition branch for $\Delta > 0$ and a background-mixing branch for $\Delta \le 0$ without allowing the diffusivity to collapse to zero.

## Coriolis-Coupled Slow Return

The same geometric closure yields a two-component horizontal wind state

$$
x = (e,U,V,T_s) \in \mathbb{R}^4,
$$

and the slow momentum equations become

$$
\dot U = f(V-V_g)-\gamma\sqrt{e+\delta}U, \qquad
\dot V = -f(U-U_g)-\gamma\sqrt{e+\delta}V.
$$

The production term is driven by total horizontal speed,

$$
\Delta = \eta\,\gamma\,(U^2+V^2)-K G(T_s),
$$

so the fast equation and its regularized critical manifold remain structurally unchanged while the slow return path acquires Coriolis rotation. This is the natural route to capturing Blackadar-type inertial oscillations and circular hodograph overshoot within the same GSPT framework.