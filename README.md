# StableBoundaryLayerGSPT

StableBoundaryLayerGSPT is a Julia-first, reproducible scientific pipeline where the manuscript is generated from code and data artifacts.

## Milestone Focus

- v0.1 Reference Theory (no observational datasets required)
	- complete mathematical model contract scaffold
	- stable API and stable CLI surface
	- scientific validation tier definitions (L0-L4)
	- canonical synthetic benchmark suite scaffold
	- reproducible synthetic publication bundle

- Planned progression
	- v0.2 CASES99
	- v0.3 FLOSS
	- v0.4 multi-campaign comparison
	- v1.0 publication release

## Principles

- Scientific contracts first (`spec/`)
- One public API per source module
- Explicit validation gate before visualization and reporting
- Machine-readable provenance for generated artifacts
- Dual manuscript output paths (TeX-first and Markdown-first)

## Quick Start

```bash
cd /Users/davidengland/Documents/GitHub/StableBoundaryLayerGSPT
julia --project=. -e 'using Pkg; Pkg.instantiate()'
make pipeline-cases99
make test

# Reference CLI examples
bash scripts/stablebl build --dataset CASES99
bash scripts/stablebl diagnostics --dataset CASES99 --nsamples 120 --ngrid 40 --seed 7
bash scripts/stablebl paper --dataset CASES99
bash scripts/stablebl bundle --synthetic --dataset CASES99
```

`scripts/stablebl paper` now auto-generates the 4D solver trajectory and diagnostic geometry plot, writes it under `reports/generated/figures/`, assembles `reports/generated/paper.tex`, and compiles the PDF so collaborators can reproduce manuscript figures without manual steps.

## Current Status

- Phase -1 bootstrap complete: spec layer scaffolded
- Phase 0/1 bootstrap complete: package skeleton, stage runner, and manifest/provenance writing in place
- v1 dataset stubs configured: CASES99, FLOSS

## Repository Layout

```text
src/            Julia modules
spec/           Canonical scientific contracts
benchmarks/     Canonical synthetic benchmark definitions
data/           Raw and processed dataset roots
results/        Stage outputs by dataset
reports/        Generated manuscript fragments
templates/      TeX/Markdown templates
figures/        Generated figures and metadata
tables/         Generated tables and metadata
scripts/        Entrypoint scripts
test/           Module-mirrored test tree
```

## Executable Specifications

The reference-theory contracts are maintained as machine-readable specifications in `spec/`.
Core v0.1 contracts:

- `spec/fast_slow.yaml`
- `spec/critical_manifold.yaml`
- `spec/fold_detection.yaml`
- `spec/hysteresis.yaml`
- `spec/llj.yaml`
- `spec/validation/tiers.yaml`

These define inputs/outputs/constraints/properties independent of implementation details.

## One-Command Synthetic Bundle

Generate a reproducible synthetic reference bundle:

```bash
bash scripts/stablebl bundle --synthetic --dataset CASES99
```

Outputs are written under `bundle/` and include manuscript artifacts, figures, diagnostics, specs, benchmarks, provenance, manifest, checksums, and a zip archive.

## Authoring Workflow

- Edit scientific contracts in `spec/` (canonical equations, diagnostics, outputs, datasets).
- Edit narrative section sources in `templates/sections/`.
- Do not manually edit `reports/generated/`; it is overwritten by pipeline runs.