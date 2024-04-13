if (surface_exists(gameworld_worldscene)) surface_free(gameworld_worldscene);
if (surface_exists(gameworld_temporary)) surface_free(gameworld_temporary);
if (surface_exists(gameworld_jumpflood)) surface_free(gameworld_jumpflood);
if (surface_exists(gameworld_distancefield)) surface_free(gameworld_distancefield);

if (surface_exists(gameworld_radiance)) surface_free(gameworld_radiance);
if (surface_exists(gameworld_bouncescene)) surface_free(gameworld_bouncescene);

if (surface_exists(gameworld_storage)) surface_free(gameworld_storage);
for(var i = 0; i < global.radiance_cascade_count; i++) {
	if (surface_exists(gameworld_cascades[i]))
		surface_free(gameworld_cascades[i]);
	
	if (surface_exists(gameworld_mipmaps[i]))
		surface_free(gameworld_mipmaps[i]);
}