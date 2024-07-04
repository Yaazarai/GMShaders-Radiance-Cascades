varying vec2 in_TexelCoord;

#define F16V2(f) vec2(floor(f * 255.0) * float(0.0039215689), fract(f * 255.0))

void main() {
    vec4 scene = texture2D(gm_BaseTexture, in_TexelCoord);
    gl_FragColor = vec4(F16V2(in_TexelCoord.x * scene.a), F16V2(in_TexelCoord.y * scene.a));
}