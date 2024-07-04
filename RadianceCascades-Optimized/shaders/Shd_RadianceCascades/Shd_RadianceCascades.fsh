varying vec2 in_TexelCoord;
uniform sampler2D in_RenderScene;
uniform sampler2D in_DistanceField;
uniform vec2 in_RenderExtent;
uniform vec2 in_CascadeExtent;
uniform float in_CascadeCount;
uniform float in_CascadeIndex;
uniform float in_CascadeLinear;
uniform float in_CascadeInterval;

#define TAU 6.283185
#define EPS 0.0001
#define V2F16(v) ((v.y * float(0.0039215689)) + v.x)
#define F16V2(f) vec2(floor(f * 255.0) * float(0.0039215689), fract(f * 255.0))

struct probe_info {
	float angular;
	vec2 linear, size, probe;
	float index, offset, range, scale;
};

probe_info cascadeTexelInfo(vec2 coord) {
	float angular = pow(2.0, in_CascadeIndex);                                              // Ray Count.
	vec2 linear = vec2(in_CascadeLinear * pow(2.0, in_CascadeIndex));                       // Cascade Probe Spacing.
	vec2 size = in_CascadeExtent / angular;                                                 // Size of Probe-Group.
	vec2 probe = mod(floor(coord), size);                                                   // Probe-Group Index.
	vec2 raypos = floor(in_TexelCoord * angular);                                           //	* spatial-xy ray-index position.
	float index = raypos.x + (angular * raypos.y);                                          // PreAvg Index (actual = index * 4).
	float offset = (in_CascadeInterval  * (1.0 - pow(4.0, in_CascadeIndex))) / (1.0 - 4.0); // Offset of Ray Interval (geometric sum).
	float range = in_CascadeInterval * pow(4.0, in_CascadeIndex);                           // Length of Ray Interval (geometric sum).
	float scale = length(in_RenderExtent);                                                  // Diagonal of Render Extent (for SDF scaling).
	return probe_info(angular * angular, linear, size, probe, index, offset, range, scale); // Output probe information struct.
}

vec4 raymarch(vec2 point, float theta, probe_info info) {
	vec2 texel = 1.0 / in_RenderExtent;
	vec2 delta = vec2(cos(theta), -sin(theta));
	vec2 ray = point + (delta * info.offset);
	for(float i = 0.0, df = 0.0, rd = 0.0; i < info.range; i++) {
		df = V2F16(texture2D(in_DistanceField, ray * texel).rg);
		rd += df * info.scale;
		ray += delta * df * info.scale;
		
		if (rd >= info.range || ray.x < 0.0 || ray.y < 0.0 || ray.x >= in_RenderExtent.x || ray.y >= in_RenderExtent.y) break;
		if (df < EPS) return vec4(texture2D(in_RenderScene, ray * texel).rgb, 0.0);
	}
	
	return vec4(0.0, 0.0, 0.0, 1.0);
}

vec4 merge(vec4 radiance, float index, probe_info info) {
	float angularN1 = pow(2.0, in_CascadeIndex + 1.0);
	vec2 extentN1 = info.size * 0.5;
	vec2 probeN1 = vec2(mod(index, angularN1), floor(index / angularN1)) * extentN1;
	vec2 clampedUVN1 = max(vec2(1.0), min(info.probe * 0.5, extentN1 - 1.0));
	vec2 probeUVN1 = probeN1 + clampedUVN1 + 0.25;
	vec4 interpolated = texture2D(gm_BaseTexture, probeUVN1 * (1.0 / in_CascadeExtent));
	return radiance + (radiance.a * interpolated);
}

void main() {
	probe_info info = cascadeTexelInfo(floor(in_TexelCoord * in_CascadeExtent));
	
	vec2 origin = (info.probe + 0.5) * info.linear;
	float preavg_index = info.index * 4.0;
	float theta_scalar = TAU / (info.angular * 4.0);
	
	vec4 samples[4];
	for(int i = 0; i < 4; i++) {
		float index = preavg_index + float(i);
		samples[i] = raymarch(origin, (index + 0.5) * theta_scalar, info);
		
		if (samples[i].a != 0.0 && in_CascadeIndex < in_CascadeCount - 1.0)
			samples[i] = merge(samples[i], index, info);
		else
			samples[i].a = 1.0 - samples[i].a;
	}
	
	gl_FragColor = (samples[0] + samples[1] + samples[2] + samples[3]) / 4.0;
}

/*
	Optimizations:
	1. Single-Pass Interval & Merge (raycast intervals and merge with cascade N+1).
	2. Pre-Averaging (cast 4 rays, average and store averaged result).
	* Angular resolution is fixed due to this change, adjust linear resolution for fidelity.
	3. Direction-First Hardware Interpolation (single-tap merge lookup).
	* "angular/direction-first probes," instead of "position/linear-first probes."
*/