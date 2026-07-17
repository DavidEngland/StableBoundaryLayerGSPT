using LinearAlgebra
using Statistics
using Printf
using SparseArrays
import OrdinaryDiffEq
    import JLD2


include(joinpath(@__DIR__, "scm.jl"))
include(joinpath(@__DIR__, "scm_diagnostics.jl"))

"""
    build_scm_jacobian_prototype(p)

Build a sparse Jacobian prototype matching the local vertical stencil
for state layout [Ts, U[1:N], V[1:N], theta[1:N]].
"""
function build_scm_jacobian_prototype(p)
    N = p.N
    n = 3N + 1
    rows = Int[]
    cols = Int[]

    # Ts row couples to Ts, U1, V1, theta1 through surface fluxes/SEB.
    push!(rows, 1); push!(cols, 1)
    push!(rows, 1); push!(cols, 2)
    push!(rows, 1); push!(cols, N + 2)
    push!(rows, 1); push!(cols, 2N + 2)

    idxU(i) = 1 + i
    idxV(i) = 1 + N + i
    idxTh(i) = 1 + 2N + i

    # U equations: nearest-neighbor U stencil + same-level and neighboring V/theta influence.
    for i in 1:N
        r = idxU(i)
        for j in max(1, i - 1):min(N, i + 1)
            push!(rows, r); push!(cols, idxU(j))
            push!(rows, r); push!(cols, idxV(j))
            push!(rows, r); push!(cols, idxTh(j))
        end
        if i == 1
            push!(rows, r); push!(cols, 1)
        end
    end

    # V equations: nearest-neighbor V stencil + same-level and neighboring U/theta influence.
    for i in 1:N
        r = idxV(i)
        for j in max(1, i - 1):min(N, i + 1)
            push!(rows, r); push!(cols, idxV(j))
            push!(rows, r); push!(cols, idxU(j))
            push!(rows, r); push!(cols, idxTh(j))
        end
        if i == 1
            push!(rows, r); push!(cols, 1)
        end
    end

    # Theta equations: nearest-neighbor theta stencil + local velocity coupling via closure.
    for i in 1:N
        r = idxTh(i)
        for j in max(1, i - 1):min(N, i + 1)
            push!(rows, r); push!(cols, idxTh(j))
            push!(rows, r); push!(cols, idxU(j))
            push!(rows, r); push!(cols, idxV(j))
        end
        if i == 1
            push!(rows, r); push!(cols, 1)
        end
    end

    vals = ones(Float64, length(rows))
    return sparse(rows, cols, vals, n, n)
end

"""
    run_and_diagnose_scm(X0, p, t_span, dt; cfg=SCMDiagnosticConfig(), solver=Rodas5P(), abstol=1e-8, reltol=1e-6)

Run the SCM trajectory with `scm_gspt_tendencies!`, compute the full diagnostics suite,
and return a packaged payload suitable for publication post-processing.
"""
function run_and_diagnose_scm(
    X0,
    p,
    t_span,
    dt;
    cfg=SCMDiagnosticConfig(),
    solver=nothing,
    abstol=1.0e-8,
    reltol=1.0e-6,
    profile_every_seconds=1800.0,
    jacobian_mode::Symbol=:autodiff,
    jacobian_sparsity::Symbol=:dense,
)
    t_start, t_end = t_span
    t_end >= t_start || error("t_span must satisfy t_end >= t_start")
    dt > 0 || error("dt must be positive")

    if isnothing(solver)
        if jacobian_mode == :finite
            solver_alg = OrdinaryDiffEq.Rodas5P(autodiff=false)
        elseif jacobian_mode == :autodiff
            solver_alg = OrdinaryDiffEq.Rodas5P()
        else
            error("Unsupported jacobian_mode=$(jacobian_mode). Use :autodiff or :finite")
        end
    else
        solver_alg = solver
    end

    times = collect(t_start:dt:t_end)
    if isempty(times) || times[end] < t_end
        push!(times, t_end)
    end

    println("Starting SCM simulation trajectory...")
    @printf("  Grid points (N): %d | Time samples: %d | dt: %.1f s\n", p.N, length(times), dt)
    @printf("  Jacobian mode: %s\n", String(jacobian_mode))
    @printf("  Jacobian sparsity: %s\n", String(jacobian_sparsity))

    f = if jacobian_sparsity == :banded
        OrdinaryDiffEq.ODEFunction(scm_gspt_tendencies!; jac_prototype=build_scm_jacobian_prototype(p))
    elseif jacobian_sparsity == :dense
        scm_gspt_tendencies!
    else
        error("Unsupported jacobian_sparsity=$(jacobian_sparsity). Use :dense or :banded")
    end

    prob = OrdinaryDiffEq.ODEProblem(f, copy(X0), (t_start, t_end), p)
    sol = OrdinaryDiffEq.solve(prob, solver_alg; saveat=times, abstol=abstol, reltol=reltol)

    states = [Vector(u) for u in sol.u]
    times = collect(sol.t)

    println("Simulation complete. Running diagnostic pipeline...")

    time_series = compute_time_series_diagnostics(times, states, p; cfg=cfg)
    profiles = sample_profile_snapshots(time_series; every_seconds=profile_every_seconds)
    hovmoller = build_hovmoller_payload(time_series, p)
    verification = compute_numerical_verification(time_series)

    println("\n================ SCM RUN INTEGRITY REPORT ================")
    @printf("  Max Surface Energy Closure Error : %12.6e W/m^2\n", verification.max_surface_energy_closure_error)
    @printf("  Manifold Fold Proximity Fraction : %12.2f %%\n", verification.fold_near_fraction * 100)
    @printf(
        "  Diffusivity Limits (Km)          : [%6.2e, %6.2e] m^2/s\n",
        verification.min_diffusivity,
        verification.max_diffusivity,
    )
    @printf(
        "  Richardson Number Limits (Ri)    : [%6.2f, %6.2f]\n",
        verification.min_ri,
        verification.max_ri,
    )
    @printf("  Solver accepted/rejected steps   : %d / %d\n", sol.destats.naccept, sol.destats.nreject)
    @printf("  RHS evaluations                  : %d\n", sol.destats.nf)
    println("==========================================================\n")

    payload = (
        p=p,
        times=times,
        states=states,
        time_series=time_series,
        profiles=profiles,
        hovmoller=hovmoller,
        verification=verification,
        solver_summary=(
            algorithm=string(typeof(solver_alg)),
            jacobian_mode=String(jacobian_mode),
            jacobian_sparsity=String(jacobian_sparsity),
            accepted_steps=sol.destats.naccept,
            rejected_steps=sol.destats.nreject,
            rhs_evaluations=sol.destats.nf,
            retcode=string(sol.retcode),
            abstol=abstol,
            reltol=reltol,
        ),
        figure_manifest=publication_figure_manifest(),
    )

    return payload
end

"""
    save_scm_results(filepath, payload)

Persist the packaged payload to a JLD2 file.
If `JLD2` is not installed in the active environment, throws with install guidance.
"""
function save_scm_results(filepath::AbstractString, payload)
    mkpath(dirname(filepath))
    JLD2.jldsave(filepath; payload...)
    println("Saved packaged diagnostic payload to: $(filepath)")
    return filepath
end

if abspath(PROGRAM_FILE) == @__FILE__
    println("scm_run.jl defines run_and_diagnose_scm(...) and save_scm_results(...)")
    println("Load it with include(\"scm/scm_run.jl\") and call the functions from your case script.")
end
