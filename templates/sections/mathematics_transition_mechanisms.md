# Transition Mechanisms in the Reduced Geometry

## Critical Manifold

With $\varepsilon=0$:

$$
\sqrt{e+\delta}(\Delta-\alpha e)=0, \quad \Delta=\sigma S^2-K\Gamma.
$$

Since $\delta>0$, the manifold branch is

$$
e^* = \frac{\Delta}{\alpha} \quad (\Delta>0),
$$

and laminar clamping is used for $\Delta \le 0$.

For differentiable solver interfaces, introduce the smoothing scale $\eta>0$ and define

$$
e^*_{\eta} = \frac{1}{2\alpha}\left(\Delta + \sqrt{\Delta^2 + \eta^2}\right).
$$

This regularization is $C^\infty$ for fixed $\eta$ and recovers the clipped manifold in the limit $\eta \to 0$.

## Vector-Momentum Generalization

The manifold machinery is unchanged if the scalar slow shear is replaced by horizontal momentum components $(U,V)$. The only modification is the forcing diagnostic,

$$
\Delta = \sigma \left(\frac{\sqrt{U^2+V^2}}{h}\right)^2 - K G(T_s),
$$

or an analogous vector-shear norm in a vertically resolved setting. The fast foliation and transcritical threshold are therefore preserved, but the slow flow reaching that threshold becomes rotational under Coriolis coupling.

## Transcritical Exchange

At

$$
\Delta = \sigma S^2-K\Gamma = 0,
$$

the leading decay rate approaches zero, producing critical slowing and early warning signatures.

## Fold Catastrophe

For reduced slow manifold relation $H(T_s,S)=0$, fold points satisfy

$$
H=0, \quad \frac{\partial H}{\partial T_s}=0.
$$

Crossing the fold causes fast departure from the attracting branch and jump to laminar regime.