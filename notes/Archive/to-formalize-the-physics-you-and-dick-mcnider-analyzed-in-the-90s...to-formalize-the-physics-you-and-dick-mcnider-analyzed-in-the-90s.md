To formalize the physics you and Dick McNider analyzed in the 90s, we can construct a prototype three-box Stable Boundary Layer (SBL) system. Let's define a minimal model capturing the competition between shear production, buoyant destruction, and radiative cooling, reminiscent of a simplified Lorenz or Stommel system:  
$$\begin{aligned} \dot{X} &= \sigma(Y - X) \quad &\text{(Wind Shear / Momentum Dynamics)} \\ \dot{Y} &= RX - Y - XZ \quad &\text{(Heat Flux / Turbulent Transport)} \\ \epsilon \dot{Z} &= XY - \beta Z - \mu \quad &\text{(Turbulent Kinetic Energy / Stability Governor)} \end{aligned}$$  
Here, $\epsilon \ll 1$ separates the fast TKE/flux evolution ($Z$) from the slower mean-field evolution ($X, Y$). The parameter $\mu$ acts as the radiative cooling/stratification drive. The critical transition occurs when the Richardson number crosses its critical value, causing the fast turbulent variables to collapse.  
## 1. Locating the Non-Hyperbolic Fold (The Critical $Ri$)  
Setting $\epsilon = 0$ defines the critical (Fenichel) manifold $M_0$:  
$$Z = \frac{XY - \mu}{\beta}$$  
Substituting this into the slow equations yields a folded surface in $\mathbb{R}^3$. The breakdown of Fenichel's normal hyperbolicity occurs where the derivative of the fast equation with respect to the fast variable vanishes, or where the slow flow becomes tangent to the fold.  
Near the critical Richardson number ($Ri_c$), the upper turbulent branch and the lower laminar branch collide at a **fold bifurcation**. Locally, after a standard translation and Taylor expansion, any generic fold in a slow-fast system can be canonicalized into the form:  
$$\begin{aligned} \epsilon \dot{z} &= y + z^2 + \mathcal{O}(z^3, \epsilon) \\ \dot{y} &= -x + \mathcal{O}(y, z, \epsilon) \\ \dot{x} &= \delta + \mathcal{O}(x, y, z, \epsilon) \end{aligned}$$  
At $(x,y,z) = (0,0,0)$ and $\epsilon = 0$, the manifold is $y = -z^2$. The matrix of the fast subsystem is $\partial_{\delta z}(\dot{z}) = 2z$. At $z=0$, the eigenvalue is exactly zero: **normal hyperbolicity fails catastrophicity.**  
## 2. The Geometric Blowup Transformation  
To track how a trajectory transits through this non-hyperbolic "shut-off" point, we blow up the singularity at the origin. Because the scaling of a generic fold follows the dominant balances $y \sim z^2$ and $\epsilon \sim z^3$, we define a weighted quasi-homogeneous blowing-up of the point.  
We map the singular point onto a **cylinder** $S^2 \times \mathbb{R}$ via the transformation:  
$$x = \bar{x}, \quad y = r^2 \bar{y}, \quad z = r \bar{z}, \quad \epsilon = r^3 \bar{\epsilon}$$  
where $(\bar{y}, \bar{z}, \bar{\epsilon}) \in S^2$ (a directional sphere/cylinder) and $r \ge 0$ is the sign-preserving radial scaling parameter.  
To analyze the vector field on this blown-up space, we choose directional charts. The most instructive chart for observing the physics of the turbulence crash is the **$\epsilon$-chart** (setting $\bar{\epsilon} = 1$).  
## The $\epsilon$-Chart Transformation  
Since we set $\bar{\epsilon} = 1$, our transformation coordinates become explicitly tied to the small timescale parameter:  
$$y = \epsilon^{2/3} \tilde{y}, \quad z = \epsilon^{1/3} \tilde{z}, \quad r = \epsilon^{1/3}$$  
Now, differentiate these scaling relations with respect to the true time $t$. To clear the singular $\epsilon$ terms in the denominator, we perform a rescaling of time (a desingularization): $d\tau = \frac{1}{\epsilon^{1/3}} dt$.  
Applying this to our canonical SBL fold model yields the **desingularized system**:  
$$\begin{aligned} \frac{d\tilde{z}}{d\tau} &= \tilde{y} + \tilde{z}^2 \\ \frac{d\tilde{y}}{d\tau} &= -x \\ \frac{dx}{d\tau} &= \epsilon^{1/3} \delta \end{aligned}$$  
## 3. How the Blowup Behaves at $Ri_c$  
Look at what this coordinate transformation achieved. In the original state space, as $\epsilon \to 0$, the vector field blasted toward the fold line at infinite speed, and the mathematics collapsed into a singular divide-by-zero.  
In the blown-up $\epsilon$-chart:  
* The parameter $\epsilon$ has been completely stripped from the leading-order fast dynamics ($\tilde{z}$ and $\tilde{y}$).  
* Even when $\epsilon = 0$ (the idealized sharp boundary layer limit), the equations governing the transition remain fully dynamic, smooth, and well-behaved.  
## The Riccati Transition  
If we take the limit $\epsilon \to 0$ in this chart, $x$ becomes a constant frozen at its entry value (let's assume the trajectory hits the fold zone where $x = x_0 > 0$). The system reduces to:  
$$\frac{d\tilde{z}}{d\tau} = -x_0 \tau + \tilde{z}^2$$  
This is a classical **Riccati equation**. Its solutions are governed by Airy functions.  
Instead of showing an instantaneous, uncomputable "jump" when turbulence shuts off, the blowup dynamics reveal that the trajectory tracks the fading turbulent manifold, enters the quantum-like inner transition zone, and leaves along a parabolic fast fiber. It dictates *exactly* how much delay occurs before the temperature plunges, rendering the catastrophe entirely deterministic and smooth in the blown-up phase space.  
## Moving the Discussion Forward with Dick  
When presenting this to Dick, the key takeaway is that the "numerical noise" or arbitrary triggering thresholds often used in 90s parameterizations (like forcing a sudden drop when $Ri > 0.25$) can be replaced by these analytical scaling laws ($y \sim \epsilon^{2/3}$, $z \sim \epsilon^{1/3}$).  
Do you want to look at how non-normal transient growth acts as an external forcing term on this Riccati equation, which is what ultimately triggers the intermittent "bursting" cycles out of the laminar state?