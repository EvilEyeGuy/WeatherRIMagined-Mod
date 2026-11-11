#version 450

layout(location = 0) in vec3 inPosition; // @vertex Position required
layout(location = 2) in vec4 inColor; // @vertex Color optional @default = vec4(0.0, 0.0, 0.0, 0.0)
layout(location = 3) in vec4 inUv0; // @vertex TexCoord0 optional @default = vec4(0.0, 0.0, 0.0, 0.0)

layout(push_constant) uniform Push { mat4 modelMatrix; } push;

layout(location = 1) out vec2 vUv;
layout(location = 2) out float vStaerke;

layout(set = 0, binding = 0) uniform VertexUniforms
{
    mat4 ViewProj;
} uVertex;

layout(set = 2, binding = 0) uniform MaterialUniforms
{
    vec4 _Color;      // @color @default = vec4(1.0, 1.0, 1.0, 1.0)
    vec4 _MainTex_ST; // @default = vec4(0.0, 0.0, 1.0, 1.0)
    vec4 _CastVect;
    vec4 _WR_Wetter;
} uMaterial;

const float Hoehe = 4.7560977;
const float Mittag = 0.5;
const float Seite = 1.344;
const float Standard = 0.35;

void main()
{
    vec2 sonne = uMaterial._CastVect.xz;
    float betrag = length(sonne);
    float weite = (inColor.g * 255.0 * 256.0 + inColor.a * 255.0) / 65535.0 * 32.0 - 8.0;
    vec2 welt = inPosition.xz;
    vStaerke = (inColor.r >= 0.75 && inColor.r < 0.9) ? inColor.g : 1.0;
    if (inColor.r < 0.75)
    {
        float grenze = inColor.r * 255.0 / 127.0 * 8.0;
        vec2 e = betrag > 0.001 ? sonne / betrag : vec2(0.0, -1.0);
        float anteil = min(1.0, Seite * Mittag / sqrt(Mittag * Mittag * e.x * e.x + Seite * Seite * e.y * e.y));
        welt = welt + vec2(inPosition.y, 0.0) + e * weite * min(anteil / Standard, grenze);
    }
    else
    {
        vec2 richtung = betrag > 0.001 ? sonne / betrag : vec2(0.0, -1.0);
        welt += richtung * min(betrag, 9.09) * weite * inPosition.y;
    }
    gl_Position = uVertex.ViewProj * push.modelMatrix * vec4(welt.x, Hoehe, welt.y, 1.0);
    vUv = inUv0.xy * uMaterial._MainTex_ST.zw + uMaterial._MainTex_ST.xy;
}
