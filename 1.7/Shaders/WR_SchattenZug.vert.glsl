#version 450

layout(location = 0) in vec3 inPosition; // @vertex Position required
layout(location = 2) in vec4 inColor; // @vertex Color optional @default = vec4(0.0, 0.0, 0.0, 0.0)
layout(location = 3) in vec4 inUv0; // @vertex TexCoord0 optional @default = vec4(0.0, 0.0, 0.0, 0.0)
layout(location = 4) in vec4 inUv1; // @vertex TexCoord1 optional @default = vec4(0.0, 0.0, 0.0, 0.0)

layout(push_constant) uniform Push { mat4 modelMatrix; } push;

layout(location = 1) out vec2 vOrt;
layout(location = 2) out vec2 vZug;
layout(location = 3) out vec4 vKachel;
layout(location = 4) out vec4 vWerte;
layout(location = 5) out float vTiefe;

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
const float Spanne = 0.2;

void main()
{
    float bits = floor(inColor.r * 255.0 + 0.5);
    float art = floor(bits / 8.0);
    float ecke = mod(bits, 4.0);
    float spiegeln = mod(floor(bits / 4.0), 2.0);
    float fach = inColor.b * 2.55;
    float winkel = floor(inColor.a * 255.0 + 0.5) / 256.0 * 6.2831853;
    vec2 welt;
    vKachel = vec4(inUv0.xyz, inUv1.w);
    if (art > 2.5)
    {
        welt = inPosition.xz;
        vOrt = inUv1.xy;
        vZug = vec2(inUv1.z, 0.0);
        vWerte = vec4(inColor.g, fach, spiegeln, 3.0);
    }
    else
    {
        vec2 zug;
        if (art > 1.5)
        {
            zug = vec2(inPosition.y, inUv1.z);
        }
        else
        {
            vec2 sonne = uMaterial._CastVect.xz;
            float betrag = length(sonne);
            vec2 richtung = betrag > 0.001 ? sonne / betrag : vec2(0.0, -1.0);
            zug = richtung * min(betrag, 9.09) * inPosition.y;
        }
        float laenge = length(zug);
        vec2 e = laenge > 0.0001 ? zug / laenge : vec2(0.0, -1.0);
        vec2 n = vec2(-e.y, e.x);
        float b = max(inUv1.x, 0.001);
        float h = max(inUv1.y, 0.001);
        float c = cos(winkel);
        float s = sin(winkel);
        vec2 achseX = vec2(c, -s);
        vec2 achseZ = vec2(s, c);
        float halbS = (abs(dot(achseX, e)) * b + abs(dot(achseZ, e)) * h) * 0.5;
        float halbT = (abs(dot(achseX, n)) * b + abs(dot(achseZ, n)) * h) * 0.5;
        float weit = 1.0 + fach;
        float ps = ecke >= 2.0 ? laenge + halbS * weit : -halbS;
        float pt = (ecke == 1.0 || ecke == 2.0) ? halbT * weit : -halbT * weit;
        vec2 weg = e * ps + n * pt;
        welt = inPosition.xz + weg;
        vOrt = vec2(dot(weg, achseX) / b, dot(weg, achseZ) / h) + vec2(0.5);
        vZug = vec2(dot(zug, achseX) / b, dot(zug, achseZ) / h);
        vWerte = vec4(inColor.g, fach, spiegeln, art > 1.5 ? 2.0 : 1.0);
    }
    gl_Position = uVertex.ViewProj * push.modelMatrix * vec4(welt.x, Hoehe, welt.y, 1.0);
    vec4 oben = uVertex.ViewProj * push.modelMatrix * vec4(welt.x, Hoehe + Spanne, welt.y, 1.0);
    vTiefe = oben.z / oben.w - gl_Position.z / gl_Position.w;
}
