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
#define EPS 0.000100
#define V2F16(v) ((v.y * float(0.0039215689)) + v.x)
#define SRGB(c) pow(c.rgb, vec3(2.2))

struct probe_info { float angular, linear; vec2 extent, probe; float index, interval, limit; };
probe_info cascadeTexelInfo() {
	float angular = pow(2.0, in_CascadeIndex);
	float raycount = angular * angular;
	float linear = in_CascadeLinear * pow(2.0, in_CascadeIndex);
	vec2 extent = floor(in_CascadeExtent / angular);
	vec2 texel = floor(in_TexelCoord * in_CascadeExtent);
	vec2 probe = mod(texel, extent);
	vec2 sector = floor(texel / extent);
	float index = mod(sector.x + (sector.y * angular), raycount);
	float interval = (in_CascadeInterval  * (1.0 - pow(4.0, in_CascadeIndex))) / (1.0 - 4.0);
	float limit = in_CascadeInterval * pow(4.0, in_CascadeIndex);	
		limit += length(vec2(in_CascadeLinear * pow(2.0, in_CascadeIndex + 1.0)));
	return probe_info(raycount, linear, extent, probe, index, interval, limit);
}

vec4 raymarch(vec2 point, float theta, float sdfscale, probe_info pinfo) {
	vec2 texel = 1.0 / in_RenderExtent;
	vec2 delta = vec2(cos(theta), -sin(theta));
	vec2 ray = (point + (delta * pinfo.interval)) * texel;
	
	for(float i = 0.0, df = 0.0, rd = 0.0; i < pinfo.limit; i++) {
		df = V2F16(texture2D(in_DistanceField, ray).rg);
		rd += df * sdfscale;
		ray += delta * df * sdfscale * texel;
		
		if (rd >= pinfo.limit || floor(ray) != vec2(0.0)) break;
		if (df <= EPS && rd <= EPS && in_CascadeIndex != 0.0) return vec4(0.0);
		if (df <= EPS) return vec4(SRGB(texture2D(in_RenderScene, ray).rgb), 0.0);
	}
	
	return vec4(0.0, 0.0, 0.0, 1.0);
}

vec4 merge(vec4 rinfo, float index, probe_info pinfo) {
	if (rinfo.a == 0.0 || in_CascadeIndex >= in_CascadeCount - 1.0)
		return vec4(rinfo.rgb, 1.0 - rinfo.a);
	
	float angularN1 = pow(2.0, in_CascadeIndex + 1.0);
	vec2 sizeN1 = floor(pinfo.extent * 0.5);
	vec2 probeN1 = vec2(mod(index, angularN1), floor(index / angularN1)) * sizeN1;
	vec2 interpUVN1 = (pinfo.probe * 0.5) + 0.25;
	vec2 clampedUVN1 = max(vec2(1.0), min(interpUVN1, sizeN1 - 1.0));
	vec2 probeUVN1 = probeN1 + clampedUVN1;
	vec4 interpolated = texture2D(gm_BaseTexture, probeUVN1 * (1.0 / in_CascadeExtent));
	return rinfo + interpolated;
}

void main() {
	float sdfscale = length(in_RenderExtent);
	probe_info pinfo = cascadeTexelInfo();
	vec2 origin = (pinfo.probe + 0.5) * pinfo.linear;
	float preavg_index = pinfo.index * 4.0;
	float theta_scalar = TAU / (pinfo.angular * 4.0);
	
	for(float i = 0.0; i < 4.0; i++) {
		float index = preavg_index + float(i),
			theta = (index + 0.5) * theta_scalar;
		vec4 rinfo = raymarch(origin, theta, sdfscale, pinfo);
		gl_FragColor += merge(rinfo, index, pinfo) * 0.25;
	}
	 
	if (in_CascadeIndex == 0.0)
		gl_FragColor = vec4(pow(gl_FragColor.rgb, vec3(1.0 / 2.2)), 1.0);
}