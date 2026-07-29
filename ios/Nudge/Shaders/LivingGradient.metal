#include <metal_stdlib>
using namespace metal;

/// The living gradient — three slowly-orbiting soft radial centers.
/// Driven with t = time * 0.011 for a ~90s feel; imperceptible in any
/// single second, alive over a minute.
[[ stitchable ]] half4 livingGradient(float2 pos, half4 color, float2 size, float t,
                                      half4 c0, half4 c1, half4 c2) {
    float2 uv = pos / size;
    float2 p0 = 0.5 + 0.42 * float2(sin(t * 0.9), cos(t * 0.7));
    float2 p1 = 0.5 + 0.38 * float2(sin(t * 0.5 + 2.1), cos(t * 1.1 + 1.3));
    float2 p2 = 0.5 + 0.45 * float2(sin(t * 0.7 + 4.2), cos(t * 0.4 + 3.7));
    half w0 = half(exp(-3.5 * distance(uv, p0)));
    half w1 = half(exp(-3.5 * distance(uv, p1)));
    half w2 = half(exp(-3.5 * distance(uv, p2)));
    half4 g = (c0 * w0 + c1 * w1 + c2 * w2) / max(w0 + w1 + w2, half(0.001));
    return half4(g.rgb, 1.0h);
}
