using Test
using DataFrames
using StableBoundaryLayerGSPT.Diagnostics

@testset "Bifurcation Sweep" begin
    params = Dict(
        "sigma" => 1.0,
        "K" => 0.8,
        "alpha" => 0.6,
        "a_fold" => 0.6,
        "b_fold" => 0.35,
        "T0" => 280.0,
        "S0" => 0.8,
    )

    analysis = synthetic_bifurcation_analysis(parameters=params, nsamples=40, ngrid=20, seed=7)

    @test nrow(analysis.transcritical_map) == 400
    @test nrow(analysis.fold_map) == 400
    @test nrow(analysis.transcritical_envelope) == 20
    @test nrow(analysis.fold_envelope) == 2
    @test haskey(analysis.summary, "transcritical_near_fraction")
    @test haskey(analysis.summary, "fold_near_fraction")
end
