# Symbols Reference

Auto-generated from `spec/symbols.yaml`. Do not edit by hand.

## State Variables and Coordinates

| Symbol | Meaning | Units | Code Mapping |
| --- | --- | --- | --- |
| `e` | Turbulent kinetic energy | `m^2 s^-2` | `e` |
| `U` | Zonal wind component | `m s^-1` | `U` |
| `V` | Meridional wind component | `m s^-1` | `V` |
| `T_s` | Surface skin temperature | `K` | `Ts` |

## Fast-Slow and Regularization Parameters

| Symbol | Meaning | Units | Code Mapping |
| --- | --- | --- | --- |
| `epsilon` | Fast-slow timescale ratio | --- | `epsilon` |
| `delta` | Background TKE floor | `m^2 s^-2` | `delta` |
| `alpha_safe` | Safeguard gate width | --- | `alpha_safe` |
| `sigma_e` | Fast linear TKE term | `s^-1` | `sigma_e` |
| `beta_T` | Thermal stability sensitivity | --- | `beta_t` |

## Closure and Surface Coupling Parameters

| Symbol | Meaning | Units | Code Mapping |
| --- | --- | --- | --- |
| `l0` | Master mixing length | `m` | `l0` |
| `K` | Buoyant destruction scale | `m s^-2` | `K` |
| `C_skin` | Surface thermal capacity | `J m^-2 K^-1` | `C_skin` |
| `gamma` | Effective drag coefficient | `s^-1` | `gamma` |
| `C_H` | Heat exchange coefficient | --- | `CH` |
| `K_m` | Eddy viscosity for momentum | `m^2 s^-1` | `K_m` |
| `K_h` | Eddy diffusivity for heat | `m^2 s^-1` | `K_h` |
| `Ri_g` | Gradient Richardson number | --- | `Ri_g` |
| `Pr_t` | Turbulent Prandtl number | --- | `Pr_t` |
| `kappa` | Von Karman constant | --- | `kappa` |
| `alpha` | Legacy gate scaling parameter | --- | `alpha` |
| `beta` | Legacy fast linear TKE coefficient | --- | `beta` |
| `eta` | Shear production efficiency | --- | `eta` |
| `delta_u` | Velocity regularization floor | `m s^-1` | `delta_u` |
| `phi_m` | Momentum stability function | --- | `phi_m` |
| `phi_h` | Heat stability function | --- | `phi_h` |
| `U_g` | Zonal geostrophic wind | `m s^-1` | `U_g` |
| `V_g` | Meridional geostrophic wind | `m s^-1` | `V_g` |
| `T_a` | Reference atmospheric temperature | `K` | `T_a` |
| `T_g` | Deep ground temperature | `K` | `T_deep` |
| `R_down` | Downwelling longwave radiation | `W m^-2` | `R_down` |
| `C_D` | Neutral drag coefficient | --- | `C_D` |
| `C_s` | Surface heat exchange coefficient | --- | `C_s` |
| `h_min` | Minimum effective boundary-layer height | `m` | `h_min` |
| `h_max` | Maximum effective boundary-layer height | `m` | `h_max` |
| `c1` | Mechanical-rotational depth scaling constant | --- | `c1` |
| `c2` | Buoyancy-stratification depth scaling constant | --- | `c2` |

## Diagnostics and Geometric Invariants

| Symbol | Meaning | Units | Code Mapping |
| --- | --- | --- | --- |
| `Delta` | Fold invariant forcing diagnostic | `m^2 s^-2` | `Delta` |
| `S0` | Critical manifold | --- | `S0` |
| `C` | Fold singularity set | --- | `C_fold` |
| `X` | Phase-space domain | --- | `X_domain` |
| `q_fold` | Fold turbulent amplitude | `m s^-1` | `q_fold` |
| `e_fold` | Fold TKE level | `m^2 s^-2` | `e_fold` |
| `Delta_fold` | Fold forcing threshold | `m^2 s^-2` | `Delta_fold` |
