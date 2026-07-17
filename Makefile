.PHONY: bootstrap pipeline-cases99 pipeline-floss pipeline-sheba pipeline-all run-solver-cases99 run-solver-floss run-solver-sheba run-solver-all bifurcation-cases99 bifurcation-floss bifurcation-sheba bifurcation-all assemble-manuscript paper-all stablebl-build stablebl-build-sheba stablebl-diagnostics stablebl-diagnostics-sheba stablebl-paper stablebl-paper-sheba stablebl-bundle-synthetic scm-run scm-plot scm-report scm-all scm-verify run-gabls1 run-idealized-sbl run-sheba run-sheba-fd run-sheba-high-top run-sheba-high-top-fd compile-scm-reports test clean

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
SCM_SOLVER_JACOBIAN ?= autodiff
SCM_JACOBIAN_SPARSITY ?= dense
SCM_EXTRA_ARGS ?=
SCM_DZ_TAG ?= $(shell echo "$(SCM_DZ)" | sed 's/\.0$$//')
SCM_DURATION_H ?= $(shell echo "$(SCM_DURATION)" | cut -d. -f1)
SCM_REPORT_NAME ?= $(SCM_CASE)_$(SCM_GRID_SIZE)x$(SCM_DZ_TAG)m_$(SCM_DURATION_H)h_report.tex
SCM_REPORT_PATH ?= $(SCM_OUTDIR)/$(SCM_REPORT_NAME)
SCM_REPORT_BASE ?= $(basename $(SCM_REPORT_NAME))
SCM_WRAPPER_TEX_NAME ?= $(SCM_REPORT_BASE)_wrapper.tex
SCM_WRAPPER_PDF_NAME ?= $(SCM_REPORT_BASE)_wrapper.pdf
SCM_WRAPPER_TEX_PATH ?= $(SCM_OUTDIR)/$(SCM_WRAPPER_TEX_NAME)
SCM_WRAPPER_PDF_PATH ?= $(SCM_OUTDIR)/$(SCM_WRAPPER_PDF_NAME)
SCM_WRITE_COMPAT_WRAPPER ?= 0
BIFURCATION_VERBOSE ?= 0
BIFURCATION_LOG_DIR ?= results/_logs

bootstrap:
	julia --project=. -e 'using Pkg; Pkg.instantiate()'

pipeline-cases99:
	julia --project=. scripts/run_pipeline.jl --dataset CASES99

pipeline-floss:
	julia --project=. scripts/run_pipeline.jl --dataset FLOSS

pipeline-sheba:
	julia --project=. scripts/run_pipeline.jl --dataset SHEBA

# Optimized: Parallelization-friendly prerequisite tree
pipeline-all: pipeline-cases99 pipeline-floss pipeline-sheba

run-solver-cases99:
	julia --project=. scripts/run_4d_solver.jl --dataset CASES99

run-solver-floss:
	julia --project=. scripts/run_4d_solver.jl --dataset FLOSS

run-solver-sheba:
	julia --project=. scripts/run_4d_solver.jl --dataset SHEBA

# Optimized: Parallelization-friendly prerequisite tree
run-solver-all: run-solver-cases99 run-solver-floss run-solver-sheba

bifurcation-cases99:
	@mkdir -p $(BIFURCATION_LOG_DIR)
	@log="$(BIFURCATION_LOG_DIR)/bifurcation_CASES99.log"; \
	echo "[bifurcation] CASES99 start (log: $$log)"; \
	if [ "$(BIFURCATION_VERBOSE)" = "1" ]; then \
		julia --project=. scripts/sweep_bifurcation.jl --dataset CASES99 2>&1 | tee "$$log"; \
	else \
		julia --project=. scripts/sweep_bifurcation.jl --dataset CASES99 >"$$log" 2>&1 || { \
			echo "[bifurcation] CASES99 failed (showing last 40 lines)"; \
			tail -n 40 "$$log"; \
			exit 1; \
		}; \
	fi; \
	echo "[bifurcation] CASES99 done"

bifurcation-floss:
	@mkdir -p $(BIFURCATION_LOG_DIR)
	@log="$(BIFURCATION_LOG_DIR)/bifurcation_FLOSS.log"; \
	echo "[bifurcation] FLOSS start (log: $$log)"; \
	if [ "$(BIFURCATION_VERBOSE)" = "1" ]; then \
		julia --project=. scripts/sweep_bifurcation.jl --dataset FLOSS 2>&1 | tee "$$log"; \
	else \
		julia --project=. scripts/sweep_bifurcation.jl --dataset FLOSS >"$$log" 2>&1 || { \
			echo "[bifurcation] FLOSS failed (showing last 40 lines)"; \
			tail -n 40 "$$log"; \
			exit 1; \
		}; \
	fi; \
	echo "[bifurcation] FLOSS done"

bifurcation-sheba:
	@mkdir -p $(BIFURCATION_LOG_DIR)
	@log="$(BIFURCATION_LOG_DIR)/bifurcation_SHEBA.log"; \
	echo "[bifurcation] SHEBA start (log: $$log)"; \
	if [ "$(BIFURCATION_VERBOSE)" = "1" ]; then \
		julia --project=. scripts/sweep_bifurcation.jl --dataset SHEBA 2>&1 | tee "$$log"; \
	else \
		julia --project=. scripts/sweep_bifurcation.jl --dataset SHEBA >"$$log" 2>&1 || { \
			echo "[bifurcation] SHEBA failed (showing last 40 lines)"; \
			tail -n 40 "$$log"; \
			exit 1; \
		}; \
	fi; \
	echo "[bifurcation] SHEBA done"

# Optimized: Parallelization-friendly prerequisite tree
bifurcation-all: bifurcation-cases99 bifurcation-floss bifurcation-sheba

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
	julia --project=. scm/run_case.jl --case $(SCM_CASE) --duration $(SCM_DURATION) --dt $(SCM_DT) --grid-size $(SCM_GRID_SIZE) --dz $(SCM_DZ) --profile-every $(SCM_PROFILE_EVERY) --outdir $(SCM_OUTDIR) --solver-jacobian $(SCM_SOLVER_JACOBIAN) --jacobian-sparsity $(SCM_JACOBIAN_SPARSITY) $(SCM_EXTRA_ARGS)

scm-plot:
	julia --project=. scm/plot_case.jl --input $(SCM_OUTDIR)/payload.jld2 --outdir $(SCM_OUTDIR)/plots --format $(SCM_PLOT_FORMAT) --dpi $(SCM_PLOT_DPI)

scm-report:
	@echo "Rendering semantic report: $(SCM_REPORT_PATH)"
	julia --project=. scm/render_case_report.jl --summary $(SCM_OUTDIR)/summary.json --template $(SCM_REPORT_TEMPLATE) --out $(SCM_REPORT_PATH)
	@printf '%s\n' '\documentclass{article}' '\usepackage[T1]{fontenc}' '\usepackage{lmodern}' '\usepackage{graphicx}' '\usepackage{booktabs}' '\usepackage{amsmath}' '\begin{document}' '\input{$(SCM_REPORT_NAME)}' '\end{document}' > $(SCM_WRAPPER_TEX_PATH)
	@pdflatex -interaction=nonstopmode -halt-on-error -output-directory $(SCM_OUTDIR) $(SCM_WRAPPER_TEX_PATH) >/dev/null
	@cp $(SCM_REPORT_PATH) $(SCM_OUTDIR)/scm_case_report.tex
	@echo "Updated compatibility copy: $(SCM_OUTDIR)/scm_case_report.tex"
	@if [ "$(SCM_WRITE_COMPAT_WRAPPER)" = "1" ]; then cp $(SCM_WRAPPER_TEX_PATH) $(SCM_OUTDIR)/scm_case_report_wrapper.tex; cp $(SCM_WRAPPER_PDF_PATH) $(SCM_OUTDIR)/scm_case_report_wrapper.pdf; echo "Updated compatibility wrapper copies in $(SCM_OUTDIR)"; fi
	@echo "Rendered semantic wrapper: $(SCM_WRAPPER_TEX_PATH)"
	@echo "Rendered semantic wrapper PDF: $(SCM_WRAPPER_PDF_PATH)"

scm-all: scm-run scm-plot scm-report

run-gabls1:
	$(MAKE) scm-all SCM_CASE=gabls1 SCM_OUTDIR=results/gabls1

run-idealized-sbl:
	$(MAKE) scm-all SCM_CASE=idealized_sbl SCM_OUTDIR=results/idealized_sbl

run-sheba:
	$(MAKE) scm-all \
		SCM_CASE=sheba \
		SCM_DURATION=12.0 \
		SCM_DT=10.0 \
		SCM_GRID_SIZE=160 \
		SCM_DZ=2.0 \
		SCM_OUTDIR=results/sheba \
		SCM_SOLVER_JACOBIAN=autodiff \
		SCM_EXTRA_ARGS='--save-jld2 true --use-nonlocal-h true --h 300 --nonlocal-h-weight 0.5 --nonlocal-h-min 20.0 --nonlocal-h-max 400.0 --ts-min 220'

run-sheba-fd:
	$(MAKE) scm-all \
		SCM_CASE=sheba \
		SCM_DURATION=12.0 \
		SCM_DT=10.0 \
		SCM_GRID_SIZE=160 \
		SCM_DZ=2.0 \
		SCM_OUTDIR=results/sheba_fd \
		SCM_SOLVER_JACOBIAN=finite \
		SCM_JACOBIAN_SPARSITY=dense \
		SCM_EXTRA_ARGS='--save-jld2 true --use-nonlocal-h true --h 300 --nonlocal-h-weight 0.5 --nonlocal-h-min 20.0 --nonlocal-h-max 400.0 --ts-min 220'

run-sheba-high-top:
	$(MAKE) scm-all \
		SCM_CASE=sheba \
		SCM_DURATION=12.0 \
		SCM_DT=10.0 \
		SCM_GRID_SIZE=250 \
		SCM_DZ=2.0 \
		SCM_OUTDIR=results/sheba_high_top \
		SCM_SOLVER_JACOBIAN=autodiff \
		SCM_JACOBIAN_SPARSITY=banded \
		SCM_EXTRA_ARGS='--save-jld2 true --use-nonlocal-h true --h 500 --nonlocal-h-weight 0.5 --nonlocal-h-min 20.0 --nonlocal-h-max 500.0 --ts-min 220'

run-sheba-high-top-fd:
	$(MAKE) scm-all \
		SCM_CASE=sheba \
		SCM_DURATION=12.0 \
		SCM_DT=10.0 \
		SCM_GRID_SIZE=250 \
		SCM_DZ=2.0 \
		SCM_OUTDIR=results/sheba_high_top_fd \
		SCM_SOLVER_JACOBIAN=finite \
		SCM_JACOBIAN_SPARSITY=dense \
		SCM_EXTRA_ARGS='--save-jld2 true --use-nonlocal-h true --h 500 --nonlocal-h-weight 0.5 --nonlocal-h-min 20.0 --nonlocal-h-max 500.0 --ts-min 220'

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
	@julia --project=. scm/render_case_report.jl --summary results/scm_verify/summary.json --template $(SCM_REPORT_TEMPLATE) --out results/scm_verify/scm_verify_40x4m_0h_report.tex
	@[ -s results/scm_verify/scm_verify_40x4m_0h_report.tex ] || (echo "Verification FAILED: semantic verify report missing or empty"; exit 1)
	@cp results/scm_verify/scm_verify_40x4m_0h_report.tex results/scm_verify/scm_case_report.tex
	@[ -s results/scm_verify/scm_case_report.tex ] || (echo "Verification FAILED: scm_case_report.tex missing or empty"; exit 1)
	@echo "Verification PASSED: SCM pipeline is end-to-end healthy."

compile-scm-reports:
	@echo "Compiling dynamic SCM report portfolio..."
	@rm -f compile_reports.aux compile_reports.log compile_reports.out compile_reports.toc
	@reports="$$(find results -path 'results/_archived*' -prune -o -type f -name '*_report_wrapper.pdf' -print | sort)"; \
	if [ -z "$$reports" ]; then \
		echo "No compiled SCM report wrapper PDFs found under results/."; \
		exit 1; \
	fi; \
	graphpaths=$$(for pdf in $$reports; do tex="$${pdf%_wrapper.pdf}.tex"; dir="$$(dirname "$$tex")"; printf '{%s/}{%s/plots/}\n' "$$dir" "$$dir"; done | awk '!seen[$$0]++'); \
	{ \
		printf '%s\n' '\documentclass{article}'; \
		printf '%s\n' '\usepackage[T1]{fontenc}'; \
		printf '%s\n' '\usepackage{lmodern}'; \
		printf '%s\n' '\usepackage{graphicx}'; \
		printf '%s\n' '\usepackage{booktabs}'; \
		printf '%s\n' '\usepackage{amsmath}'; \
		printf '%s\n' '\usepackage{microtype}'; \
		printf '%s\n' '\usepackage[margin=1in]{geometry}'; \
		printf '%s\n' '\usepackage[hidelinks]{hyperref}'; \
		printf '%s\n' '\graphicspath{'; \
		printf '%s\n' "$$graphpaths"; \
		printf '%s\n' '}'; \
		printf '%s\n' ''; \
		printf '%s\n' '\title{Single Column Model (SCM) Diagnostic Runs}'; \
		printf '%s\n' '\author{GSPT Simulation Pipeline}'; \
		printf '%s\n' '\date{\today}'; \
		printf '%s\n' ''; \
		printf '%s\n' '\begin{document}'; \
		printf '%s\n' ''; \
		printf '%s\n' '\maketitle'; \
		printf '%s\n' ''; \
		printf '%s\n' '\section{Overview}'; \
		printf '%s\n' 'This document compiles every current SCM case report under results/ that has a compiled wrapper PDF.'; \
		printf '%s\n' ''; \
		n=1; \
		for pdf in $$reports; do \
			tex="$${pdf%_wrapper.pdf}.tex"; \
			base="$$(basename "$${tex%.tex}")"; \
			title="$$(printf '%s' "$$base" | sed 's/_/ /g')"; \
			printf '%s\n' '\newpage'; \
			printf '\section{Case %d: %s}\n' "$$n" "$$title"; \
			printf '\\IfFileExists{\\detokenize{%s}}{%%\n' "$$tex"; \
			printf '  \\input{\\detokenize{%s}}\n' "$$tex"; \
			printf '%s\n' '}{%'; \
			printf '  \\textbf{Report not found:} \\texttt{%s}\n' "$$(printf '%s' "$$tex" | sed 's/_/\\_/g')"; \
			printf '%s\n' '}'; \
			printf '%s\n' ''; \
			n=$$((n + 1)); \
		done; \
		printf '%s\n' '\end{document}'; \
	} > compile_reports.tex
	pdflatex -interaction=nonstopmode -halt-on-error compile_reports.tex
	pdflatex -interaction=nonstopmode -halt-on-error compile_reports.tex
	@echo "Success! Combined portfolio available at compile_reports.pdf"

test:
	julia --project=. -e 'using Pkg; Pkg.test()'

clean:
	find results -type d -name 'run_*' -prune -exec rm -rf {} +
	find results -type d -name 'bifurcation_*' -prune -exec rm -rf {} +
	if [ -d reports/generated ]; then find reports/generated -type f ! -name '.gitkeep' -delete; fi
	if [ -d figures ]; then find figures -type f \( -name '*.md' -o -name '*.tex' -o -name '*.json' \) -delete; fi
	if [ -d tables ]; then find tables -type f \( -name '*.md' -o -name '*.tex' -o -name '*.json' \) -delete; fi
	if [ -d bundle ]; then find bundle -mindepth 1 -maxdepth 1 -exec rm -rf -- {} \;; fi