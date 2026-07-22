module Physics

export compute_fluxes

"""
    compute_fluxes(state)

Compute placeholder turbulent fluxes (sensible, latent, mechanical) from state variables.
Accepts `NamedTuple`, `Dict`, or any struct with `:tke` and `:ri` fields.
"""
function compute_fluxes(state)
    tke = _get_var(state, :tke, 0.0)
    ri = _get_var(state, :ri, 0.0)

    # Physical safety bounds: TKE cannot be negative
    tke_pos = max(zero(tke), tke)

    # Flux suppression terms (prevent negative fluxes at high Ri unless intended)
    f_sensible = max(zero(ri), 1.0 - 0.5 * ri)
    f_latent = max(zero(ri), 1.0 - 0.2 * ri)

    sensible = 15.0 * tke_pos * f_sensible
    latent = 8.0 * tke_pos * f_latent
    mechanical = 10.0 * tke_pos

    return (; sensible, latent, mechanical)
end

# Flexible property getters supporting NamedTuples, Dicts, and custom structs
_get_var(s::NamedTuple, k::Symbol, default) = get(s, k, default)
_get_var(s::AbstractDict, k::Symbol, default) = get(s, k, default)
_get_var(s, k::Symbol, default) = hasproperty(s, k) ? getproperty(s, k) : default

end