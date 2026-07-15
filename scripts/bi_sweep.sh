#!/bin/bash
# Step 1: Run the bifurcation sweeps to find the "fold" boundaries
make bifurcation-cases99

# Step 2: Manually run SCM near those critical boundaries
# (Observe how changing SCM_DT from 30.0 to 10.0 shifts the state transition)
make scm-run SCM_CASE=idealized_sbl SCM_DT=10.0 SCM_GRID_SIZE=100 SCM_OUTDIR=results/bistable_dt10
make scm-run SCM_CASE=idealized_sbl SCM_DT=60.0 SCM_GRID_SIZE=100 SCM_OUTDIR=results/bistable_dt60
