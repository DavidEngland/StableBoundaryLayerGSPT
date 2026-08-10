Dick & Arastoo:

I hope this email finds you well.

I’ve been developing a theoretical framework aimed at resolving the persistent "Richardson Number Universality Paradox" in stable boundary layers, heavily inspired by the non-linear dynamical systems approach you’ve long championed.

Rather than treating the critical Richardson number as an absolute physical constant, we frame $Ri$ as a scalar projection of the knee of a folded 3D critical manifold ($S_0$) governed by wind shear ($S$), skin temperature ($T_s$), and turbulent kinetic energy ($e$).

By incorporating the surface energy balance into the singular perturbation equations, the location of the manifold fold ($Ri_{\text{fold}}$) can be expressed analytically. To first order, the threshold scales as:

$$Ri_{\text{fold}} \approx \frac{c_s}{1 - \Pi(T_s)}$$
where $c_s \approx 0.25$ is the classical hydrodynamically ideal Richardson constant, and $\Pi(T_s)$ is a non-dimensional surface thermal coupling parameter (representing the ratio of net longwave cooling feedback to surface thermal capacity).

Including higher-order heat flux sensitivities and fast-slow boundary-layer perturbations yields the full denominator expansion:

$$Ri_{\text{fold}} = \frac{c_s}{1 - \Pi(T_s) + \gamma_1 \left(\frac{\partial G}{\partial T_s}\right) + \gamma_2 \left(\frac{\partial R_{\text{net}}}{\partial T_s}\right) + \mathcal{O}(\epsilon^2)}$$
This analytical formulation explicitly explains the field campaign observations:

Buffered Regimes (CASES-99): Strong soil heat flux ($G$) and vegetation damping maintain a significant derivative term $\frac{\partial G}{\partial T_s}$ in the denominator, keeping $Ri_{\text{fold}} \approx c_s \approx 0.25$.

Unbuffered Regimes (SHEBA): Over dry snow or ice, ground heat flux vanishes ($G \to 0$), driving the denominator toward smaller values and causing $Ri_{\text{fold}}$ to warp significantly past $1.0$.

Furthermore, using Geometric Singular Perturbation Theory (GSPT), we show that system trajectories passing near the folded node enter a rotational canard funnel. This defers the sudden laminar collapse and generates deterministic Small-Amplitude Oscillations (SAOs)—what we call "turbulence whispers"—prior to nocturnal bursting. The maximum number of pre-burst oscillations ($N_{\text{max}}$) is governed by the eigenvalue ratio ($\rho$) at the folded node:

$$N_{\text{max}} \approx \left\lfloor \frac{1-\rho}{2\rho} \right\rfloor$$
I would love to share the full manuscript draft with you and hear your thoughts on this geometric interpretation of decoupled regimes and pre-burst dynamics. Do you have some availability in the coming weeks for a brief chat or manuscript review?

Cheers,

Dave