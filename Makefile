.PHONY: bootstrap pipeline-cases99 pipeline-floss pipeline-all bifurcation-cases99 bifurcation-floss bifurcation-all assemble-manuscript stablebl-build stablebl-diagnostics stablebl-paper stablebl-bundle-synthetic test clean

bootstrap:
	julia --project=. -e 'using Pkg; Pkg.instantiate()'

pipeline-cases99:
	julia --project=. scripts/run_pipeline.jl --dataset CASES99

pipeline-floss:
	julia --project=. scripts/run_pipeline.jl --dataset FLOSS

pipeline-all:
	$(MAKE) pipeline-cases99
	$(MAKE) pipeline-floss

bifurcation-cases99:
	julia --project=. scripts/sweep_bifurcation.jl --dataset CASES99

bifurcation-floss:
	julia --project=. scripts/sweep_bifurcation.jl --dataset FLOSS

bifurcation-all:
	$(MAKE) bifurcation-cases99
	$(MAKE) bifurcation-floss

assemble-manuscript:
	julia --project=. scripts/assemble_manuscript.jl --dataset CASES99

stablebl-build:
	bash scripts/stablebl build --dataset CASES99

stablebl-diagnostics:
	bash scripts/stablebl diagnostics --dataset CASES99

stablebl-paper:
	bash scripts/stablebl paper --dataset CASES99

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