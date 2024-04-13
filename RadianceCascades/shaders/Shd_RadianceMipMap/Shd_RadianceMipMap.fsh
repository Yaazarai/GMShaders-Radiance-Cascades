varying vec2 in_TextCoord;
uniform float in_MipMapExtent;     // Cascade MipMap Resolution.
uniform float in_CascadeExtent;    // Cascade Diagonal Resolution.
uniform float in_CascadeIndex;     // Cascade index.
uniform float in_CascadeAngular;   // Cascade angular resolution.
uniform sampler2D in_CascadeAtlas; // MipMap Source Cascade [N].

struct ProbeTexel {
	float count;
	float size;
	float probes;
};

ProbeTexel cascadeProbeTexel(float cascadeIndex) {
	float count = in_CascadeAngular * pow(4.0, cascadeIndex);
	float size = sqrt(count);
	float probes = in_CascadeExtent / size;
	return ProbeTexel(count, size, probes);
}

// We fetch radiance intervals within the cascade by angle (thetaIndex) and probe (texelIndex).
vec4 cascadeFetch(ProbeTexel info, vec2 texelIndex, float thetaIndex) {
	vec2 probeTexel = texelIndex * info.size;
	probeTexel += vec2(mod(thetaIndex, info.size), (thetaIndex / info.size));
	vec2 cascadeTexelPosition = probeTexel / in_CascadeExtent;
	return texture2D(in_CascadeAtlas, cascadeTexelPosition);
}

void main() {
	// Get the mipmap's cascade texel info based on the cascade being rendered.
	ProbeTexel probeInfo = cascadeProbeTexel(in_CascadeIndex);
	vec2 mipmapCoord = vec2(in_TextCoord * in_MipMapExtent);
	
	// Loops through all of the radiance intervals for this mip-map and accumulate.
	vec4 radiance = vec4(0.0, 0.0, 0.0, 0.0);
	for(float i = 0.0; i < probeInfo.count; i ++)
		// cascadeFetch uses the probe's cell index, which is the same as the mipmap's pixel position.
		radiance += cascadeFetch(probeInfo, mipmapCoord, i);
	
	gl_FragColor = vec4(radiance.rgb / probeInfo.count, 1.0);
}