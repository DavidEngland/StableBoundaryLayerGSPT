# Diagnostic: SCM Publication Suite

- Diagnostic ID: `DIAG-SCM-PUB-001`
- Scope: vertically resolved GSPT-SCM runs (`scm/scm.jl`)
- Purpose: provide a compact, publication-quality diagnostic hierarchy with minimal redundancy

## Level 1: State Evolution

Primary time-series diagnostics for each run:

- skin temperature `T_s(t)`
- near-surface air temperature
- surface sensible heat flux `H`
- ground heat flux `G`
- net radiation `R_n`
- friction velocity `u_*`
- boundary-layer depth estimate
- Richardson number bounds
- Monin-Obukhov length estimate
- selected-height eddy diffusivities
- maximum shear
- surface wind speed
- geostrophic wind speed

Implementation: `compute_time_series_diagnostics` in `scm/scm_diagnostics.jl`.

## Level 2: Vertical Profiles

Store profile snapshots every 10 to 30 minutes:

- `U(z)`
- `V(z)`
- wind speed and direction
- potential temperature `theta(z)`
- temperature gradient
- `K_m(z)` and `K_h(z)` on faces
- mixing length `ell(z)`
- local shear
- stability diagnostics (`Ri_g`, closure state)

Implementation: `sample_profile_snapshots` and profile payload fields from `compute_snapshot_diagnostics`.

## Level 3: Time-Height Contours (Hovmoller)

Generate contour payloads for:

- wind speed
- zonal wind
- meridional wind
- potential temperature
- eddy diffusivities (`K_m`, `K_h`)
- shear
- Richardson number
- manifold fields (`Delta`, `e_xi`)

Implementation: `build_hovmoller_payload` in `scm/scm_diagnostics.jl`.

## Level 4: Numerical Verification

Track numerical and closure integrity:

- minimum and maximum diffusivity
- minimum and maximum Richardson number
- surface energy closure residual
- near-fold fraction based on `|Delta - delta/l0|`

Implementation: `compute_numerical_verification`.

## GSPT-Focused Diagnostics

Novel manifold-centric diagnostics:

- `Delta(z,t)` and regularized embedding `e_xi(Delta)`
- scatter of `Delta` vs `K_m`
- production-buoyancy balance proxies through closure terms
- fold-proximity indicator from surface closure state

These diagnostics separate GSPT-SCM analysis from conventional SCM reporting.

## Recommended Core Manuscript Figures (8)

1. Time series of `T_s`, sensible heat flux, and `u_*`.
2. Time-height contour of wind speed with LLJ evolution.
3. Time-height contour of potential temperature with inversion growth.
4. Profiles of `U`, `theta`, and `K_m` at representative times.
5. Surface energy budget (`R_n`, `H`, `G`, storage).
6. Phase portrait on regularized manifold (`Delta` vs `e_xi`).
7. Eddy diffusivity response versus stability (`Ri_g` or equivalent).
8. Fold-proximity diagnostic versus time.
