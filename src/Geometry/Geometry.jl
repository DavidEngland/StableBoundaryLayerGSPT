module Geometry

export critical_manifold

"""Return a simple critical manifold estimate from state variables."""
function critical_manifold(state::NamedTuple)
    ri = Float64(get(state, :ri, 0.0))
    tke = Float64(get(state, :tke, 0.0))
    z = Float64(get(state, :z, 10.0))
    manifold_value = tke / (1 + abs(ri))
    return (; z, manifold_value)
end

end