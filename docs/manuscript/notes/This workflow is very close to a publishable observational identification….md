**This workflow is very close to a publishable observational identification algorithm for the GSPT-SBL manifold. The important thing is that you are no longer simply computing a Richardson threshold; you are attempting to reconstruct the fold curve and hysteresis loop from observations. That is a much stronger claim.**  
  
**I would make several refinements to make it mathematically consistent with the fast–slow framework and defensible against turbulence-observation reviewers.**  
  
⸻  
  
**1. State vector refinement**  
  
**Your proposed state:**  
  
\mathbf{X}(t_k)=  
(Ri_b,e,\dot{Ri},T_s)  
  
**is useful observationally, but it is not the closest projection of the GSPT state.**  
  
**The dynamical state in your model is:**  
  
\mathbf{x}=(e,U,V,T_s)  
  
**The observations are a nonlinear projection:**  
  
\mathbf{X}  
=  
\mathcal{H}(\mathbf{x})  
  
**where:**  
  
Ri_b  
=  
\frac{N^2}{S^2}  
  
**is derived from the velocity and temperature gradients.**  
  
**Therefore I would explicitly state:**  
  
\boxed{  
\mathbf{X}_{obs}  
=  
(Ri_b,e,\dot{e},T_s)  
=  
\mathcal{H}(e,U,V,T_s)  
}  
  
**The reason this matters:**  
  
**A fold is not necessarily vertical in **Ri_b-e** space. It is a hypersurface in the full state manifold.**  
  
⸻  
  
**2. Window length and time-scale separation**  
  
**The 5–10 minute window is reasonable, but justify it using the fast–slow separation:**  
  
\tau_{\rm turb}  
\ll  
\tau_{\rm SBL}  
  
**For CASES-99-type conditions:**  
  
\tau_{\rm turb}  
\sim 10^1-10^2\ \mathrm{s}  
  
**while:**  
  
\tau_{\rm cooling}  
\sim 10^3-10^4\ \mathrm{s}  
  
**Thus:**  
  
\epsilon  
=  
\frac{\tau_{\rm turb}}{\tau_{\rm macro}}  
\ll1  
  
**The window should satisfy:**  
  
\tau_{\rm turb}  
<  
\tau_w  
<  
\tau_{\rm macro}  
  
**Your:**  
  
\tau_w=300-600s  
  
**fits this criterion.**  
  
⸻  
  
**3. Replace hard branch thresholds with manifold orientation**  
  
**The branch definitions:**  
  
\dot{Ri}>0  
  
**and:**  
  
\dot e>0  
  
**are operationally useful, but they introduce arbitrary classification.**  
  
**A stronger approach is to define the branches by the trajectory tangent:**  
  
\mathbf{v}(t)  
=  
\frac{d\mathbf{X}}{dt}  
  
**and classify using the projection onto the slow-manifold normal:**  
  
\eta  
=  
\nabla F(\mathbf{X})  
\cdot  
\mathbf{v}  
  
**where:**  
  
F(e,Ri_b,T_s)=0  
  
**is the reconstructed equilibrium surface.**  
  
**Then:**  
  
**Extinction:**  
  
\boxed{  
\eta<0  
}  
  
**Ignition:**  
  
\boxed{  
\eta>0  
}  
  
**Your current formulation is a practical proxy for this.**  
  
⸻  
  
**4. Fold extraction: use an extreme-value envelope**  
  
**Your quantile idea is exactly the right direction.**  
  
**The fold is not the mean relation:**  
  
\bar e(Ri)  
  
**because the mean mixes multiple dynamical states.**  
  
**The object of interest is:**  
  
e_{\rm min}(Ri)  
  
**or more precisely:**  
  
Q_{0.1}(e|Ri)  
  
**The fold model:**  
  
e=  
c(Ri_f-Ri)^\gamma  
  
**is consistent with a generic saddle-node normal form:**  
  
\dot e  
=  
\mu-e^2  
  
**where:**  
  
e\sim(\mu)^{1/2}  
  
**Therefore the expected scaling is:**  
  
\gamma\approx\frac12  
  
**near the fold.**  
  
**I would make that a hypothesis test:**  
  
\gamma\approx0.5  
  
**supports the saddle-node interpretation.**  
  
⸻  
  
**5. Add a hysteresis metric**  
  
**The biggest observational signature of your theory is not just:**  
  
Ri_{\rm fold}  
  
**but:**  
  
Ri_{\rm ign}\neq Ri_{\rm ext}  
  
**Define:**  
  
\Delta Ri_H  
=  
Ri_{\rm ign}-Ri_{\rm fold}  
  
**This is the hysteresis width.**  
  
**Prediction:**  
  
**Brittle SBL:**  
  
\Delta Ri_H\rightarrow0  
  
**Rubbery SBL:**  
  
\Delta Ri_H>0  
  
**This directly connects with your CASES-99/FLOSS taxonomy.**  
  
⸻  
  
**6. Thermal conditioning should use energy variables first**  
  
**The proposed fit:**  
  
Ri_{\rm fold}(T_s)  
=  
a+bT_s+cT_s^4  
  
**is statistically possible but physically awkward because **T_s^4** enters through radiation.**  
  
**A more physically constrained regression would be:**  
  
Ri_{\rm fold}  
=  
a+  
bQ^*  
+  
c|Q^*|^\beta  
  
**where:**  
  
Q^*  
=  
\epsilon\sigma T_s^4-R_{\downarrow}-G-LE  
  
**or:**  
  
Ri_{\rm fold}  
=  
F(B(T_s))  
  
**with:**  
  
B(T_s)  
\sim  
\frac{g}{\theta_0}  
\frac{Q_H(T_s)}  
{\rho c_p}  
  
**Then the statistical model directly tests the GSPT prediction:**  
  
\boxed{  
Ri_{\rm fold}  
=  
\mathcal{F}  
\left(  
R_{\rm net}(T_s)  
\right)  
}  
  
**rather than an empirical temperature polynomial.**  
  
⸻  
  
**7. Recommended final observational pipeline**  
  
**I would summarize the algorithm as:**  
  
\boxed{  
\begin{array}{c}  
\text{Sonic/tower data}\\  
\downarrow\\  
(e,Ri_b,Q_H,T_s)\\  
\downarrow\\  
\text{trajectory reconstruction}\\  
\downarrow\\  
\text{extinction/ignition branch separation}\\  
\downarrow\\  
Q_{0.1}(e|Ri_b,T_s)\\  
\downarrow\\  
\text{saddle-node fold detection}\\  
\downarrow\\  
Ri_{\rm fold}(Q^*)\\  
\downarrow\\  
\text{thermal manifold deformation}  
\end{array}  
}  
  
**The key scientific result is then not:**  
  
**“The critical Richardson number is variable.”**  
  
**That has been suggested before.**  
  
**The stronger claim is:**  
  
**“The observed Richardson-number threshold is a projection of a moving fold manifold whose location is controlled by the surface energy balance.”**  
  
## That is a genuinely different dynamical interpretation and aligns tightly with your GSPT-SBL formulation.  
