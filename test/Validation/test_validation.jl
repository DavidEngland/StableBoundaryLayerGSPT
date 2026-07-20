using Test
using StableBoundaryLayerGSPT.Validation
using StableBoundaryLayerGSPT.Geometry: compute_manifold_equilibrium

@testset "Validation" begin
    good = Dict("n_samples" => 10, "ri_mean" => 0.05, "tke_mean" => 0.1, "tke_min" => 0.0)
    pass, _ = run_validation_gate(good)
    @test pass

    bad = Dict("n_samples" => 10, "ri_mean" => 0.05, "tke_mean" => 0.1, "tke_min" => -0.01)
    pass_bad, _ = run_validation_gate(bad)
    @test !pass_bad

    test_p = (
        σ = 1.0e-6,
        δ = 1.0e-4,
        Δz = 50.0,
        Ug = 10.0,
        Vg = 0.0,
        g_over_θ0 = 9.81 / 273.15,
        l_0 = 15.0,
        CD = 1.5e-3,
        CH = 1.5e-3,
    )

    strong_shear_state = (
        U1 = 5.0,
        V1 = 0.0,
        θ1 = 273.15,
        Ts = 273.15,
    )

    geom = compute_manifold_equilibrium(strong_shear_state, test_p; e_guess = 0.5)
    cooler_surface_state = (
        U1 = 5.0,
        V1 = 0.0,
        θ1 = 273.15,
        Ts = 270.15,
    )

    geom_cooler = compute_manifold_equilibrium(cooler_surface_state, test_p; e_guess = 0.5)

    @test geom.converged
    @test geom.e_eq > 0.0
    @test geom.fold_diagnostic < 0.0
    @test abs(geom.residual) < 1e-7
    @test geom.thermal_inversion == 0.0
    @test geom_cooler.thermal_inversion > geom.thermal_inversion
    @test geom_cooler.e_eq != geom.e_eq
end
