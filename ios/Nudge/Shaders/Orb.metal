#include <metal_stdlib>
using namespace metal;

/// One shell of the companion orb — a noise-displaced soft aurora sphere with
/// inner caustic swirl and a volumetric halo. Rendered 3× with phase-offset t
/// and different palettes, blended plusLighter. Alpha fades fully to zero well
/// inside the bounds so the orb never shows a rectangular edge.
[[ stitchable ]] half4 orbShell(float2 pos, half4 existing, float2 size, float t,
                                float energy, half4 inner, half4 outer) {
    float2 uv = (pos / size) * 2.0 - 1.0;
    float r = length(uv);
    float a = atan2(uv.y, uv.x);

    // Multi-octave organic rim displacement — alive, never mechanical.
    float wob = 0.05 * (0.4 + energy) * sin(5.0 * a + t * 1.7)
              + 0.032 * sin(9.0 * a - t * 1.25 + sin(t * 0.6) * 1.4)
              + 0.022 * energy * sin(14.0 * a + t * 2.6);

    float edge = 1.0 - smoothstep(0.46 + wob, 0.68 + wob, r);

    // Inner caustic swirl — light folding inside the glass.
    float swirl = 0.5 + 0.5 * sin(6.5 * r - t * 2.1 + 3.0 * a + sin(t * 0.9));
    float core = exp(-3.2 * r * r);
    float mixAmount = clamp(core + swirl * (0.18 + 0.4 * energy) * (1.0 - r), 0.0, 1.0);
    half4 body = mix(outer, inner, half(mixAmount));

    // Volumetric halo, faded hard before the bounds so no box ever shows.
    float halo = exp(-5.0 * max(0.0, r - 0.66)) * (0.22 + 0.55 * energy);
    float boundsFade = 1.0 - smoothstep(0.92, 1.0, r);

    half alpha = half(clamp((edge + halo) * boundsFade, 0.0, 1.0));
    half3 rgb = body.rgb * half(edge) + outer.rgb * half(halo * boundsFade);
    return half4(rgb, alpha);
}
