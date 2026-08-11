Here is my take: treating S_g and T_{\text{deep}} as environmental control parameters on a universal manifold—rather than campaign-specific tuning knobs—is the single strongest conceptual thesis of this paper. It directly redefines the "Richardson number universality crisis" in boundary-layer meteorology as an intrinsic geometric projection effect.  
To make this regime map airtight for peer review, here are three high-impact refinements to incorporate into your (S_g, T_{\text{deep}}) continuation strategy:  
**1. Track Co-dimension 2 Bifurcation Points**  
When sweeping the 2D parameter space (S_g, T_{\text{deep}}), the fold curve \mathcal{C}_{\text{fold}} will not remain static; it deforms and can degenerate.  
Using BifurcationKit.jl, explicitly track **Co-dimension 2 singular points** along the fold surface:  
* **Cusp Points (CP):** Where two fold branches meet (F = 0, F_e = 0, F_{ee} = 0). This marks the boundary between continuous, smooth SBL transitions and discontinuous, catastrophic collapses.  
* **Bogdanov-Takens (BT) or Zero-Hopf Points:** Where the fold interacts with slow-subsystem oscillatory dynamics. This pins down the exact origin of canard funnels and determines where MMOs switch to full relaxation oscillations.  
Mapping these Co-dim 2 points directly onto your (S_g, T_{\text{deep}}) atlas creates sharp, mathematically rigorous boundary lines separating **smooth decay**, **pre-burst turbulence whispering**, and **abrupt nocturnal collapse**.  
**2. Non-Dimensionalization for True Universality**  
While physical units (2\text{--}25\text{ m s}^{-1} and 250\text{--}290\text{ K}) are necessary for observational comparison (CASES-99, SHEBA, FLOSS), reviewers in applied math and fluid dynamics will want to see dimensionless parameters.  
Convert (S_g, T_{\text{deep}}) into two characteristic dimensionless control numbers:  
\Pi_1 = \frac{c_s S_g^2}{B(T_{\text{deep}})} \quad \text{(Ratio of geostrophic production to deep thermal sink)} \Pi_2 = \frac{\rho c_p C_H S_g}{\lambda} \quad \text{(Ratio of surface turbulent coupling to ground heat conduction)}  
\Pi_1 = \frac{c_s S_g^2}{B(T_{\text{deep}})} \quad \text{(Ratio of geostrophic production to deep thermal sink)} \Pi_2 = \frac{\rho c_p C_H S_g}{\lambda} \quad \text{(Ratio of surface turbulent coupling to ground heat conduction)}  
By plotting the atlas in (\Pi_1, \Pi_2) space, you prove that CASES-99, SHEBA, and FLOSS are not distinct physical models, but rather specific coordinates on a single dimensionless master surface.  
**3. Asymmetric Collapse vs. Recovery Boundaries (Hysteresis)**  
Because the fold surface is folded in 3D/4D space, the critical Richardson number for **nocturnal collapse** (passing off the fold boundary during evening cooling) is not identical to the threshold for **morning recovery** (re-establishing turbulence as solar radiation or geostrophic shear increases).  
Because the fold surface is folded in 3D/4D space, the critical Richardson number for **nocturnal collapse** (passing off the fold boundary during evening cooling) is not identical to the threshold for **morning recovery** (re-establishing turbulence as solar radiation or geostrophic shear increases).  
In your CampaignProjection.jl module, track two distinct values:  
* Ri_{\text{collapse}}: The fold threshold traversed from the upper stable turbulent branch down to the laminar branch.  
* Ri_{\text{recovery}}: The unfolding threshold required to jump back up to the turbulent branch.  
Demonstrating that Ri_{\text{collapse}} \neq Ri_{\text{recovery}} across the parameter space explains why observational estimates of Ri_{\text{crit}} vary so wildly depending on whether the observational window captured the evening transition or the morning breakout.  
**BifurcationKit 2D Atlas Pipeline (Julia Conceptual Layout)**  
To construct this efficiently using BifurcationKit.jl, structure the continuation sweep around a 2D parameter map:  
To construct this efficiently using BifurcationKit.jl, structure the continuation sweep around a 2D parameter map:  
```
using BifurcationKit, ForwardDiff, Parameters

# Define regularized vector field and parameter struct
@with_kw struct SBLParams{T}
    μ::T = 0.05
    C_D::T = 0.001
    C_skin::T = 2.0e4
    R_down::T = 250.0
    σ_SB::T = 5.67e-8
    λ::T = 5.0
    T_a::T = 273.15
    δ::T = 1e-4
    # Control Parameters
    S_g::T = 10.0
    T_deep::T = 280.0
end

# 1. Continue folds in 1D along S_g
# 2. Perform 2D continuation of Limit Points in (S_g, T_deep) space
# 3. Output map: Ri_fold(S_g, T_deep) and Canard ratio ρ(S_g, T_deep)

```
By presenting this parameter-space atlas as the central synthesis figure, the paper delivers a complete paradigm shift: field campaigns didn't find conflicting physics—they just sampled different coordinates of the exact same GSPT geometry.  
