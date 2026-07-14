.PHONY: bootstrap pipeline-cases99 pipeline-floss pipeline-sheba pipeline-all run-solver-cases99 run-solver-floss run-solver-sheba run-solver-all bifurcation-cases99 bifurcation-floss bifurcation-sheba bifurcation-all assemble-manuscript paper-all stablebl-build stablebl-build-sheba stablebl-diagnostics stablebl-diagnostics-sheba stablebl-paper stablebl-paper-sheba stablebl-bundle-synthetic scm-run scm-plot scm-report scm-all scm-verify run-gabls1 run-idealized-sbl test clean

DATASET ?= CASES99

SCM_CASE ?= gabls1
SCM_DURATION ?= 9.0
SCM_DT ?= 30.0
SCM_GRID_SIZE ?= 80
SCM_DZ ?= 2.0
SCM_PROFILE_EVERY ?= 1800
SCM_OUTDIR ?= results/$(SCM_CASE)
SCM_PLOT_FORMAT ?= png
SCM_PLOT_DPI ?= 200
SCM_REPORT_TEMPLATE ?= templates/scm_case_report.tex.mustache

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
	julia --project=. scripts/assemble_manuscript.jl --dataset $(DATASET)

paper-all:
	$(MAKE) clean
	$(MAKE) run-solver-all
	julia --project=. scripts/sweep_bifurcation.jl --dataset $(DATASET)
	julia --project=. scripts/plot_4d_diagnostics.jl --solution results/$(DATASET)/latest/solution.csv --out reports/generated/figures/4d_sbl_diagnostics.png
	julia --project=. scripts/assemble_manuscript.jl --dataset $(DATASET)
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory reports/generated reports/generated/paper.tex
	pdflatex -interaction=nonstopmode -halt-on-error -output-directory reports/generated reports/generated/paper.tex

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

scm-run:
	julia --project=. scm/run_case.jl --case $(SCM_CASE) --duration $(SCM_DURATION) --dt $(SCM_DT) --grid-size $(SCM_GRID_SIZE) --dz $(SCM_DZ) --profile-every $(SCM_PROFILE_EVERY) --outdir $(SCM_OUTDIR)

scm-plot:
	julia --project=. scm/plot_case.jl --input $(SCM_OUTDIR)/payload.jld2 --outdir $(SCM_OUTDIR)/plots --format $(SCM_PLOT_FORMAT) --dpi $(SCM_PLOT_DPI)

scm-report:
	julia --project=. scm/render_case_report.jl --summary $(SCM_OUTDIR)/summary.json --template $(SCM_REPORT_TEMPLATE) --out $(SCM_OUTDIR)/scm_case_report.tex

scm-all: scm-run scm-plot scm-report

run-gabls1:
	$(MAKE) scm-all SCM_CASE=gabls1 SCM_OUTDIR=results/gabls1

run-idealized-sbl:
	$(MAKE) scm-all SCM_CASE=idealized_sbl SCM_OUTDIR=results/idealized_sbl

scm-verify:
	@echo "Running SCM diagnostic pipeline verification..."
	@julia --project=. scm/run_case.jl --case idealized_sbl --duration 0.1 --dt 30.0 --grid-size 40 --dz 4.0 --outdir results/scm_verify --save-jld2 true
	@echo "Checking output artifacts..."
	@[ -s results/scm_verify/payload.jld2 ] || (echo "Verification FAILED: payload.jld2 missing or empty"; exit 1)
	@[ -s results/scm_verify/time_series.csv ] || (echo "Verification FAILED: time_series.csv missing or empty"; exit 1)
	@[ -s results/scm_verify/summary.json ] || (echo "Verification FAILED: summary.json missing or empty"; exit 1)
	@echo "Rendering verification plots..."
	@julia --project=. scm/plot_case.jl --input results/scm_verify/payload.jld2 --format png --outdir results/scm_verify/plots
	@[ -s results/scm_verify/plots/fig01_timeseries_ts_h_ustar.png ] || (echo "Verification FAILED: expected figure missing or empty"; exit 1)
	@julia --project=. scm/render_case_report.jl --summary results/scm_verify/summary.json --template $(SCM_REPORT_TEMPLATE) --out results/scm_verify/scm_case_report.tex
	@[ -s results/scm_verify/scm_case_report.tex ] || (echo "Verification FAILED: scm_case_report.tex missing or empty"; exit 1)
	@echo "Verification PASSED: SCM pipeline is end-to-end healthy."

test:
	julia --project=. -e 'using Pkg; Pkg.test()'

clean:
	find results -type d -name 'run_*' -prune -exec rm -rf {} +
	find results -type d -name 'bifurcation_*' -prune -exec rm -rf {} +
	if [ -d reports/generated ]; then find reports/generated -type f ! -name '.gitkeep' -delete; fi
	if [ -d figures ]; then find figures -type f \( -name '*.md' -o -name '*.tex' -o -name '*.json' \) -delete; fi
	if [ -d tables ]; then find tables -type f \( -name '*.md' -o -name '*.tex' -o -name '*.json' \) -delete; fi
	if [ -d bundle ]; then find bundle -mindepth 1 -maxdepth 1 -exec rm -rf -- {} \;; fi