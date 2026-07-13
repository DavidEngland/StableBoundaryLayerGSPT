.PHONY: bootstrap pipeline-cases99 pipeline-floss pipeline-sheba pipeline-all run-solver-cases99 run-solver-floss run-solver-sheba run-solver-all bifurcation-cases99 bifurcation-floss bifurcation-sheba bifurcation-all assemble-manuscript stablebl-build stablebl-build-sheba stablebl-diagnostics stablebl-diagnostics-sheba stablebl-paper stablebl-paper-sheba stablebl-bundle-synthetic test clean

bootstrap:
	julia --project=. -e 'using Pkg; Pkg.instantiate()'

pipeline-cases99:
	julia --project=. scripts/run_pipeline.jl --dataset CASES99

pipeline-floss:
	julia --project=. scripts/run_pipeline.jl --dataset FLOSS

pipeline-sheba:
	julia --project=. scripts/run_pipeline.jl --dataset SHEBA

pipeline-all:
	$(MAKE) pipeline-cases99
	$(MAKE) pipeline-floss
	$(MAKE) pipeline-sheba

run-solver-cases99:
	julia --project=. scripts/run_4d_solver.jl --dataset CASES99

run-solver-floss:
	julia --project=. scripts/run_4d_solver.jl --dataset FLOSS

run-solver-sheba:
	julia --project=. scripts/run_4d_solver.jl --dataset SHEBA

run-solver-all:
	$(MAKE) run-solver-cases99
	$(MAKE) run-solver-floss
	$(MAKE) run-solver-sheba

bifurcation-cases99:
	julia --project=. scripts/sweep_bifurcation.jl --dataset CASES99

bifurcation-floss:
	julia --project=. scripts/sweep_bifurcation.jl --dataset FLOSS

bifurcation-sheba:
	julia --project=. scripts/sweep_bifurcation.jl --dataset SHEBA

bifurcation-all:
	$(MAKE) bifurcation-cases99
	$(MAKE) bifurcation-floss
	$(MAKE) bifurcation-sheba

assemble-manuscript:
	julia --project=. scripts/assemble_manuscript.jl --dataset CASES99

stablebl-build:
	bash scripts/stablebl build --dataset CASES99

stablebl-build-sheba:
	bash scripts/stablebl build --dataset SHEBA

stablebl-diagnostics:
	bash scripts/stablebl diagnostics --dataset CASES99

stablebl-diagnostics-sheba:
	bash scripts/stablebl diagnostics --dataset SHEBA

stablebl-paper:
	bash scripts/stablebl paper --dataset CASES99

stablebl-paper-sheba:
	bash scripts/stablebl paper --dataset SHEBA

stablebl-bundle-synthetic:
	bash scripts/stablebl bundle --synthetic --dataset CASES99

test:
	julia --project=. -e 'using Pkg; Pkg.test()'

clean:
	find results -type d -name 'run_*' -prune -exec rm -rf {} +
	find results -type d -name 'bifurcation_*' -prune -exec rm -rf {} +
	find reports/generated -type f ! -name '.gitkeep' -delete
	find figures -type f \( -name '*.md' -o -name '*.tex' -o -name '*.json' \) -delete
	find tables -type f \( -name '*.md' -o -name '*.tex' -o -name '*.json' \) -delete
	if [ -d bundle ]; then find bundle -mindepth 1 -maxdepth 1 -exec rm -rf -- {} \;; fi