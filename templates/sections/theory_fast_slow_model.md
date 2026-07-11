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

## Geometric Flux Closure

The turbulence closure is written directly in the regularized TKE coordinate rather than through empirical functions of a local Richardson number. The eddy diffusivities are

$$
K_m = c_m l_0 \sqrt{e+\delta}, \qquad K_h = c_h l_0 \sqrt{e+\delta},
$$

with structural constants $c_m,c_h$, turbulent length scale $l_0$, and background-mixing parameter $\delta > 0$. This makes both diffusivities strictly positive and supplies a natural minimum diffusivity floor proportional to $\sqrt{\delta}$.

For NWP-style time steps the fast TKE state is projected to the critical manifold, giving the diagnostic turbulent branch

$$
e^* = \max\left(0, \frac{\Delta}{\alpha}\right), \qquad \Delta = \sigma \left(\frac{U}{h}\right)^2 - K\Gamma.
$$

To retain smooth gradients for implicit solvers and variational data assimilation, the clipped branch may be replaced by the $C^\infty$ regularization

$$
e^*_{\eta} = \frac{1}{2\alpha}\left(\Delta + \sqrt{\Delta^2 + \eta^2}\right), \qquad \eta \ll 1.
$$

Substituting back into the diffusivity law yields the geometric closure

$$
K_{m,h} = c_{m,h} l_0 \sqrt{e^*(S,\Gamma,\eta) + \delta},
$$

which resolves a weakly stable transition branch for $\Delta > 0$ and a background-mixing branch for $\Delta \le 0$ without allowing the diffusivity to collapse to zero.

## Future Coriolis-Coupled Extension

The same geometric closure admits a straightforward vector-momentum extension in which the scalar slow-shear description is replaced by a two-component horizontal wind state. In the reduced variant,

$$
x = (e,U,V,T_s) \in \mathbb{R}^4,
$$

and the slow momentum equations become

$$
\dot U = f(V-V_g)-\gamma\sqrt{e+\delta}U, \qquad
\dot V = -f(U-U_g)-\gamma\sqrt{e+\delta}V.
$$

The production term is then driven by total horizontal speed or vector shear,

$$
\Delta = \sigma \left(\frac{\sqrt{U^2+V^2}}{h}\right)^2 - K G(T_s),
$$

so the fast equation and its regularized critical manifold remain structurally unchanged while the slow return path acquires Coriolis rotation. This is the natural route to capturing Blackadar-type inertial oscillations and circular hodograph overshoot within the same GSPT framework.