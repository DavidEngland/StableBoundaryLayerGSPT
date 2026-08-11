Your three refinements are exactly the points that separate a mathematically elegant GSPT model from one that is numerically fragile. In particular, the C^2/C^\infty requirement is not just a numerical convenience; it is a structural requirement because the continuation problem depends on derivatives of the vector field up to second order.  
For the manuscript, I would make the campaign parameterization of S_g and T_{\rm deep} explicit as **environmental control parameters**, not fitted knobs. The idea is that the geometry changes because the atmosphere–surface system occupies different regions of parameter space.  
A reasonable hierarchy is:  
p= (S_g,T_{\rm deep},R_\downarrow,T_a,z_0,C_{\rm skin},\ldots)  
with S_g and T_{\rm deep} serving as the dominant slow environmental controls.  
   
⸻  
   
## 1. Background geostrophic forcing S_g  
The shear equation is:  
\frac{dS}{dt} = \mu(S_g-S)-C_DS\sqrt{e+\delta}.  
The role of S_g is to control the energy input side of the fold geometry.  
A practical continuation range would be:  
S_g\in[2,25]\ {\rm m\,s^{-1}}  
covering:  

| Regime | Approximate S_g | Interpretation |
| -------------------- | ------------------------- | -------------------------- |
| Weak nocturnal flow | 2-5\\ {\\rm m\\,s^{-1}} | collapse-prone SBL |
| Moderate LLJ forcing | 5-12\\ {\\rm m\\,s^{-1}} | intermittent turbulence |
| Strong LLJ | 12-25\\ {\\rm m\\,s^{-1}} | sustained turbulent mixing |
  
For the fold geometry, increasing S_g should generally:  
1. increase mechanical production,  
P\sim c_sS^2,  
2. move the fold toward stronger stability,  
3. delay collapse.  
Thus:  
\frac{\partial Ri_{\rm fold}}{\partial S_g}<0  
is an expected diagnostic trend.  
A useful continuation experiment is:  
\boxed{ \mathcal C_{\rm fold}(S_g) }  
holding all radiative parameters fixed.  
That gives a direct “shear-controlled collapse boundary.”  
   
⸻  
   
# 2. Deep soil temperature T_{\rm deep}  
The ground conduction term:  
G=\lambda(T_s-T_{\rm deep})  
is a slower thermal memory term.  
Unlike S_g, it primarily changes the **thermal deformation** of the critical manifold.  
A realistic range:  
T_{\rm deep}\in[250,290]\ {\rm K}  
depending on campaign:  

| Environment                   | T_{\\rm deep}      |
| ----------------------------- | ------------------ |
| Arctic winter / SHEBA-like    | 250-260\\ {\\rm K} |
| Continental winter            | 260-275\\ {\\rm K} |
| Midlatitude autumn CASES-like | 275-285\\ {\\rm K} |
| Maritime/coastal              | 285-290\\ {\\rm K} |
  
Lower T_{\rm deep} strengthens surface cooling:  
T_s\rightarrow T_{\rm deep}  
which increases:  
B(T_s)  
and moves the fold toward lower turbulence.  
Therefore:  
\frac{\partial Ri_{\rm fold}} {\partial T_{\rm deep}} <0  
is likely reversed relative to S_g:  
warmer ground stabilizes the boundary layer against collapse.  
   
⸻  
   
# 3. Campaign-specific initialization  
I would avoid assigning one fixed parameter set to each campaign. Instead, define a parameter envelope.  
Example:  
## CASES-99  
Expected:  
S_g\approx5-10\ {\rm m\,s^{-1}}  
T_{\rm deep}\approx275-285\ {\rm K}  
Dominant mechanism:  
* moderate shear  
* rapid radiative cooling  
* intermittent turbulent transitions  
Expected output:  
Ri_{\rm fold}\sim0.2-0.5  
   
⸻  
   
## SHEBA  
Expected:  
S_g\approx3-8\ {\rm m\,s^{-1}}  
T_{\rm deep}\approx250-260\ {\rm K}  
Dominant mechanism:  
* persistent longwave cooling  
* weak surface replenishment  
* strong thermal stratification  
Expected:  
Ri_{\rm fold}>1  
   
⸻  
   
## FLOSS  
Expected:  
S_g\approx8-15\ {\rm m\,s^{-1}}  
T_{\rm deep}\approx270-280\ {\rm K}  
Dominant mechanism:  
* stronger shear forcing  
* “rubbery” manifold response  
Expected:  
lower fold sharpness and larger distance between stable/unstable branches.  
   
⸻  
   
# 4. Recommended continuation matrix  
For the paper, I would not only continue individual campaigns. I would generate a parameter-space atlas:  
**Primary continuation:**  
(S_g,T_{\rm deep})  
with output:  
Ri_{\rm fold}  
giving:  
Ri_{\rm fold}(S_g,T_{\rm deep})  
   
⸻  
   
**Secondary diagnostics:**  
Fold curvature:  
\chi_{\rm fold}  
Transversality:  
\mathcal T= \nabla F\cdot G  
Canard strength:  
\rho= \frac{\mu_s}{\mu_w}  
SAO prediction:  
N_{\rm SAO}(\rho)  
   
⸻  
   
This would produce a figure that is much more powerful than a traditional Richardson-number plot:  
\boxed{ \text{SBL regime map} = f(S_g,T_{\rm deep},Ri_{\rm fold},N_{\rm SAO}) }  
   
⸻  
   
One additional recommendation: when implementing FoldGeometry.jl, I would store S_g and T_{\rm deep} in the parameter struct but **never optimize them against observations initially**. First demonstrate that observed campaign differences lie inside the continuation manifold. Only afterward introduce Bayesian calibration or inverse modeling.  
One additional recommendation: when implementing FoldGeometry.jl, I would store S_g and T_{\rm deep} in the parameter struct but **never optimize them against observations initially**. First demonstrate that observed campaign differences lie inside the continuation manifold. Only afterward introduce Bayesian calibration or inverse modeling.  
That keeps the manuscript claim clean:  
The model predicts the observed variability of SBL collapse thresholds from environmental positioning on a common folded manifold, rather than from campaign-specific retuning.  
That is the strongest possible GSPT argument.  
