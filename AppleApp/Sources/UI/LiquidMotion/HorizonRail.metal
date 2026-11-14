#include <metal_stdlib>
using namespace metal;

[[ stitchable ]] float2 coverLensRefraction(float2 position, float progress, float2 size) {
    float2 delta = position - size * 0.5;
    float distance = length(delta);
    float radius = min(size.x, size.y) * 0.75 * clamp(progress, 0.0, 1.0);
    float strength = sin((distance - radius) * 0.12) * 12.0 * (1.0 - progress);
    float envelope = 1.0 - smoothstep(0.0, 32.0, abs(distance - radius));
    return position + delta / max(1.0, distance) * strength * envelope;
}

// Eigene, scrollgebundene Papierbiegung; bei ruhenden Karten ist der Effekt null.
[[ stitchable ]] float2 horizonRailBend(float2 position, float4 bounds, float phase) {
    float2 unit = (position - bounds.xy) / max(bounds.zw, float2(1.0));
    float strength = clamp(phase, -1.0, 1.0);
    float wave = sin(unit.x * M_PI_F * 2.0);
    float envelope = sin(clamp(unit.y, 0.0, 1.0) * M_PI_F);
    return position + float2(
        strength * envelope * 12.0,
        strength * wave * 13.0
    );
}
