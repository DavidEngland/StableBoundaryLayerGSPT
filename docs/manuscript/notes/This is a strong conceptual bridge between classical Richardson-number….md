**This is a strong conceptual bridge between classical Richardson-number stability theory and your GSPT-SBL framework, but there are a few places where the atmospheric physics needs tightening so that the argument survives scrutiny from boundary-layer experts. The central idea is sound:**  
  
**The apparent “critical Richardson number” is not a universal constant in the nocturnal SBL because the SBL equilibrium manifold itself moves as surface forcing changes.**  
  
**That is exactly the type of interpretation your folded-manifold framework is designed to capture. However, I would adjust the derivation in several ways.**  
  
⸻  
  
**1. The main conceptual correction: **Ri_c** vs. **Ri_{\text{fold}}  
  
**The Miles–Howard theorem concerns linear inviscid parallel shear flow stability:**  
  
Ri(z)=\frac{N^2}{S^2} > \frac14  
  
**everywhere implies linear stability.**  
  
**This is not a turbulence-collapse criterion. The atmospheric SBL collapse threshold is a nonlinear dynamical transition involving:**  
  
* **turbulent kinetic energy production,**  
* **buoyancy destruction,**  
* **mixing length collapse,**  
* **surface exchange,**  
* **intermittent regeneration.**  
  
**Therefore:**  
  
Ri_{\rm fold}\neq Ri_c  
  
**A better notation would be:**  
  
Ri_{\rm fold}=Ri_{\rm fold}(T_s,U_g,Q^*,\ell,\delta,\ldots)  
  
**where the fold represents loss of the turbulent equilibrium branch:**  
  
\frac{\partial \mathcal{F}(e; \mu)}{\partial e}=0  
  
**with**  
  
\mu=\mu(T_s,Q^*,U)  
  
**being the slowly varying control parameter.**  
  
**This avoids implying that the fold is a modified Miles–Howard constant.**  
  
⸻  
  
**2. Surface energy balance as the slow manifold forcing**  
  
**Your equation**  
  
\Pi(T_s)=\frac{\beta^2\ell_0}{4B(T_s)}  
  
**is the GSPT control parameter.**  
  
**The atmospheric interpretation is:**  
  
B(T_s)\sim \text{buoyancy destruction}  
  
**with**  
  
B\approx  
\frac{g}{\theta_0}  
\frac{w'\theta'}{}  
  
**and in first-order closure:**  
  
w'\theta'\approx -K_h  
\frac{\partial \theta}{\partial z}  
  
**giving:**  
  
B(T_s)  
\approx  
\frac{g}{\theta_0}  
K_h  
\frac{\partial\theta}{\partial z}  
  
**The surface boundary condition supplies the gradient:**  
  
Q_H  
=  
-\rho c_p K_h  
\frac{\partial T}{\partial z}  
  
**so:**  
  
\frac{\partial\theta}{\partial z}  
\sim  
-\frac{Q_H}{\rho c_p K_h}  
  
**Therefore:**  
  
B(T_s)  
\sim  
-\frac{g}{\theta_0}  
\frac{Q_H(T_s)}{\rho c_p}  
  
**The important point:**  
  
\boxed{  
B=B(T_s,Q^*,U)  
}  
  
**not a prescribed constant.**  
  
⸻  
  
**3. Surface radiation coupling**  
  
**Your surface energy balance is the correct coupling:**  
  
R_{\rm net}(T_s)  
=  
H+G+LE  
  
**but the sign convention needs care.**  
  
**A common atmospheric convention is:**  
  
Q^*  
=  
R_{\rm SW}+R_{\rm LW}-H-LE-G  
  
**For nocturnal cooling:**  
  
R_{\rm LW}<0  
  
**and the sensible heat flux becomes downward:**  
  
H<0  
  
**The bulk sensible flux:**  
  
H  
=  
\rho c_p C_H U(T_s-T_a)  
  
**so the temperature difference directly modifies the turbulent heat exchange.**  
  
**The surface state is therefore determined implicitly:**  
  
F(T_s,U)  
=  
R_{\rm net}(T_s)  
-\rho c_pC_HU(T_s-T_a)  
-G-LE  
=0  
  
**The fold occurs on this coupled manifold.**  
  
⸻  
  
**4. Better Richardson-number expression**  
  
**Your expression:**  
  
Ri_{\rm fold}(T_s,U)  
=  
\frac{g}{\theta_0}z_{\rm ref}  
\frac{T_a-T_s}{U^2}  
  
**is essentially a bulk Richardson number:**  
  
Ri_b  
=  
\frac{g}{\theta_0}  
\frac{\Delta\theta z}{(\Delta U)^2}  
  
**The dynamic version should be written:**  
  
\boxed{  
Ri_{\rm fold}  
=  
\frac{  
N^2(T_s)  
}{  
S^2(U,e)  
}  
}  
  
**where:**  
  
N^2(T_s)  
=  
\frac{g}{\theta_0}  
\frac{\partial\theta}{\partial z}  
  
**and:**  
  
\frac{\partial\theta}{\partial z}  
\approx  
\frac{  
Q_H(T_s)  
}{  
\rho c_p K_h  
}  
  
**giving:**  
  
\boxed{  
Ri_{\rm fold}(T_s)  
=  
\frac{  
\frac{g}{\theta_0}  
\frac{  
Q_H(T_s)  
}{  
\rho c_pK_h  
}  
}  
{  
S^2  
}  
}  
  
**with:**  
  
Q_H(T_s)  
=  
R_{\rm net}(T_s)-G-LE  
  
**Therefore:**  
  
\boxed{  
Ri_{\rm fold}(T_s)  
=  
\frac{  
\frac{g}{\theta_0}  
\frac{  
R_{\rm net}(T_s)-G-LE  
}{  
\rho c_pK_h  
}  
}  
{  
S^2  
}  
}  
  
**This is the atmospheric form of your GSPT control parameter.**  
  
⸻  
  
**5. Why CASES-99 and SHEBA differ**  
  
**This interpretation is particularly powerful because it explains the observed scatter.**  
  
**CASES-99**  
  
**Grassland:**  
  
* **moderate **T_s**,**  
* **appreciable soil heat storage,**  
* **stronger turbulent regeneration.**  
  
**Thus:**  
  
G>0  
  
**buffers cooling:**  
  
|Q_H|\downarrow  
  
**giving:**  
  
N^2\downarrow  
  
**and:**  
  
Ri_{\rm fold}\sim0.2-0.3  
  
⸻  
  
**SHEBA / Arctic ice**  
  
**The ice surface behaves differently:**  
  
* **very weak conductive compensation,**  
* **persistent radiative loss,**  
* **strong near-surface inversion.**  
  
**Thus:**  
  
R_{\rm net}\rightarrow\text{large negative}  
  
**and:**  
  
N^2(T_s)\uparrow  
  
**while turbulence production can remain intermittent.**  
  
**The fold moves:**  
  
Ri_{\rm fold}\gg0.25  
  
**allowing observed values:**  
  
Ri_b>1  
  
**without violating Miles–Howard because the system is not a fixed parallel shear layer.**  
  
⸻  
  
**6. The key GSPT statement**  
  
**The strongest formulation for your paper would be:**  
  
\boxed{  
Ri_{\rm fold}  
\text{ is not a universal instability constant;  
it is a projection of a moving turbulent equilibrium manifold.}  
}  
  
**The classical picture assumes:**  
  
Ri_c=\text{constant}  
  
**Your framework replaces this with:**  
  
Ri_{\rm fold}  
=  
\mathcal{R}  
(M_{\rm SBL}(T_s,U,Q^*,e))  
  
**where the observed Richardson number is merely the coordinate where trajectories intersect the folded turbulent branch.**  
  
⸻  
  
**7. One additional refinement worth adding**  
  
**The most important missing piece is that **K_h** is itself part of the fast-slow dynamics:**  
  
K_h=K_h(e,\ell,Ri)  
  
**As **e\rightarrow0**:**  
  
K_h\rightarrow K_{h,\min}  
  
**through your **C^\infty** regularization:**  
  
K_h\sim\ell\sqrt{e+\delta}  
  
**Therefore:**  
  
Ri_{\rm fold}  
  
**is not only a function of **T_s**, but:**  
  
\boxed{  
Ri_{\rm fold}  
=  
Ri_{\rm fold}(T_s,U,e,\delta)  
}  
  
**This is exactly where your regularized GSPT formulation differs from MOST: the turbulent diffusivity does not instantaneously collapse; it evolves along the slow manifold.**  
  
**That is the mathematically clean argument connecting:**  
  
## surface radiation → moving equilibrium manifold → dynamic Richardson threshold → intermittent SBL regime transitions.  
