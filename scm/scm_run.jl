using LinearAlgebra
using Statistics
using Printf

include(joinpath(@__DIR__, "scm.jl"))
include(joinpath(@__DIR__, "scm_diagnostics.jl"))

function _require_ordinarydiffeq()
    try
        @eval import OrdinaryDiffEq
    catch
        error("OrdinaryDiffEq is not installed in the active environment. Run: using Pkg; Pkg.add(\"OrdinaryDiffEq\")")
    end
    return OrdinaryDiffEq
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
)
    t_start, t_end = t_span
    t_end >= t_start || error("t_span must satisfy t_end >= t_start")
    dt > 0 || error("dt must be positive")

    od = _require_ordinarydiffeq()
    solver_alg = isnothing(solver) ? od.Rodas5P() : solver

    times = collect(t_start:dt:t_end)
    if isempty(times) || times[end] < t_end
        push!(times, t_end)
    end

    println("Starting SCM simulation trajectory...")
    @printf("  Grid points (N): %d | Time samples: %d | dt: %.1f s\n", p.N, length(times), dt)

    prob = od.ODEProblem(scm_gspt_tendencies!, copy(X0), (t_start, t_end), p)
    sol = od.solve(prob, solver_alg; saveat=times, abstol=abstol, reltol=reltol)

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
    try
        @eval import JLD2
    catch
        error("JLD2 is not installed. Run: using Pkg; Pkg.add(\"JLD2\")")
    end

    mkpath(dirname(filepath))
    JLD2.jldsave(filepath; payload...)
    println("Saved packaged diagnostic payload to: $(filepath)")
    return filepath
end

if abspath(PROGRAM_FILE) == @__FILE__
    println("scm_run.jl defines run_and_diagnose_scm(...) and save_scm_results(...)")
    println("Load it with include(\"scm/scm_run.jl\") and call the functions from your case script.")
end
