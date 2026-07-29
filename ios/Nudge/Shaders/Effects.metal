#include <metal_stdlib>
using namespace metal;

/// Fluid melt dissolve — alpha erosion driven by hash noise.
/// Used when a Thread moment is dismissed; it melts away, never to
/// guilt-reappear.
[[ stitchable ]] half4 melt(float2 pos, half4 color, float progress, float2 size) {
    // At rest the shader must be a perfect no-op — partial-alpha noise at
    // progress 0 is what made resting cards look "pixelated".
    if (progress <= 0.001) { return color; }
    float2 uv = pos / size;
    float n = fract(sin(dot(floor(uv * 28.0), float2(12.9898, 78.233))) * 43758.5453);
    half a = color.a * half(smoothstep(progress, progress + 0.18, n + uv.y * 0.25));
    return half4(color.rgb, a);
}

/// Touch ripple distortion — wave propagating from an origin point.
[[ stitchable ]] float2 ripple(float2 pos, float2 origin, float t, float amplitude,
                               float frequency, float decay) {
    float d = distance(pos, origin);
    float delay = d / 1200.0;
    float time = max(0.0, t - delay);
    float r = amplitude * sin(frequency * time) * exp(-decay * time);
    return pos + normalize(pos - origin + 0.0001) * r;
}

/// Genie-style traveling light — a soft diagonal band of iridescent light
/// that sweeps across glass surfaces, kissing edges with subtle chroma.
/// progress 0→1 moves the band across; strength scales the glow.
[[ stitchable ]] half4 lightSweep(float2 pos, half4 color, float2 size,
                                  float progress, float strength) {
    float2 uv = pos / max(size, float2(1.0, 1.0));
    // Diagonal coordinate, band center travels from -0.35 to 1.35.
    float diag = (uv.x + uv.y) * 0.5;
    float center = mix(-0.35, 1.35, progress);
    float d = diag - center;
    float band = exp(-d * d / 0.006);
    float chroma = exp(-(d - 0.045) * (d - 0.045) / 0.004);
    float chromb = exp(-(d + 0.045) * (d + 0.045) / 0.004);

    half3 glow = half3(1.0, 0.98, 0.92) * half(band)
               + half3(0.65, 0.85, 1.0) * half(chroma * 0.5)
               + half3(1.0, 0.75, 0.85) * half(chromb * 0.5);
    half a = color.a;
    half3 rgb = color.rgb + glow * half(strength) * a;
    return half4(rgb, a);
}

/// Liquid distortion lens for the same sweep — bends the surface slightly
/// as the light passes, like glass catching the sun.
[[ stitchable ]] float2 sweepLens(float2 pos, float2 size, float progress, float amount) {
    float2 uv = pos / max(size, float2(1.0, 1.0));
    float diag = (uv.x + uv.y) * 0.5;
    float center = mix(-0.35, 1.35, progress);
    float d = diag - center;
    float lens = exp(-d * d / 0.01) * amount;
    return pos + float2(lens, lens * 0.6);
}

/// Touch light — an iridescent bloom that blossoms at the touch point and
/// chases the ripple wavefront outward, then dissolves. Paired with the
/// `ripple` distortion this is the Genie-style light-bends-with-the-water
/// moment, driven entirely by the finger, never on a loop.
[[ stitchable ]] half4 touchGlow(float2 pos, half4 color, float2 origin,
                                 float t, float strength) {
    if (t <= 0.0 || t >= 1.2 || strength <= 0.0) { return color; }
    float d = distance(pos, origin);

    // The expanding wavefront ring — light rides the water's edge.
    float front = t * 950.0;
    float ringD = d - front;
    float ring = exp(-ringD * ringD / 2400.0);

    // The bloom at the touch point itself, fading as the wave leaves.
    float bloom = exp(-d * d / 14000.0) * exp(-t * 3.2);

    // Iridescent fringing on the ring — chroma split like bent light.
    float fringeA = exp(-(ringD - 26.0) * (ringD - 26.0) / 1300.0);
    float fringeB = exp(-(ringD + 26.0) * (ringD + 26.0) / 1300.0);

    float fade = exp(-t * 2.1);
    half3 light = half3(1.0, 0.97, 0.9) * half(ring * 0.55)
                + half3(1.0, 0.98, 0.94) * half(bloom * 0.5)
                + half3(0.62, 0.84, 1.0) * half(fringeA * 0.28)
                + half3(1.0, 0.72, 0.82) * half(fringeB * 0.28);
    half a = color.a;
    return half4(color.rgb + light * half(strength * fade) * a, a);
}
