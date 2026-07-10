module Physics

export compute_fluxes

"""Compute placeholder turbulent fluxes from state variables."""
function compute_fluxes(state::NamedTuple)
    tke = Float64(get(state, :tke, 0.0))
    ri = Float64(get(state, :ri, 0.0))
    sensible = 15.0 * tke * (1 - 0.5 * ri)
    latent = 8.0 * tke * (1 - 0.2 * ri)
    mechanical = 10.0 * tke
    return (; sensible, latent, mechanical)
end

end