using Test
using StableBoundaryLayerGSPT.Dynamics

@testset "Dynamics" begin
    states = integrate_system(Dict("nsteps" => 5, "dt" => 60.0, "tke0" => 0.2, "ri0" => 0.06))
    @test length(states) == 6
    @test all(s -> s.tke >= 0, states)
end
