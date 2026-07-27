using Test

include(joinpath(@__DIR__, "..", "..", "scripts", "generate_symbols.jl"))

@testset "Symbols SSOT generation" begin
    mktempdir() do tmp
        spec_path = joinpath(@__DIR__, "..", "..", "spec", "symbols.yaml")
        tex_out = joinpath(tmp, "list_of_symbols.tex")
        md_out = joinpath(tmp, "SYMBOLS.md")

        context, generated_tex, generated_md = SymbolSSOT.generate_symbols_assets(
            spec_path=spec_path,
            tex_out=tex_out,
            md_out=md_out,
        )

        @test generated_tex == tex_out
        @test generated_md == md_out
        @test isfile(tex_out)
        @test isfile(md_out)

        tex_text = read(tex_out, String)
        md_text = read(md_out, String)

        @test occursin("List of Symbols", tex_text)
        @test occursin("\\(\\beta_T\\)", tex_text)
        @test occursin("\\(\\sigma_e\\)", tex_text)

        @test occursin("# Symbols Reference", md_text)
        @test occursin("| beta_T |", md_text)
        @test occursin("| sigma_e |", md_text)

        @test haskey(context, "symbol_beta_T_tex")
        @test context["symbol_beta_T_code"] == "beta_t"
        @test haskey(context, "symbol_sigma_e_tex")
    end
end
