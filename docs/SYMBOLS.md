# Symbols Reference

Auto-generated from `spec/symbols.yaml`. Do not edit by hand.

## State Variables and Coordinates

| Symbol | Meaning | Units | Code Mapping |
| --- | --- | --- | --- |
| `T_s` | Surface skin temperature | K | `Ts` |
| `U` | Zonal wind component | m s^-1 | `U` |
| `V` | Meridional wind component | m s^-1 | `V` |
| `e` | Turbulent kinetic energy | m^2 s^-2 | `e` |

## Fast-Slow and Regularization Parameters

| Symbol | Meaning | Units | Code Mapping |
| --- | --- | --- | --- |
| `alpha_safe` | Safeguard gate width | - | `alpha_safe` |
| `beta_T` | Thermal stability sensitivity | - | `beta_t` |
| `delta` | Background TKE floor | m^2 s^-2 | `delta` |
| `epsilon` | Fast-slow timescale ratio | - | `epsilon` |
| `sigma_e` | Fast linear TKE term | s^-1 | `sigma_e` |

## Closure and Surface Coupling Parameters

| Symbol | Meaning | Units | Code Mapping |
| --- | --- | --- | --- |
| `C_H` | Heat exchange coefficient | - | `CH` |
| `C_skin` | Surface thermal capacity | J m^-2 K^-1 | `C_skin` |
| `K` | Buoyant destruction scale | m s^-2 | `K` |
| `gamma` | Effective drag coefficient | s^-1 | `gamma` |
| `l0` | Master mixing length | m | `l0` |

## Diagnostics and Geometric Invariants

| Symbol | Meaning | Units | Code Mapping |
| --- | --- | --- | --- |
| `Delta` | Fold invariant forcing diagnostic | m^2 s^-2 | `Delta` |
| `Delta_fold` | Fold forcing threshold | m^2 s^-2 | `Delta_fold` |
| `e_fold` | Fold TKE level | m^2 s^-2 | `e_fold` |
| `q_fold` | Fold turbulent amplitude | m s^-1 | `q_fold` |
