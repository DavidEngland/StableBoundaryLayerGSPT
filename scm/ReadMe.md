# GSPT-SCM

Global Bifurcation and Smoothly Embedded Single Column Model (SCM) for nocturnal Stable Boundary Layer (SBL) simulation.

This module implements a vertically resolved 1D column solver using a smooth $C^\infty$ GSPT-inspired closure. The objective is to preserve physical transition behavior near turbulence collapse while avoiding hard discontinuities that destabilize implicit ODE solvers.

## Why This Model

Traditional SBL closures often suffer from abrupt regime switches near high Richardson number conditions. This SCM replaces hard branching with a smooth embedding that regularizes the shear-buoyancy transition and keeps diffusivities differentiable.

## Core Features

- Dual-safe RHS design in `scm_gspt_tendencies!` with preallocated workspace buffers for standard runs and typed scratch buffers when AD dual numbers are present.
- Smooth regularization of the transition manifold through $(\delta, \xi)$.
- Vertically resolved momentum and thermal diffusion with consistent surface coupling.
- Configurable Jacobian strategy: `--solver-jacobian {autodiff|finite}` and `--jacobian-sparsity {dense|banded}`.
- Fail-fast anomaly guard for non-physical skin temperatures with structured failure summaries.
- End-to-end pipeline for run, diagnostics, plotting, and LaTeX report generation.

## Governing Embedded Closure

The model computes local production minus buoyancy destruction as

$$
\Delta = \eta \, \ell_z^2 \left[\left(\frac{\partial U}{\partial z}\right)^2 + \left(\frac{\partial V}{\partial z}\right)^2\right]
- K_{\mathrm{buoy}} \left(\exp\left(\beta\,\frac{\partial \theta}{\partial z}\,\frac{\ell_z}{\theta_a}\right) - 1\right)
$$

with smooth embedding

$$
e^*_{\xi} = \frac{1}{2}\left[(\ell_0\Delta - \delta) + \sqrt{(\ell_0\Delta - \delta)^2 + \xi^2}\right],
\qquad
K_m = \ell_z\sqrt{e^*_{\xi} + \delta}
$$

## State Layout and Grid

For $N$ vertical levels, the state vector is $X \in \mathbb{R}^{3N+1}$:

- $X_1 = T_s$: surface skin temperature.
- $X_{2: N+1} = U$: zonal wind profile.
- $X_{N+2:2N+1} = V$: meridional wind profile.
- $X_{2N+2:3N+1} = \theta$: potential temperature profile.

Diffusivities $K_m$ and $K_h$ are evaluated on faces ($1\dots N-1$), while prognostic variables are centered at cell centers.

The Jacobian prototype in the SCM driver uses this block state layout and a local nearest-neighbor stencil, so each interior node only couples to $(i-1, i, i+1)$ along the vertical column.

## Quick Start

Run the full SCM workflow from repository root:

```bash
make scm-all
```

Case-specific presets:

```bash
make run-idealized-sbl
make run-gabls1
make run-sheba
make run-sheba-fd
make run-sheba-high-top
make run-sheba-high-top-fd
```

Verification smoke test (run + plots + report + checks):

```bash
make scm-verify
```

## CLI Workflow

1. Run and produce artifacts (`payload.jld2`, `summary.json`, `time_series.csv`):

```bash
julia --project=. scm/run_case.jl \
    --case sheba \
    --duration 12.0 \
    --dt 10.0 \
    --grid-size 250 \
    --dz 2.0 \
    --solver-jacobian autodiff \
    --jacobian-sparsity banded \
    --theta-lapse-rate 0.004 \
    --use-nonlocal-h true \
    --h 500 \
    --nonlocal-h-weight 0.5 \
    --nonlocal-h-min 20.0 \
    --nonlocal-h-max 500.0 \
    --k-min-surf 1e-3 \
    --ts-min 220.0 \
    --ts-max 350.0 \
    --debug-print false \
    --outdir results/sheba_high_top
```

1. Generate figure suite:

```bash
julia --project=. scm/plot_case.jl \
    --input results/sheba_high_top/payload.jld2 \
    --outdir results/sheba_high_top/plots \
    --format png
```

1. Render SCM LaTeX case report:

```bash
julia --project=. scm/render_case_report.jl \
    --summary results/sheba_high_top/summary.json \
    --template templates/scm_case_report.tex.mustache \
    --out results/sheba_high_top/sheba_250x2m_12h_report.tex
```

1. Compile combined SCM portfolio from all current semantic report wrappers under `results/`:

```bash
make compile-scm-reports
```

## Solver Modes and Performance A/B

Use matching setups to compare solver pathways:

```bash
# Sparse AD Jacobian path (recommended)
make run-sheba-high-top

# Dense finite-difference baseline path
make run-sheba-high-top-fd
```

Inspect `summary.json` in each output directory and compare `solver_summary.rhs_evaluations`, `accepted_steps`, and `rejected_steps`.

## Surface Coupling

The atmosphere is coupled to the land skin temperature through the surface energy budget:

$$
\frac{dT_s}{dt} = \frac{1}{C_{\mathrm{skin}}}
\left(R_{\mathrm{down}} - \sigma T_s^4 + \rho C_p\,\mathrm{flux}_{H,\mathrm{surf}} - \frac{\lambda_s(T_s - T_{\mathrm{deep}})}{d_{\mathrm{soil}}}\right)
$$

Here $\mathrm{flux}_{H,\mathrm{surf}}$ is positive downward toward the surface. A positive sensible heat flux therefore warms the skin layer.

This coupling is integrated in the same stiff solve as momentum and thermal profiles, improving numerical robustness during strongly stable transitions.

## Outputs

Each run produces:

- `summary.json`: solver and verification metrics.
- `summary.json` (failed run): structured anomaly metadata if the guard aborts integration.
- `time_series.csv`: scalar diagnostic time series.
- `payload.jld2`: full diagnostic payload for figure generation.
- `plots/`: figure suite (`fig01` through `fig08` by default).
- `<semantic>_report.tex`: auto-rendered SCM report section with namespaced labels.
- `<semantic>_report_wrapper.{tex,pdf}`: standalone wrapper for case-level PDF compile.

Note: generated run outputs are intentionally ignored by Git in this repository configuration.
