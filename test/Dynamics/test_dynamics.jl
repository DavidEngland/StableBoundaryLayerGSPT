using Test
using StableBoundaryLayerGSPT.Dynamics

@testset "Dynamics" begin
    states = integrate_system(Dict("nsteps" => 5, "dt" => 60.0, "tke0" => 0.2, "ri0" => 0.06))
    @test length(states) == 6
    @test all(s -> s.tke >= 0, states)

    params = default_4d_parameters()
    @test hyperbolic_embedding_e(-1.0, params) >= 0.0

    embedded_zero = hyperbolic_embedding_e(params["delta"] / params["l0"], params)
    @test embedded_zero ≈ params["xi"] / 2 atol=1.0e-12

    sol = solve_4d_sbl(parameters=params, tspan=(0.0, 300.0), saveat=60.0)
    rows = solution_to_rows(sol, params)
    @test !isempty(rows)
    @test haskey(rows[1], :e_star_smooth)
    @test haskey(rows[1], :Km_star)
    @test haskey(rows[1], :Kh_star)
    @test all(row -> row.e_star_smooth >= 0.0, rows)
end
