#version 450

layout(location = 1) in vec2 vUv;
layout(location = 2) in float vStaerke;

layout(location = 0) out vec4 outColor;

layout(set = 2, binding = 0) uniform MaterialUniforms
{
    vec4 _Color;      // @color @default = vec4(1.0, 1.0, 1.0, 1.0)
    vec4 _MainTex_ST; // @default = vec4(0.0, 0.0, 1.0, 1.0)
    vec4 _CastVect;
    vec4 _WR_Wetter;
} uMaterial;

layout(set = 2, binding = 1) uniform sampler2D _MainTex;

void main()
{
    if (texture(_MainTex, vUv).a < 0.5)
    {
        discard;
    }
    vec3 ton = max(max(uMaterial._WR_Wetter.y, uMaterial._WR_Wetter.z), uMaterial._WR_Wetter.w) > 0.0 ? uMaterial._WR_Wetter.yzw : vec3(0.42);
    float kraft = vStaerke < 0.0 ? -vStaerke : clamp(uMaterial._CastVect.w, 0.0, 1.0) * vStaerke;
    vec3 d = ton * (kraft * (1.0 - clamp(uMaterial._WR_Wetter.x, 0.0, 1.0)));
    if (max(d.r, max(d.g, d.b)) < 0.004)
    {
        discard;
    }
    outColor = vec4(vec3(1.0) - d, 1.0);
}
