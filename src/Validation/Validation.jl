module Validation

export run_validation_gate

"""Run required scientific validation checks before visualization/reporting."""
function run_validation_gate(diagnostics::AbstractDict{String,<:Any})
    required = ["n_samples", "ri_mean", "tke_mean", "tke_min"]
    for key in required
        haskey(diagnostics, key) || return (false, "Missing diagnostic: $key")
    end

    diagnostics["n_samples"] > 2 || return (false, "Insufficient samples")
    isfinite(Float64(diagnostics["ri_mean"])) || return (false, "Non-finite ri_mean")
    Float64(diagnostics["tke_min"]) >= 0 || return (false, "Negative TKE detected")

    return (true, "Validation checks passed")
end

end