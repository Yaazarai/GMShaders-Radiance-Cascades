/*
	Radiance Cascades solves the rendering equation by having several
	grids of radiance probes (cascades) within a scene that check raymarch
	for light at varying intervals (distances and ranges) away from the
	radiance probes depending on the N-index of the cascade.
	
	Lower cascades have higher linear resolution and sample closer to the
	the probes with less rays-per-probe and have more probes per cascade.
	
	Higher cascades have higher anuglar resolution and sample further from
	the probes with more rays-per-probe and have less probes per cascade.
	
	This is due to how penumbras (edges of shadows) work where the accuracy
	of the shadow (how blurry it is) is sharper closer to light sources and
	blurrier further from light sources. Neat!
	
	By default this implementation uses quadrupling for ray counts and probes
	between cascades. If cascade0 has 16 rays and 256 probes, cascade1 has 64
	rays and 64 probes, then 256 rays and 16 probes and so on.
	
	Shader Passes:
		1. Cascades (Raymarches the probes in each cascade).
		2. Merging (Merges N and N+1 cascades for all cascades, excludes mipmapping).
		3. Interpolate (-1 with 0. Cascade -1 is screen space, Cascade 0 is the first/final cascade).
*/
// Disable Surface Depth Buffer (for memory profiling).
surface_depth_disable(true);

var width = 1024.0, height = 1024.0;
// Passing 0 or less cascades will optimally calculate the number of required cascades.
// Parameters: [angular] is power of 4, [interval] is multiple of 4, [spacing] is power of 2.
// Any value passed that does not conform to these rules will be automatically adjusted (adjusted up).
radiance_initialize(max(width, height), 4, 4, 2, 1.0, 0.65);
radiance_defaultshaders(Shd_JumpfloodSeed, Shd_JumpfloodAlgorithm, Shd_DistanceField, Shd_RadianceIntervals, Shd_RadianceMerging, Shd_RadianceMipMap);

var bytes = 4.0 * sqr(global.radiance_cascade_extent) * global.radiance_cascade_count;
show_debug_message("\nRender  Diagonal: {0}", string(global.radiance_render_extent));
show_debug_message(  "Cascade Diagonal: {0}", string(global.radiance_cascade_extent));
show_debug_message(  "Cascade Count: {0}", string(global.radiance_cascade_count));
show_debug_message(  "Cascade Angular: {0}", string(global.radiance_cascade_angular));
show_debug_message(  "Cascade Interval: {0}", string(global.radiance_cascade_interval));
show_debug_message(  "Cascade Spacing: {0}", string(global.radiance_cascade_spacing));
show_debug_message(  "Cascade Memory: {0} MB\n", string(bytes / 1024 / 1024));

#macro INVALID_SURFACE -1
gameworld_worldscene = INVALID_SURFACE;
gameworld_temporary = INVALID_SURFACE;
gameworld_jumpflood = INVALID_SURFACE;
gameworld_distancefield = INVALID_SURFACE;

gameworld_radiance = INVALID_SURFACE;
gameworld_bouncescene = INVALID_SURFACE;

gameworld_storage = INVALID_SURFACE;
for(var i = 0; i < global.radiance_cascade_count + 1; i++) {
	gameworld_cascades[i] = INVALID_SURFACE;
	gameworld_mipmaps[i] = INVALID_SURFACE;
}

global.showcascade = 0;