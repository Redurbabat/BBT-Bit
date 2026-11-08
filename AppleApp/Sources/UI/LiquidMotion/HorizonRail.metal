#include <metal_stdlib>
using namespace metal;

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
