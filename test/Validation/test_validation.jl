using Test
using StableBoundaryLayerGSPT.Validation

@testset "Validation" begin
    good = Dict("n_samples" => 10, "ri_mean" => 0.05, "tke_mean" => 0.1, "tke_min" => 0.0)
    pass, _ = run_validation_gate(good)
    @test pass

    bad = Dict("n_samples" => 10, "ri_mean" => 0.05, "tke_mean" => 0.1, "tke_min" => -0.01)
    pass_bad, _ = run_validation_gate(bad)
    @test !pass_bad
end
