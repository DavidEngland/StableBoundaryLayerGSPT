The Complete 4D GSPT-SBL Governing System
The full state vector is defined as \mathbf{x} = (e, U, V, T_s) \in \mathbb{R}^4, where e is the fast turbulent coordinate, and (U, V, T_s) are the slow environmental coordinates. The system is scaled using the small singular perturbation parameter \varepsilon, representing the ratio of the rapid turbulent allocation timescale to the slow macro-environmental thermodynamic forcing timescale (0 < \varepsilon \ll 1).
1. The Complete Fast-Slow Equations
Fast Subsystem (Turbulence Mechanics)
\varepsilon \frac{de}{dt} = \sqrt{e + \delta} \left[ \frac{\sigma}{h^2} (U^2 + V^2) - K \cdot G(T_s) - \alpha e \right]
Slow Subsystem (Atmospheric Rotational Dynamics & Surface Thermodynamics)
\frac{dU}{dt} = f(V - V_g) - \gamma \sqrt{e + \delta} \cdot U \frac{dV}{dt} = -f(U - U_g) - \gamma \sqrt{e + \delta} \cdot V \frac{dT_s}{dt} = \frac{1}{C_{\text{skin}}} \left[ R_{\downarrow} - \sigma_{SB} T_s^4 - \lambda \frac{T_s - T_{\text{deep}}}{d_{\text{soil}}} - \rho c_p C_H \sqrt{e + \delta} \cdot (T_s - T_a) \right]
2. Parameterization of Closures and Functions
To close the system mathematically, the abstract couplings are mapped to physical planetary boundary layer functions:
A. The Stratification Function G(T_s)
The stable stratification is driven by the vertical temperature inversion between the reference atmospheric layer (T_a) and the ground skin temperature (T_s). It is parameterized using a smooth, continuous exponential activation function to ensure it is C^\infty everywhere:
G(T_s) = \exp\left( \beta \frac{T_a - T_s}{T_a} \right) - 1
* Behavior: When T_s = T_a (neutral stratification), G(T_s) = 0, and buoyant destruction vanishes. When T_s < T_a (nocturnal cooling), G(T_s) > 0, rapidly accelerating the buoyant destruction of TKE.
B. The Turbulent Diffusivity/Drag Closure
The momentum drag coefficient \gamma and the surface thermodynamic sensible heat exchange coefficient C_H are scaled identically with the regularized turbulent velocity scale u_* \sim \sqrt{e + \delta}:
\gamma = \frac{\kappa^2}{\ln(h/z_0)^2} \cdot \frac{1}{h} C_H = \frac{\kappa^2}{\ln(h/z_{0m})\ln(h/z_{0h})}
Where \kappa is the von Kármán constant, h is the bulk boundary layer height scale, and z_0 represents the surface roughness lengths.
3. Physical Parameters and Baseline Scaling
To run this model numerically (e.g., in Julia/SciML or Python's solve_ivp), use the following verified baseline parameters scaled for a typical mid-latitude nocturnal boundary layer (resembling CASES99 conditions):
Environmental Controls & Geostrophic Forcing
Parameter	Description	Baseline Value	Units
U_g	Zonal Geostrophic Wind	10.0	\text{m s}^{-1}
V_g	Meridional Geostrophic Wind	0.0	\text{m s}^{-1}
T_a	Reference Air Temperature (z = h)	285.15	\text{K} \ (12^\circ\text{C})
T_{\text{deep}}	Deep Soil Core Temperature	283.15	\text{K} \ (10^\circ\text{C})
R_{\downarrow}	Downward Longwave Radiation	260.0	\text{W m}^{-2}
f	Coriolis Parameter (at \sim 45^\circ\text{N})	1.0 \times 10^{-4}	\text{s}^{-1}
Turbulence & Boundary Layer Internals
Parameter	Description	Baseline Value	Units
\varepsilon	Singular Perturbation Parameter	0.01	Dimensionless
\delta	Background Mixing Parameter	1.0 \times 10^{-4}	\text{m}^2\text{s}^{-2}
\sigma	Mechanical Shear Production Weight	0.15	Dimensionless
K	Buoyant Destruction Weight	0.40	\text{m}^2\text{s}^{-3}
\alpha	Viscous Dissipation Coeff	0.25	\text{s}^{-1}
\beta	Stratification Sensitivity Parameter	15.0	Dimensionless
h	Coupling Bulk Scale Height	50.0	\text{m}
Thermal Properties (Surface Energy Budget)
Parameter	Description	Baseline Value	Units
\sigma_{SB}	Stefan-Boltzmann Constant	5.67 \times 10^{-8}	\text{W m}^{-2}\text{K}^{-4}
\lambda	Soil Thermal Conductivity	1.2	\text{W m}^{-1}\text{K}^{-1}
d_{\text{soil}}	Effective Soil Layer Depth	0.5	\text{m}
\rho c_p	Volumetric Heat Capacity of Air	1200.0	\text{J m}^{-3}\text{K}^{-1}
C_{\text{skin}}	Thermal Capacity of Skin Layer	2.0 \times 10^{4}	\text{J m}^{-2}\text{K}^{-1}
4. Geometric Features of the 4D Phase Space
When analyzing this mathematical system, the geometric structures shift from your previous lower-dimensional derivations in three important ways:
1. The Critical Manifold \mathcal{M}_0: Defined strictly in the limit \varepsilon \to 0 by setting the fast equation to zero (f = 0). This yields the active turbulent sheet where: e^* = \frac{1}{\alpha} \left[ \frac{\sigma}{h^2}(U^2 + V^2) - K \cdot G(T_s) \right]
2. The Trapped Laminar State: If \frac{\sigma}{h^2}(U^2 + V^2) < K \cdot G(T_s), the term inside the brackets becomes negative. Because real-world kinetic energy cannot be negative, the regularization parameter \delta holds the system on the background mixing floor where e \approx 0.
3. The Rank-Deficient Fold (\mathcal{C}_{\text{fold}}): Substituting e^* into the prognostic T_s equation yields the reduced slow flow on the manifold. Differentiating this with respect to the coordinate T_s defines the fold line. Because U^2 + V^2 is a circular symmetric term, the fold curve is an open, parabolic boundary wrapped around the (U, V) wind velocity plane.

