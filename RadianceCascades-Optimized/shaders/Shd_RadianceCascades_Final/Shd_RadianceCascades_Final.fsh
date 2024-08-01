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
#define V2F16(v) ((v.y * float(0.0039215689)) + v.x)
#define SRGB(c) pow(c.rgb, vec3(2.2))
#define LINEAR(c) pow(c.rgb, vec3(1.0 / 2.2))

vec4 raymarch(vec2 origin, vec2 delta, float interval) {
	float scale = length(in_RenderExtent);
	for(float ii = 0.0, dd = 0.0, rr = 0.0, ee = 0.0001; ii < interval; ii++) {
		vec2 ray = (origin + (delta * rr)) * (1.0 / in_RenderExtent);
		rr += scale * (dd = V2F16(texture2D(in_DistanceField, ray).rg));
		if (rr >= interval || floor(ray) != vec2(0.0)) break;
		if (dd <= ee) return vec4(SRGB(texture2D(in_RenderScene, ray).rgb), 0.0);
	}
	return vec4(0.0, 0.0, 0.0, 1.0);
}

vec4 merge(vec4 radiance, float index, vec2 extent, vec2 probe) {
	if (radiance.a == 0.0 || in_CascadeIndex >= in_CascadeCount - 1.0)
		return vec4(radiance.rgb, 1.0 - radiance.a);
	float angularN1 = pow(2.0, floor(in_CascadeIndex + 1.0));
	vec2 extentN1 = floor(in_CascadeExtent / angularN1);
	vec2 interpN1 = vec2(mod(index, angularN1), floor(index / angularN1)) * extentN1;
	interpN1 += clamp((probe * 0.5) + 0.25, vec2(1.0), extentN1 - 1.0);
	return radiance + texture2D(gm_BaseTexture, interpN1 * (1.0 / in_CascadeExtent));
}

void main() {
	vec2 coord = floor(in_TexelCoord * in_CascadeExtent);
	float sqr_angular = pow(2.0, floor(in_CascadeIndex));
	vec2 extent = floor(in_CascadeExtent / sqr_angular);
	vec4 probe = vec4(mod(coord, extent), floor(coord / extent));
	float interval = (in_CascadeInterval  * (1.0 - pow(4.0, in_CascadeIndex))) / (1.0 - 4.0);
	vec2 linear = vec2(in_CascadeLinear * pow(2.0, in_CascadeIndex));
	float limit = (in_CascadeInterval * pow(4.0, in_CascadeIndex)) + length(linear * 2.0);
	vec2 origin = (probe.xy + 0.5) * linear;
	float angular = sqr_angular * sqr_angular * 4.0;
	float index = (probe.z + (probe.w * sqr_angular)) * 4.0;
	
	for(float i = 0.0; i < 4.0; i++) {
		float preavg = index + float(i);
		float theta = (preavg + 0.5) * (TAU / angular);
		vec2 delta = vec2(cos(theta), -sin(theta));
		vec2 ray = origin + (delta * interval);
		vec4 radiance = raymarch(ray, delta, limit);
		gl_FragColor += merge(radiance, preavg, extent, probe.xy) * 0.25;
	}
	
	if (in_CascadeIndex == 0.0)
		gl_FragColor = vec4(LINEAR(gl_FragColor), 1.0);
}