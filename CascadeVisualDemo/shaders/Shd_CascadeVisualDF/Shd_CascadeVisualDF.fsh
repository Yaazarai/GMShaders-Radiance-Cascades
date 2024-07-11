//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;
uniform float in_CascadeSize;
uniform float in_CascadeIndex;

void main() {
	vec2 texel = v_vTexcoord * in_CascadeSize;
	float sectors = pow(2.0, in_CascadeIndex);
	vec2 size = vec2(in_CascadeSize / sectors);
	gl_FragColor = vec4(mod(texel, size) / size, 0.0, 1.0);
}