varying vec2 in_TextCoord;

#define F16V2(f) vec2(floor(f * 255.0) * float(0.0039215689), fract(f * 255.0))

void main() {
    vec4 scene = texture2D(gm_BaseTexture, in_TextCoord);
    gl_FragColor = vec4(F16V2(in_TextCoord.x * scene.a), F16V2(in_TextCoord.y * scene.a));
}