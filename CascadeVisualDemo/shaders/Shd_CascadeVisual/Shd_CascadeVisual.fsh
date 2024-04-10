//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float in_CascadeSize;
uniform float in_CascadeIndex;
uniform float in_CascadeAngular;

void main() {
    vec2 texel = v_vTexcoord * in_CascadeSize;
	float size = sqrt(pow(4.0, in_CascadeIndex) * in_CascadeAngular);
	gl_FragColor = vec4(mod(texel, size) / size, 0.0, 1.0);
}
