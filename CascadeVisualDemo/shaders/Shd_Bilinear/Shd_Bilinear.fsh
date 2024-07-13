//
// Simple passthrough fragment shader
//
varying vec2 v_vTexcoord;
varying vec4 v_vColour;

uniform vec4 colorTL;
uniform vec4 colorTR;
uniform vec4 colorBL;
uniform vec4 colorBR;

void main() {
	gl_FragColor = mix(
		mix(colorTL, colorTR, v_vTexcoord.x), 
		mix(colorBL, colorBR, v_vTexcoord.x),
	v_vTexcoord.y);
}