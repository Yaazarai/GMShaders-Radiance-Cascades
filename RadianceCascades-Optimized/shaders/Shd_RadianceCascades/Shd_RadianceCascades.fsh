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
#define EPS 0.000010
#define V2F16(v) ((v.y * float(0.0039215689)) + v.x)
#define F16V2(f) vec2(floor(f * 255.0) * float(0.0039215689), fract(f * 255.0))
#define PI  3.141592
#define ATAN2(d) ((((atan(d.y, -d.x) / PI) * .5) + .5) * TAU)

struct probe_info { float angular; vec2 linear, size, probe; float index, offset, range, scale; };	// Information struct about scene probes within the cascade.

vec3 tosrgb(vec3 color) { return pow(color, vec3(2.2)); }

// Get the direction-first probe information associated with the each probe of the current cascade (in_CascadeIndex).
probe_info cascadeTexelInfo(vec2 coord) {
	float angular = pow(2.0, in_CascadeIndex);												// Ray Count.
	vec2 linear = vec2(in_CascadeLinear * pow(2.0, in_CascadeIndex));						// Cascade Probe Spacing.
	vec2 size = in_CascadeExtent / angular;                                                 // Size of Probe-Group.
	vec2 probe = mod(floor(coord), size);                                                   // Probe-Group Index.
	vec2 raypos = floor(in_TexelCoord * angular);                                           //	* spatial-xy ray-index position.
	float index = raypos.x + (angular * raypos.y);                                          // PreAvg Index (actual = index * 4).
	float offset = (in_CascadeInterval  * (1.0 - pow(4.0, in_CascadeIndex))) / (1.0 - 4.0);	// Offset of Ray Interval (geometric sum).
	float range = in_CascadeInterval * pow(4.0, in_CascadeIndex);							// Length of Ray Interval (geometric sum).
		range += length(vec2(in_CascadeLinear * pow(2.0, in_CascadeIndex+1.0)));			//	* light Leak Fix.
	float scale = length(in_RenderExtent);                                                  // Diagonal of Render Extent (for SDF scaling).
	return probe_info(angular * angular, linear, size, probe, index, offset, range, scale); // Output probe information struct.
}

// Cast a ray from a probe (point) in direction (theta) with an interval offset/range specified by probe_info (info).
vec4 raymarch(vec2 point, float theta, probe_info info) {
	vec2 texel = 1.0 / in_RenderExtent;																// Scalar for converting pixel-coordinates back to screen-space UV.
	vec2 delta = vec2(cos(theta), -sin(theta));														// Ray component to move in the direction of theta.
	vec2 ray = (point + (delta * info.offset)) * texel;												// Ray origin at interval offset starting point.
	
	for(float i = 0.0, df = 0.0, rd = 0.0; i < info.range; i++) {									// Loop for max length of interval (in event that ray SDF is near 0 for entire length of ray).
		df = V2F16(texture2D(in_DistanceField, ray).rg);											// Distance sample of scene converted from 2-byte encoded distance scene texture.
		rd += df * info.scale;																		// Sum up total ray distance traveled (scale from distance UV to pixel-coordinates).
		ray += (delta * df * info.scale * texel);													// Move ray along its direction by SDF distance sample.
		
		if (rd >= info.range || floor(ray) != vec2(0.0)) break;										// If ray has reached range or out-of-bounds, return no-hit.
		if (df < EPS && rd < EPS && in_CascadeIndex != 0.0) return vec4(0.0);						// 2D light only cast light at their surfaces, not their volume.
		if (df < EPS) return vec4(texture2D(in_RenderScene, ray).rgb, 0.0);							// On-hit return radiance from scene (with visibility term of 0--e.g. no visibility to merge with higher cascades).
		//if (df < EPS) return vec4(tosrgb(texture2D(in_RenderScene, ray).rgb), 0.0);				// On-hit return radiance from scene (with visibility term of 0--e.g. no visibility to merge with higher cascades).
	}
	
	return vec4(0.0, 0.0, 0.0, 1.0);																// If no-hit return no radiance (with visibility term of 1--visibility to merge with higher cascades).
}

// Using hardware interpolation lookup 4 direction-first probes of cascade N+1 and merge with radiance of cascade N.
vec4 merge(vec4 rinfo, float index, probe_info pinfo) {
	if (rinfo.a == 0.0 || in_CascadeIndex >= in_CascadeCount - 1.0)							// For any radiance with zero-alpha do not merge (highest cascade also cannot merge).
		return vec4(rinfo.rgb, 1.0 - rinfo.a);												// Return non-merged radiance (invert alpha to correct alpha from raymarch ray-visibility term).
	
	float angularN1 = pow(2.0, in_CascadeIndex + 1.0);										// Angular resolution of cascade N+1 for probe lookups.
	vec2 sizeN1 = pinfo.size * 0.5;															// Size of probe group of cascade N+1 (N+1 has 1/4 total probe count or 1/2 each x,y axis).
	vec2 probeN1 = vec2(mod(index, angularN1), floor(index / angularN1)) * sizeN1;			// Get the probe group correlated to the ray index passed of the current cascade ray we're merging with.
	vec2 interpUVN1 = pinfo.probe * 0.5;													// Interpolated probe position in cascade N+1 (layouts match but with 1/2 count, probe falls into its interpolated position by default).
	vec2 clampedUVN1 = max(vec2(1.0), min(interpUVN1, sizeN1 - 1.0));						// Clamp interpolated probe position away from edge to avoid hardware inteprolation affecting merge lookups from adjacet probe groups.
	vec2 probeUVN1 = probeN1 + clampedUVN1 + 0.25;											// Final lookup cascade position of the interpolated merge lookup.
	vec4 interpolated = texture2D(gm_BaseTexture, probeUVN1 * (1.0 / in_CascadeExtent));	// Texture lookup of the merge sample.
	return rinfo + interpolated;															// Return original radiance input and merge with lookup sample.
}

// Single-Pass Cast-Interval and Merge fragment shader (cast cascade[N] intervals and merge with intervals of cascade[N+1].
void main() {
	probe_info pinfo = cascadeTexelInfo(floor(in_TexelCoord * in_CascadeExtent));		// Get info about the current probe on screen (position, angular index, etc.).
	vec2 origin = (pinfo.probe + 0.5) * pinfo.linear;									// Get this probes position in screen space.
	float preavg_index = pinfo.index * 4.0;												// Convert this probe's pre-averaged index to its actual angular index (casting 4x rays, but storing 1x averaged).
	float theta_scalar = TAU / (pinfo.angular * 4.0);									// Get the scalar for converting our angular index to radians (0 to 2pi).
	
	for(float i = 0.0; i < 4.0; i++) {													// Cast 4 rays, one for each angular index for this pre-averaged ray.
		float index = preavg_index + float(i),											// Get the actual index for this pre-averaged ray.
			theta = (index + 0.5) * theta_scalar;										// Get the actual angle (theta) for this pre-averaged ray.
		vec4 rinfo = raymarch(origin, theta, pinfo);									// Raymarch the current ray at the desired angle (raymarch function handles interval offsets).
		gl_FragColor += merge(rinfo, index, pinfo) * 0.25;						// Lookup the 4 rays of cascade N+1 in the same direction as this ray, merge and average results.
	}
	
	//if (in_CascadeIndex == 0.0)														// Only for cascade0, apply sRGB conversion.
	//	gl_FragColor = vec4(pow(gl_FragColor.rgb, vec3(1.0 / 2.2)), 1.0);				// sRGB apporximation.
}

/*
	Optimizations:
	1. Single-Pass Interval & Merge (raycast intervals and merge with cascade N+1).
	2. Pre-Averaging (cast 4 rays, average and store averaged result).
	* Angular resolution is fixed due to this change, adjust linear resolution for fidelity.
	3. Direction-First Hardware Interpolation (single-tap merge lookup).
	* "angular/direction-first probes," instead of "position/linear-first probes."
	
	Cascade Transition Fix: (Not Yet Implemented)
		4. Dolkar Mask Ringing Fix (smooths transitions between cascades at minimal cost).
*/