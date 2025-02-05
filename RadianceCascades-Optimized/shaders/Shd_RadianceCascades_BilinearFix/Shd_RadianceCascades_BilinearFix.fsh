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
#define PI (0.5*TAU)
#define V2F16(v) ((v.y * float(0.0039215689)) + v.x)
#define SRGB(c) pow(c.rgb, vec3(2.2))
#define LINEAR(c) pow(c.rgb, vec3(1.0 / 2.2))

vec4 raymarch(vec2 origin, vec2 delta, float interval) {
	for(float ii = 0.0, dd = 0.0, rr = 0.0, ee = 0.00001, scale = length(in_RenderExtent); ii < interval; ii++) {
		vec2 ray = (origin + (delta * rr)) * (1.0 / in_RenderExtent);
		rr += scale * (dd = V2F16(texture2D(in_DistanceField, ray).rg));
		if (rr >= interval || floor(ray) != vec2(0.0)) break;
		if (dd <= ee) return vec4(SRGB(texture2D(in_RenderScene, ray).rgb), 0.0);
	}
	return vec4(0.0, 0.0, 0.0, 1.0);
}

vec4 mergeNearestProbe(vec4 radiance, float index, vec2 probe) {
	if (radiance.a == 0.0 || in_CascadeIndex >= in_CascadeCount - 1.0)
		return vec4(radiance.rgb, 1.0 - radiance.a);
	
	float angularN1 = pow(2.0, floor(in_CascadeIndex + 1.0));
	vec2 extentN1 = floor(in_CascadeExtent / angularN1);
	vec2 interpN1 = vec2(mod(index, angularN1), floor(index / angularN1)) * extentN1;
	interpN1 += clamp(probe + 0.5, vec2(0.5), extentN1 - vec2(0.5));
	return texture2D(gm_BaseTexture, interpN1 * (1.0 / in_CascadeExtent));
}

void getBilinearProbes(vec2 probe, out vec2 probes[4]) {
	vec2 probeN1 = floor((probe - 1.0) / 2.0);
	probes[0] = probeN1 + vec2(0.0, 0.0);
	probes[1] = probeN1 + vec2(1.0, 0.0);
	probes[2] = probeN1 + vec2(0.0, 1.0);
	probes[3] = probeN1 + vec2(1.0, 1.0);
}

float ATAN2(float yy, float xx) { return mod(atan(yy, xx), TAU); }

void main() {
	vec2 coord = floor(in_TexelCoord * in_CascadeExtent);
	float sqr_angular = pow(2.0, floor(in_CascadeIndex));
	vec2 extent = floor(in_CascadeExtent / sqr_angular);
	vec4 probe = vec4(mod(coord, extent), floor(coord / extent));
	float interval = (in_CascadeInterval * (1.0 - pow(4.0, in_CascadeIndex))) / (1.0 - 4.0);
	float limit = in_CascadeInterval * pow(4.0, in_CascadeIndex);
	
	float interval_start = interval;
	float interval_end = interval + limit;
	
	vec2 linear = vec2(in_CascadeLinear * pow(2.0, in_CascadeIndex));
	vec2 linearN1 = vec2(in_CascadeLinear * pow(2.0, in_CascadeIndex + 1.0));
	
	vec2 origin = (probe.xy + 0.5) * linear;
	float angular = sqr_angular * sqr_angular * 4.0;
	float index = (probe.z + (probe.w * sqr_angular)) * 4.0;
	
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// Bilinear Fix:
	vec2 bilinearN1[4];
	getBilinearProbes(probe.xy, bilinearN1);
	vec2 texelIndexN1 = floor((vec2(probe.xy) - 1.0) / 2.0);
	vec2 texelIndexN1_N = floor((texelIndexN1 * 2.0) + 1.0);
	vec2 weight = vec2(0.25) + (vec2(probe.xy) - texelIndexN1_N) * vec2(0.5);
	////////////////////////////////////////////////////////////////////////////////////////////////////////////
	
	gl_FragColor = vec4(0.0);
	for(float i = 0.0; i < 4.0; i++) {
		float preavg = index + float(i);
		float theta = (preavg + 0.5) * (TAU / angular);
		float thetaNm1 = (floor(preavg/4.0) + 0.5) * (TAU / (angular/4.0));
		vec2 delta = vec2(cos(theta), -sin(theta));
		vec2 deltaNm1 = vec2(cos(thetaNm1), -sin(thetaNm1));
		vec2 ray_start = origin + (deltaNm1 * interval);
		
		////////////////////////////////////////////////////////////////////////////////////////////////////////////
		/// Bilinear Fix:
		vec4 samples[4];
		for(float j = 0.0; j < 4.0; j++) {
			vec2 originN1 = (bilinearN1[int(j)] + 0.5) * linearN1;
			vec2 ray_end = originN1 + (delta * (interval + limit));
			samples[int(j)] = raymarch(ray_start, normalize(ray_end - ray_start), length(ray_end - ray_start));
			samples[int(j)] = mergeNearestProbe(samples[int(j)], preavg, bilinearN1[int(j)]);
		}
		
		vec4 top = mix(samples[0], samples[1], weight.x);
		vec4 bot = mix(samples[2], samples[3], weight.x);
		vec4 rad = mix(top, bot, weight.y);
		////////////////////////////////////////////////////////////////////////////////////////////////////////////
		
		gl_FragColor += rad * 0.25;
	}
	
	if (in_CascadeIndex < 1.0)
		gl_FragColor = vec4(LINEAR(gl_FragColor), 1.0);
}

/*
	Bilinear Fix:
		This is a reprojection fix which casts 4x as many rays, one ray to the starting position
		of each set of bilinear rays (merged rays from bilinear probes). This ensures that we
		continuously and consistently observe radiance projected from each bilinear probe.
		
		Then each ray merges with the rays from its respective bilinear-probe WITHOUT interpolation.
		Finally radiance is manually interpolated from the reprojected bilinear-rays just like Vanilla RC.
		
		To fix light leak rays are "forked," starting from 1/4th as many positions to match
		the angular resolution of the previous cascade for perfectly continuous intervals.
*/