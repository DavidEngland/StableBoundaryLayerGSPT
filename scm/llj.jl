using LinearAlgebra

"""
    analyze_llj(z::Vector{Float64}, u::Vector{Float64}, v::Vector{Float64}; top_buffer_fraction=0.15)

Analyzes a single vertical atmospheric profile to detect a Low-Level Jet (LLJ).
Returns a NamedTuple with jet properties and a boundary containment flag.
"""
function analyze_llj(z::Vector{Float64}, u::Vector{Float64}, v::Vector{Float64}; top_buffer_fraction=0.15)
    # 1. Calculate wind speed profile
    wind_speed = @. sqrt(u^2 + v^2)

    # 2. Find global maximum wind speed and its height
    max_idx = argmax(wind_speed)
    u_jet = wind_speed[max_idx]
    z_jet = z[max_idx]

    # 3. Look for a wind speed minimum above the jet to confirm a classic LLJ "nose"
    # An LLJ typically requires the wind speed to drop by at least 2 m/s (or 20%) aloft
    above_jet_speed = wind_speed[max_idx:end]
    min_above = minimum(above_jet_speed)
    jet_drop = u_jet - min_above

    is_true_llj = jet_drop >= 2.0

    # 4. Verify boundary containment
    # If the jet core is within the top X% of the domain, it's structurally compromised
    z_top = z[end]
    buffer_zone = z_top * (1.0 - top_buffer_fraction)
    is_contained = z_jet < buffer_zone

    return (
        is_llj = is_true_llj,
        height = z_jet,
        magnitude = u_jet,
        drop_aloft = jet_drop,
        is_contained = is_contained
    )
end

# --- Quick Validation Check ---
# Simulating a typical SHEBA profile over a 200m domain
z = collect(0.0:2.0:200.0)
# Create a synthetic LLJ that peaks around 60 meters
u_profile = @. 7.0 + 5.0 * exp(-((z - 60.0)/30.0)^2)
v_profile = zeros(length(z))

result = analyze_llj(z, u_profile, v_profile)

println("--- LLJ Diagnostic Report ---")
println("Jet Detected:  ", result.is_llj)
println("Jet Height:    ", result.height, " m")
println("Max Velocity:  ", result.magnitude, " m/s")
println("Contained Safely: ", result.is_contained ? "Yes" : "⚠️ NO - Too close to top boundary!")