if (!surface_exists(gameworld_worldscene)) gameworld_worldscene = surface_create(global.radiance_render_extent, global.radiance_render_extent);
if (!surface_exists(gameworld_temporary)) gameworld_temporary = surface_create(global.radiance_render_extent, global.radiance_render_extent);
if (!surface_exists(gameworld_jumpflood)) gameworld_jumpflood = surface_create(global.radiance_render_extent, global.radiance_render_extent);
if (!surface_exists(gameworld_distancefield)) gameworld_distancefield = surface_create(global.radiance_render_extent, global.radiance_render_extent);

if (!surface_exists(gameworld_radiance)) gameworld_radiance = surface_create(global.radiance_render_extent, global.radiance_render_extent);
if (!surface_exists(gameworld_bouncescene)) gameworld_bouncescene = surface_create(global.radiance_render_extent, global.radiance_render_extent);

if (!surface_exists(gameworld_storage)) gameworld_storage = surface_create(global.radiance_cascade_extent, global.radiance_cascade_extent);

for(var i = 0; i < global.radiance_cascade_count; i++) {
	var cascade_extent = global.radiance_cascade_extent;
	if (!surface_exists(gameworld_cascades[i]))
		gameworld_cascades[i] = surface_create(cascade_extent, cascade_extent);
	
	radiance_clear(gameworld_cascades[i]);
	
	var angular_resolution = sqrt(global.radiance_cascade_angular * power(4.0, i));
	var mipmap_extent = global.radiance_cascade_extent / angular_resolution;
	//show_debug_message("RESOLUTION[I]: {0} -- {1} : {2} : {3}", i, cascade_extent, mipmap_extent, angular_resolution);
	
	if (!surface_exists(gameworld_mipmaps[i]))
		gameworld_mipmaps[i] = surface_create(mipmap_extent, mipmap_extent);
}