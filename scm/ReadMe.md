# GSPT-SCM

Global Bifurcation and Smoothly Embedded Single Column Model (SCM) for nocturnal Stable Boundary Layer (SBL) simulation.

This module implements a vertically resolved 1D column solver using a smooth $C^\infty$ GSPT-inspired closure. The objective is to preserve physical transition behavior near turbulence collapse while avoiding hard discontinuities that destabilize implicit ODE solvers.

## Why This Model

Traditional SBL closures often suffer from abrupt regime switches near high Richardson number conditions. This SCM replaces hard branching with a smooth embedding that regularizes the shear-buoyancy transition and keeps diffusivities differentiable.

## Core Features

- Zero-allocation RHS design in `scm_gspt_tendencies!` with preallocated workspace buffers.
- Smooth regularization of the transition manifold through $(\delta, \xi)$.
- Vertically resolved momentum and thermal diffusion with consistent surface coupling.
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

## Quick Start

Run the full SCM workflow from repository root:

```bash
make scm-all
```

Case-specific presets:

```bash
make run-idealized-sbl
make run-gabls1
```

Verification smoke test (run + plots + report + checks):

```bash
make scm-verify
```

## CLI Workflow

1. Run and produce artifacts (`payload.jld2`, `summary.json`, `time_series.csv`):

```bash
julia --project=. scm/run_case.jl \
    --case idealized_sbl \
    --duration 12.0 \
    --dt 30.0 \
    --grid-size 100 \
    --dz 5.0 \
    --k-min-surf 1e-3 \
    --ts-min 180.0 \
    --ts-max 350.0 \
    --debug-print false \
    --outdir results/idealized_sbl
```

2. Generate figure suite:

```bash
julia --project=. scm/plot_case.jl \
    --input results/idealized_sbl/payload.jld2 \
    --outdir results/idealized_sbl/plots \
    --format png
```

3. Render SCM LaTeX case report:

```bash
julia --project=. scm/render_case_report.jl \
    --summary results/idealized_sbl/summary.json \
    --template templates/scm_case_report.tex.mustache \
    --out results/idealized_sbl/idealized_sbl_100x5m_12h_report.tex
```

4. Compile combined SCM portfolio from all current semantic report wrappers under `results/`:

```bash
make compile-scm-reports
```

## Minimal Programmatic Example

```julia
using OrdinaryDiffEq
using DifferentialEquations

N = 100
dz = 5.0
z_centers = collect(range(dz / 2, step=dz, length=N))
z_faces = collect(range(dz, step=dz, length=N - 1))

struct SCMWorkspace
        Km::Vector{Float64}
        Kh::Vector{Float64}
end

Base.@kwdef struct SCMParameters{W}
        N::Int
        dz::Float64
        z_centers::Vector{Float64}
        z_faces::Vector{Float64}
        workspace::W
        f::Float64 = 1e-4
        Ug::Float64 = 8.0
        Vg::Float64 = 0.0
        theta_a::Float64 = 265.0
        T_deep::Float64 = 270.0
        delta::Float64 = 1e-4
        K_buoy::Float64 = 0.1
        beta::Float64 = 1.0
        l_0::Float64 = 30.0
        eta::Float64 = 0.5
        xi::Float64 = 1e-3
        C_skin::Float64 = 1e4
        R_down::Float64 = 150.0
        lambda_s::Float64 = 1.0
        d_soil::Float64 = 1.0
        k_min_surf::Float64 = 1e-3
        ts_min::Float64 = 180.0
        ts_max::Float64 = 350.0
        theta_top_bc::Symbol = :relaxation
        theta_top::Float64 = 275.0
        lambda_top::Float64 = 0.01
        debug_print::Bool = false
        profile_every::Float64 = 1800.0
end

ws = SCMWorkspace(zeros(N - 1), zeros(N - 1))
p = SCMParameters(N=N, dz=dz, z_centers=z_centers, z_faces=z_faces, workspace=ws)

X0 = zeros(3N + 1)
X0[1] = 263.0
X0[2:(N + 1)] .= 5.0
X0[(N + 2):(2N + 1)] .= 1.0
X0[(2N + 2):(3N + 1)] .= 265.0

prob = ODEProblem(scm_gspt_tendencies!, X0, (0.0, 43200.0), p)
sol = solve(prob, Rodas5P(autodiff=false), reltol=1e-6, abstol=1e-8)
```

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
