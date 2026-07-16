# Transition Mechanisms in the Reduced Geometry

## Critical Manifold

With $\varepsilon=0$:

$$
\mathcal{F}(e,U,V,T_s)=\sqrt{e+\delta}\left[\eta\,\gamma\,(U^2+V^2)-K\,G(T_s)\right]-\frac{(e+\delta)^{3/2}}{l_0}=0.
$$

Since $\delta>0$, the active turbulent branch is

$$
e^* = l_0\Delta-\delta, \quad \Delta=\eta\,\gamma\,(U^2+V^2)-K\,G(T_s),
$$

and laminar clamping is used for $\Delta \le 0$.

For differentiable solver interfaces, introduce the smoothing scale $\xi>0$ and define a diagnostic approximation

$$
e^*_{\xi} = \frac{1}{2}\left(e^* + \sqrt{(e^*)^2 + \xi^2}\right).
$$

This regularization is $C^\infty$ for fixed $\xi$ and recovers the clipped manifold in the limit $\xi \to 0$. It is a diagnostic closure approximation, not the exact equilibrium relation of the prognostic fast ODE.

## Vector-Momentum Generalization

The manifold machinery is unchanged if the scalar slow shear is replaced by horizontal momentum components $(U,V)$. The forcing diagnostic becomes

$$
\Delta = \eta\,\gamma\,(U^2+V^2)-K\,G(T_s),
$$

so the turbulent branch is a paraboloid of revolution in $(U,V,e)$ for fixed $T_s$. The fast foliation and transcritical threshold are therefore preserved, but the slow flow reaching that threshold becomes rotational under Coriolis coupling.

## Transcritical Exchange

At

$$
\Delta = 0,
$$

the leading decay rate approaches zero, producing critical slowing and early warning signatures.

## Fold Catastrophe

The geometric fold is not defined directly by a surface-energy injectivity condition. Instead, fold points satisfy

$$
\mathcal{F}(e,U,V,T_s)=0, \qquad \partial_e\mathcal{F}(e,U,V,T_s)=0.
$$

The SEB provides the slow parameter dependence that can drive trajectories into this set. Crossing the fold causes loss of normal hyperbolicity, fast departure from the attracting branch, and jump to the laminar regime.