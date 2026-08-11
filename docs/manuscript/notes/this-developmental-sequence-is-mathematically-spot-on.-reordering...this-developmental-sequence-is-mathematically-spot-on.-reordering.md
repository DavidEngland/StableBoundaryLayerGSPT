This developmental sequence is mathematically spot-on. Reordering the workflow to derive the fold locus and projection map first puts geometry where it belongs in GSPT: as the invariant backbone that governs the flow before local dynamics or bifurcations are evaluated.  
Here is how we can formalize Steps 1, 2, and 3 into an analytical derivation structure.  
## Step 1: Defining the Critical Manifold S_0 and Fold Locus \mathcal{C}_{\text{fold}}  
Let the fast TKE budget equation be given in standard parameterized form by:  
```
\epsilon \frac{de}{dt} = f(e, \mathbf{x}_{\text{slow}}; l_0) = K_m(e, l_0) S^2 - K_h(e, l_0) N^2(\mathbf{x}_{\text{slow}}) - C_{\epsilon} \frac{e^{3/2}}{l_0}

```
where \mathbf{x}_{\text{slow}} = (U, V, T_s)^T, S = \Vert{}\partial_z \mathbf{U}\Vert{} is the local vertical shear, N^2 = \frac{g}{\theta_0}\frac{\partial \theta}{\partial z} is the static stability, and K_m, K_h are eddy diffusivities (e.g., K_m = c_k l_0 e^{1/2}).  
The **critical manifold** S_0 is the set of points where fast equilibrium holds:  
```
S_0 = \left\{ (e, \mathbf{x}_{\text{slow}}) \in \mathbb{R}_{\ge 0} \times \mathbb{R}^3 \;\middle\vert{}\; f(e, \mathbf{x}_{\text{slow}}; l_0) = 0 \right\}

```
The **fold locus** \mathcal{C}_{\text{fold}} \subset S_0 defines where normal hyperbolicity breaks. It is defined by the simultaneous vanishing of f and its partial derivative with respect to the fast state:  
```
\mathcal{C}_{\text{fold}} = \left\{ (e, \mathbf{x}_{\text{slow}}) \in S_0 \;\middle\vert{}\; \frac{\partial f}{\partial e}(e, \mathbf{x}_{\text{slow}}; l_0) = 0 \right\}

```
Solving \frac{\partial f}{\partial e} = 0 yields a fast coordinate at the fold, e_{\text{fold}} = e_{\text{fold}}(\mathbf{x}_{\text{slow}}). Substituting this back into f(e_{\text{fold}}, \mathbf{x}_{\text{slow}}) = 0 defines a 2D surface in the 3D slow space \mathbf{x}_{\text{slow}}.  
## Step 2: The Richardson Projection Map \Pi  
We define the Bulk Richardson number not as an independent state variable, but as a smooth coordinate projection map \Pi:  
\Pi: S_0 \longrightarrow \mathbb{R} \Pi(e, U, V, T_s) = \frac{g}{\theta_0} \frac{\left( \theta(z_h) - T_s \right) z_h}{U^2 + V^2}  
Evaluating this map strictly along the fold locus \mathcal{C}_{\text{fold}} gives the dynamic collapse boundary:  
```
Ri_{\text{fold}}(\mathbf{x}_{\text{slow}}) = \Pi\Big\vert{}_{\mathcal{C}_{\text{fold}}}(\mathbf{x}_{\text{slow}}) = \Pi\Big(e_{\text{fold}}(\mathbf{x}_{\text{slow}}), \mathbf{x}_{\text{slow}}\Big)

```
Because T_s decreases via nocturnal cooling, N^2(\mathbf{x}_{\text{slow}}) increases, shifting e_{\text{fold}} and consequently making Ri_{\text{fold}} an explicit function of the evolving surface energy balance rather than a constant 0.25.  
## Step 3: Proving l_0 as a Codimension-One Unfolding Parameter  
To test whether l_0 acts as a codimension-one bifurcation parameter (rather than just a scale factor), we evaluate the **cusp singularity conditions** on f:  
1. f(e^*, \mathbf{x}^*_{\text{slow}}; l_0^*) = 0 *(Equilibrium)*  
2. f(e^*, \mathbf{x}^*_{\text{slow}}; l_0^*) = 0 *(Equilibrium)*  
3. f(e^*, \mathbf{x}^*_{\text{slow}}; l_0^*) = 0 *(Equilibrium)*  
4. \frac{\partial f}{\partial e}(e^*, \mathbf{x}^*_{\text{slow}}; l_0^*) = 0 *(Fold inflection)*  
5. \frac{\partial f}{\partial e}(e^*, \mathbf{x}^*_{\text{slow}}; l_0^*) = 0 *(Fold inflection)*  
6. \frac{\partial f}{\partial e}(e^*, \mathbf{x}^*_{\text{slow}}; l_0^*) = 0 *(Fold inflection)*  
7. \frac{\partial^2 f}{\partial e^2}(e^*, \mathbf{x}^*_{\text{slow}}; l_0^*) = 0 *(Cusp condition)*  
8. \frac{\partial^2 f}{\partial e^2}(e^*, \mathbf{x}^*_{\text{slow}}; l_0^*) = 0 *(Cusp condition)*  
9. \frac{\partial^2 f}{\partial e^2}(e^*, \mathbf{x}^*_{\text{slow}}; l_0^*) = 0 *(Cusp condition)*  
10. \frac{\partial f}{\partial l_0}(e^*, \mathbf{x}^*_{\text{slow}}; l_0^*) \neq 0 *(Transversality)*  
11. \frac{\partial f}{\partial l_0}(e^*, \mathbf{x}^*_{\text{slow}}; l_0^*) \neq 0 *(Transversality)*  
12. \frac{\partial f}{\partial l_0}(e^*, \mathbf{x}^*_{\text{slow}}; l_0^*) \neq 0 *(Transversality)*  
If conditions 3 and 4 hold for a critical mixing length l_{0,c}, then varying l_0 through l_{0,c} structurally unfolds the manifold from a monotonic surface (l_0 > l_{0,c}) into a folded manifold with bistability (l_0 < l_{0,c}).  
## Step 4: Local Jacobian and Breakout Analysis  
Near the laminar floor e \approx \delta > 0, the Jacobian matrix J of the 4D system is:  
```
J = \begin{pmatrix} \frac{1}{\epsilon} \frac{\partial f}{\partial e} & \frac{1}{\epsilon} \frac{\partial f}{\partial U} & \frac{1}{\epsilon} \frac{\partial f}{\partial V} & \frac{1}{\epsilon} \frac{\partial f}{\partial T_s} \\ g_{1,e} & g_{1,U} & g_{1,V} & g_{1,T_s} \\ g_{2,e} & g_{2,U} & g_{2,V} & g_{2,T_s} \\ g_{3,e} & g_{3,U} & g_{3,V} & g_{3,T_s} \end{pmatrix}

```
Because \epsilon \ll 1, the leading eigenvalue is governed by the fast subsystem:  
```
\lambda_f \approx \frac{1}{\epsilon} \left. \frac{\partial f}{\partial e} \right\vert{}_{e = \delta}

```
* **Laminar Attraction (\lambda_f < 0):** Trajectories on the lower floor remain stably trapped in the quasi-laminar state.  
* **Breakout Trigger (\lambda_f = 0):** As slow shear builds aloft (U, V increase due to geostrophic acceleration), \lambda_f passes through zero.  
* **Explosive Burst (\lambda_f > 0):** The lower branch loses local stability, forcing an O(1/\epsilon) fast jump toward the upper active branch S_0^+.  
Analytically computing \left. \frac{\partial^2 f}{\partial e^2} \right\vert{}_{e=\delta} at this crossing will formally establish whether this breakout is a transcritical bifurcation, a pitchfork, or a boundary node exchange.  
To execute Step 1 directly using your specific eddy-diffusivity closure forms for K_m(e) and K_h(e), what explicit algebraic functions are you currently using for K_m and K_h?  
