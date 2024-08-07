varying vec2 in_TexelCoord;
uniform vec2 in_RenderExtent;

#define V2F16(v) ((v.y * float(0.0039215689)) + v.x)
#define F16V2(f) vec2(floor(f * 255.0) * float(0.0039215689), fract(f * 255.0))

void main() {
    vec4 jfuv = texture2D(gm_BaseTexture, in_TexelCoord);
    vec2 jumpflood = vec2(V2F16(jfuv.rg),V2F16(jfuv.ba));
	float dist = distance(in_TexelCoord * in_RenderExtent, jumpflood * in_RenderExtent);
	gl_FragColor = vec4(F16V2(dist / length(in_RenderExtent)), 0.0, 1.0);
}