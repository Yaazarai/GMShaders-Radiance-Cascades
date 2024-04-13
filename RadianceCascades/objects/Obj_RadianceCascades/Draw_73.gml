// Disable blending for Jump Flood render processes (we don't care about alpha components here).
surface_set_target(gameworld_bouncescene);
draw_surface(gameworld_radiance, 0, 0);
draw_set_color(c_white);
draw_set_alpha(1.0);
draw_surface(gameworld_worldscene, 0, 0);
surface_reset_target();

gpu_set_blendenable(false);
gpu_set_texrepeat(false);

	// Generate the JFA + SDF of the world scene.
	radiance_jfaseed(gameworld_worldscene, gameworld_temporary, gameworld_jumpflood);
	radiance_jumpflood(gameworld_temporary, gameworld_jumpflood);
	radiance_distancefield(gameworld_jumpflood, gameworld_distancefield);
	radiance_clear(gameworld_storage);

// Calculate initial Radiance Intervals.
radiancecascades_intervals(gameworld_bouncescene, gameworld_distancefield, gameworld_cascades, gameworld_storage);

// Merged Radiance Intervals from Cascades.
radiancecascades_merging(gameworld_cascades, gameworld_storage);

// Generate Cascade[N] mip-map (debugging visualization).
radiancecascades_mipmap(gameworld_cascades, gameworld_mipmaps);

// Generate Screen Radiance from Merged Cascade mip-map.
//radiancecascades_screenmerge(gameworld_radiance, gameworld_temporary, gameworld_mipmaps);

// Re-Enable Alpha Blending since the Jump Flood pass is complete.
gpu_set_blendenable(true);

//draw_surface(gameworld_worldscene, 0, 0);
//draw_surface(gameworld_jumpflood, 0, 0);
//draw_surface(gameworld_distancefield, 0, 0);
draw_surface(gameworld_radiance, 0, 0);

//var xscale = global.radiance_render_extent / global.radiance_cascade_extent;
//var yscale = global.radiance_render_extent / global.radiance_cascade_extent;
//draw_surface_ext(gameworld_cascades[global.showcascade], 0, 0, xscale, yscale, 0, c_white, 1);

surface_set_target(gameworld_radiance);
draw_clear_alpha(c_black, 0);
gpu_set_blendmode(bm_add);
var xscale = global.radiance_render_extent / surface_get_width(gameworld_mipmaps[global.showcascade]);
var yscale = global.radiance_render_extent / surface_get_height(gameworld_mipmaps[global.showcascade]);
gpu_set_tex_mip_filter(tf_linear);
draw_surface_ext(gameworld_mipmaps[global.showcascade], 0, 0, xscale, yscale, 0, c_white, 1.0);
draw_surface_ext(gameworld_mipmaps[global.showcascade], 0, 0, xscale, yscale, 0, c_white, 0.5);
gpu_set_blendmode(bm_normal);
surface_reset_target();

draw_surface(gameworld_radiance, 0, 0);