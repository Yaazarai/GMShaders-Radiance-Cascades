varying vec2 in_TextCoord;
uniform float     in_RenderExtent;  // Scren Space Resolution.
uniform sampler2D in_DistanceField; // World Input Distance Field.
uniform sampler2D in_WorldScene;    // World Input Raymarch Scene.
uniform float in_RenderDecayRate;   // How quickly 

uniform float in_CascadeExtent;   // Cascade Diagonal Resolution.
uniform float in_CascadeSpacing;  // Cascade 0 probe spacing.
uniform float in_CascadeInterval; // Cascade 0 radiance interval.
uniform float in_CascadeAngular;  // Cascade angular resolution.
uniform float in_CascadeIndex;    // Cascade index.

#define EPSILON       0.0001
#define TAU           6.283185
#define V2F16(v) ((v.y * float(0.0039215689)) + v.x)

struct ProbeTexel {
	float count;   // number of ray-directions in this probe.
	vec2 probe;   // the cell index of this probe.
	vec2 spacing; // spacing between radiance probes.
	float index;   // the theta-index of this texel in it's probe.
	float minimum; // minimum interval-range.
	float range;   // interval length (range).
	float texel;   // texel size: 1.0 / cascadeExtent;
	//vec2 position; // cascade texel probe position.
};

ProbeTexel cascadeProbeTexel(vec2 coord, float cascade) {
	float count = in_CascadeAngular * pow(4.0, cascade);
	float size = sqrt(count);
	vec2 probe = floor(coord / vec2(size));
	vec2 spacing = vec2(in_CascadeSpacing * pow(2.0, cascade));
	
	vec2  probePos = mod(floor(coord), vec2(size));
	float index = (probePos.y * size) + probePos.x;
	
	float minimum = sign(cascade) * ((in_CascadeInterval  * (1.0 - pow(4.0, cascade))) / (1.0 - 4.0));
	float range = in_CascadeInterval * pow(4.0, cascade);
	
	// Light Leak Fix: (expand interval by diag-length of the cascade spacing).
	float d = in_CascadeSpacing * pow(2.0, cascade+1.0);
	range += sign(cascade) * length(vec2(d,d));
	
	float texel = 1.0 / in_RenderExtent;
	return ProbeTexel(count, probe, spacing, index, minimum, range, texel /*, probePos / vec2(size)*/);
}

// Raymarching function: Raymarch from "pos" in direction of "delta," for length of "range" (non-normalized, range in pixel space):
vec4 raymarch(vec2 pos, vec2 delta, float range, float texel) {
	//
	// Ray Visibility Term: The A (Alpha Component) returns the transparency of this ray.
	//	* A visibility term of 0.0 means this ray is fully opaque (object hit).
	//	* A visibility term of 1.0 means this ray is transparent (no hit).
	//		When merging cascade rays with NO hits (1.0 visibility term) are the only
	//		rays which will merge with above cascades. This applies merging/smoothing
	//		of rays between cascade ranges to create those smooth shadows.
	//
	//	Interval Raymarching (raymarches a specific range away from probe):
	//
	for(float ii = 0.0, dd = 0.0, rd = 0.0, rt = range * texel; ii < range; ii++) {
		vec2 ray = pos + delta * min(rd, rt);
		rd += dd = V2F16(texture2D(in_DistanceField, ray).rg);
		// Offscreen or End of Interval no collision:
		if (rd >= rt || ray.x < 0.0 || ray.y < 0.0 || ray.x >= 1.0 || ray.y >= 1.0) break;
		// Surface/Object collision:
		if (dd <= EPSILON) return vec4(texture2D(in_WorldScene, ray).rgb, 1.0);
	}
	return vec4(0.0, 0.0, 0.0, 0.0);
}

// Default Ray-marching Implementation.
vec4 marchInterval_VanillaBranch(vec2 texel) {
	ProbeTexel probeInfo = cascadeProbeTexel(texel, in_CascadeIndex);
	vec2 probe = vec2((probeInfo.probe+0.5) * probeInfo.spacing) * probeInfo.texel;
	float theta = TAU * ((probeInfo.index+0.5) / probeInfo.count);
	vec2 delta = vec2(cos(theta), -sin(theta));
	vec2 interval = probe + (delta * probeInfo.minimum * probeInfo.texel);
	return raymarch(interval, delta, probeInfo.range, probeInfo.texel);
}

void main() {
	vec2 texel = in_TextCoord * vec2(in_CascadeExtent);
	gl_FragColor = marchInterval_VanillaBranch(texel);
}

//
// Cascade Radiance:
//		gl_FragColor = vec4(intervalRayMarch(probeInfo).rgb, 1.0);
//
// Cascade Prob Texel Space:
//		gl_FragColor = vec4(probeInfo.position, 0.0, 1.0);
//
