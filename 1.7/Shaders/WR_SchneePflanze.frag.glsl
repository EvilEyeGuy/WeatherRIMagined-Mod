#version 450

layout(location = 1) in vec2 vUv;
layout(location = 2) flat in float vFallSeed;

layout(location = 0) out vec4 outColor;

layout(set = 2, binding = 0) uniform MaterialUniforms
{
    vec4 _Color;      // @color @default = vec4(1.0, 1.0, 1.0, 1.0)
    vec4 _MainTex_ST; // @default = vec4(0.0, 0.0, 1.0, 1.0)
    float _SwayHead;  // @default = 0.0
    vec4 _FallColorSource;
    vec4 _FallTransitionRange;
    float _FallBehaviorEnabled;
    float _FallIntensity;
    float _FallGlobalControls;
    vec4 _FallSrc;
    vec4 _FallDst;
    vec4 _FallRange;
    float _SnowAmount; // @default = 0.0
} uMaterial;

layout(set = 2, binding = 1) uniform sampler2D _MainTex;
layout(set = 2, binding = 2) uniform sampler2D _FallColorDestination;
layout(set = 2, binding = 4) uniform sampler2D _SnowTex;

float randcentered(float x)
{
    return fract(sin(x) * 43758.5453);
}

float rand(float x)
{
    return abs(randcentered(x));
}

vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec3 herbst(vec3 rgb)
{
    if (uMaterial._FallBehaviorEnabled == 0.0)
    {
        return rgb;
    }

    vec3 hsv = rgb2hsv(rgb);

    bool globalControls = uMaterial._FallGlobalControls != 0.0;
    vec3 srchsv;
    vec3 dsthsv;
    if (globalControls)
    {
        srchsv = rgb2hsv(uMaterial._FallSrc.rgb);
        dsthsv = rgb2hsv(uMaterial._FallDst.rgb);
    }
    else
    {
        srchsv = rgb2hsv(uMaterial._FallColorSource.rgb);
        dsthsv = rgb2hsv(texture(_FallColorDestination, vec2(randcentered(vFallSeed * 3.0 + 5.0), 0.5)).rgb);
    }

    float hdiff = abs(srchsv.r - hsv.r);
    float distance = min(hdiff, 1.0 - hdiff);

    vec3 delta = dsthsv - srchsv;
    delta.r = delta.r - round(delta.r);

    vec2 range = globalControls ? uMaterial._FallRange.xy : uMaterial._FallTransitionRange.xy;

    const float randomFactorRange = 2.0;
    float startIntensity = mix(-randomFactorRange, 0.0, rand(vFallSeed * 2.0 + 1.0));
    float endIntensity = mix(1.0, 1.0 + randomFactorRange, rand(vFallSeed * 4.0 - 3.0));

    float chromaKeyIntensity = 1.0 - smoothstep(range.x, range.y, distance);
    float targetFallIntensity = clamp(mix(startIntensity, endIntensity, uMaterial._FallIntensity), 0.0, 1.0);

    float lerpTarget = clamp(chromaKeyIntensity * targetFallIntensity, 0.0, 1.0);

    vec3 resulthsv = hsv + delta * lerpTarget;
    resulthsv.r = fract(resulthsv.r + 1.0);
    resulthsv.gb = clamp(resulthsv.gb, 0.0, 1.0);

    return hsv2rgb(resulthsv);
}

void main()
{
    vec2 uv = vUv * uMaterial._MainTex_ST.zw + uMaterial._MainTex_ST.xy;
    vec4 texVal = texture(_MainTex, uv);
    if (texVal.a < 0.35)
        discard;

    vec3 farbe = herbst(texVal.rgb);
    vec4 schnee = texture(_SnowTex, uv);
    vec2 texelProPixel = fwidth(uv * vec2(textureSize(_SnowTex, 0)));
    float band = 0.03 * max(1.0, max(texelProPixel.x, texelProPixel.y));
    float decke = schnee.a > 0.999 ? 0.0 : clamp((uMaterial._SnowAmount - schnee.a) / band + 0.5, 0.0, 1.0);
    outColor = vec4(mix(farbe, schnee.rgb * vec3(0.9, 0.915, 0.945), decke), texVal.a);
}
