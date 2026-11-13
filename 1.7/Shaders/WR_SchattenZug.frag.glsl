#version 450

layout(location = 1) in vec2 vOrt;
layout(location = 2) in vec2 vZug;
layout(location = 3) in vec4 vKachel;
layout(location = 4) in vec4 vWerte;
layout(location = 5) in float vTiefe;

layout(location = 0) out vec4 outColor;

layout(set = 2, binding = 0) uniform MaterialUniforms
{
    vec4 _Color;      // @color @default = vec4(1.0, 1.0, 1.0, 1.0)
    vec4 _MainTex_ST; // @default = vec4(0.0, 0.0, 1.0, 1.0)
    vec4 _CastVect;
    vec4 _WR_Wetter;
} uMaterial;

layout(set = 2, binding = 1) uniform sampler2D _MainTex;

const int Hoechstens = 64;
const int Feiner = 5;

float auslauf(float a)
{
    return (1.0 - a) / (1.0 + 0.27 * a);
}

float deckung(vec2 p)
{
    if (vWerte.z > 0.5)
    {
        p.x = 1.0 - p.x;
    }
    vec2 uv = (vKachel.xy + clamp(p, 0.0, 1.0) * vKachel.zw) * uMaterial._MainTex_ST.zw + uMaterial._MainTex_ST.xy;
    return textureLod(_MainTex, uv, 0.0).a;
}

void main()
{
    vec2 schritt = max(fwidth(vOrt), vec2(0.00001));
    float lauf = 0.0;
    if (vWerte.w > 2.5)
    {
        float a = vOrt.y;
        float u = 0.5 + vOrt.x / (1.0 + vWerte.y * a);
        if (a < 0.0 || a > 1.0 || u < 0.0 || u > 1.0)
        {
            discard;
        }
        float v = vZug.x + a * (1.0 - vZug.x);
        if (deckung(vec2(u, v)) < 0.5)
        {
            discard;
        }
        lauf = a;
    }
    else
    {
        vec2 q = vOrt - vec2(0.5);
        vec2 z = vZug;
        float f = vWerte.y;
        vec2 d = (q - z) / (1.0 + f) - q;
        float s0 = 0.0;
        float s1 = 1.0;
        if (abs(d.x) < 0.000001)
        {
            if (abs(q.x) > 0.5)
            {
                discard;
            }
        }
        else
        {
            float a = (-0.5 - q.x) / d.x;
            float b = (0.5 - q.x) / d.x;
            s0 = max(s0, min(a, b));
            s1 = min(s1, max(a, b));
        }
        if (abs(d.y) < 0.000001)
        {
            if (abs(q.y) > 0.5)
            {
                discard;
            }
        }
        else
        {
            float a = (-0.5 - q.y) / d.y;
            float b = (0.5 - q.y) / d.y;
            s0 = max(s0, min(a, b));
            s1 = min(s1, max(a, b));
        }
        if (s0 > s1)
        {
            discard;
        }
        float pixel = length(d * (s1 - s0) / schritt);
        int anzahl = int(clamp(ceil(pixel / 1.5), 4.0, float(Hoechstens)));
        bool treffer = false;
        float vor = s0;
        float bei = s0;
        for (int i = 0; i <= Hoechstens; i++)
        {
            if (i > anzahl)
            {
                break;
            }
            float s = s0 + (s1 - s0) * float(i) / float(anzahl);
            if (deckung(q + d * s + vec2(0.5)) >= 0.5)
            {
                treffer = true;
                bei = s;
                break;
            }
            vor = s;
        }
        if (!treffer)
        {
            discard;
        }
        if (bei > vor)
        {
            for (int k = 0; k < Feiner; k++)
            {
                float m = (vor + bei) * 0.5;
                if (deckung(q + d * m + vec2(0.5)) >= 0.5)
                {
                    bei = m;
                }
                else
                {
                    vor = m;
                }
            }
        }
        vec2 ort = q + d * bei;
        vec2 nenner = z + f * ort;
        float t = 0.0;
        if (abs(nenner.x) > abs(nenner.y))
        {
            t = (q.x - ort.x) / nenner.x;
        }
        else if (abs(nenner.y) > 0.000001)
        {
            t = (q.y - ort.y) / nenner.y;
        }
        lauf = clamp(t, 0.0, 1.0);
    }
    vec3 ton = max(max(uMaterial._WR_Wetter.y, uMaterial._WR_Wetter.z), uMaterial._WR_Wetter.w) > 0.0 ? uMaterial._WR_Wetter.yzw : vec3(0.42);
    float kraft;
    if (vWerte.w > 2.5)
    {
        kraft = vWerte.x * auslauf(lauf);
    }
    else if (vWerte.w > 1.5)
    {
        kraft = vWerte.x * auslauf(lauf * 0.9);
    }
    else
    {
        kraft = clamp(uMaterial._CastVect.w, 0.0, 1.0);
    }
    vec3 d2 = ton * (kraft * (1.0 - clamp(uMaterial._WR_Wetter.x, 0.0, 1.0)));
    if (max(d2.r, max(d2.g, d2.b)) < 0.004)
    {
        discard;
    }
    gl_FragDepth = gl_FragCoord.z + vTiefe * (clamp(max(d2.r, max(d2.g, d2.b)), 0.0, 0.9) + 0.02 * uMaterial._Color.g);
    outColor = vec4(vec3(1.0) - d2, 1.0);
}
