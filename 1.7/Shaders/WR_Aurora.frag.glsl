#version 450

layout(location = 2) in vec3 vWorldPos;

layout(location = 0) out vec4 outColor;

layout(set = 2, binding = 0) uniform MaterialUniforms
{
    vec4 _Color;      // @color @default = vec4(1.0, 1.0, 1.0, 1.0)
    vec4 _MainTex_ST; // @default = vec4(0.0, 0.0, 1.0, 1.0)
    vec4 _WR_Aurora;
    vec4 _WR_AuroraTon;
    vec4 _WR_AuroraForm;
} uMaterial;

layout(set = 2, binding = 1) uniform sampler2D _MainTex;

float streu(vec2 p)
{
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

float rauschen(vec2 p)
{
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = streu(i);
    float b = streu(i + vec2(1.0, 0.0));
    float c = streu(i + vec2(0.0, 1.0));
    float d = streu(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void main()
{
    float staerke = uMaterial._WR_Aurora.y;
    if (staerke < 0.002)
    {
        discard;
    }
    float t = uMaterial._WR_Aurora.x;
    float abstand = max(4.0, uMaterial._WR_AuroraForm.x);
    float kantenBreite = max(0.004, uMaterial._WR_AuroraForm.y);
    float strahlen = clamp(uMaterial._WR_AuroraForm.z, 0.0, 1.0);
    float saum = max(0.05, uMaterial._WR_AuroraForm.w);
    vec2 g = vWorldPos.xz / abstand;
    vec2 w = vec2(rauschen(g * 0.9 + vec2(t * 0.011, 3.7)), rauschen(g * 0.9 + vec2(11.3, -t * 0.009)));
    w += 0.5 * vec2(rauschen(g * 2.1 + vec2(-t * 0.02, 7.1)), rauschen(g * 2.1 + vec2(5.9, t * 0.017)));
    float lauf = g.y + (w.x - 0.75) * 0.7 + 0.3 * sin(g.x * 1.3 + t * 0.03 + w.y * 2.5) + t * 0.004;
    float nummer = floor(lauf);
    float phase = lauf - nummer;
    float kante = smoothstep(0.0, kantenBreite, phase);
    float schweif = exp(-phase / saum * 3.0);
    float hell = smoothstep(0.22, 0.7, rauschen(vec2(nummer * 7.31, g.x * 0.45 + t * 0.02)));
    float strahl = rauschen(vec2(g.x * 22.0 + w.y * 9.0 + t * 0.15, nummer * 3.1 + phase * 0.6));
    float huelle = smoothstep(0.2, 0.65, rauschen(g * 0.33 + vec2(t * 0.006, -t * 0.004) + 20.0));
    float licht = kante * schweif * hell * mix(1.0, 0.25 + 1.5 * strahl * strahl, strahlen) * huelle + 0.05 * huelle;
    vec3 ton = uMaterial._WR_AuroraTon.rgb;
    vec3 zweit = mix(ton.brg, vec3(0.8, 0.2, 1.0), 0.5);
    vec3 farbe = mix(ton, zweit, smoothstep(0.1, 0.8, phase / saum) * uMaterial._WR_Aurora.z);
    float maske = texture(_MainTex, vec2(0.5, 0.5)).a;
    outColor = vec4(farbe * (licht * staerke * maske), 1.0);
}
