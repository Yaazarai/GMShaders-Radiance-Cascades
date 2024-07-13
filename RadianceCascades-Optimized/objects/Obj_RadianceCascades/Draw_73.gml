var gpu_blend = gpu_get_blendenable();
var gpu_texrepeat = gpu_get_tex_repeat();
var gpu_filter = gpu_get_tex_filter();

gpu_set_blendenable(false);
gpu_set_texrepeat(false);
gpu_set_tex_filter(true);

	// Calculate scene JFA and output SDF.
	radiance_jfaseed(radiance_world.memory, radiance_jfa.memory, radiance_sdf.memory, Shd_SeedJumpFlood);
	radiance_jumpflood(radiance_sdf.memory, radiance_jfa.memory, Shd_JumpFlood, radiance_u_jumpflood_uRenderExtent, radiance_u_jumpflood_uJumpDistance, render_width, render_height);
	radiance_distancefield(radiance_jfa.memory, radiance_sdf.memory, Shd_DistanceField, radiance_u_distancefield_uRenderExtent, render_width, render_height);
	
	// Loop through all cascades in reverse and merge radiance down the cascades (one pass merge and interval).
	for(var n = radiance_cascades - 1; n >= 0; n--) {
		shader_set(radiance_u_cascades);
		shader_texture(radiance_u_cascades_RenderScene, radiance_world.memory);
		shader_texture(radiance_u_cascades_DistanceField, radiance_sdf.memory);
		shader_vec2(radiance_u_cascades_RenderExtent, render_width, render_height);
		shader_vec2(radiance_u_cascades_CascadeExtent, radiance_width, radiance_height);
		shader_float(radiance_u_cascades_CascadeCount, radiance_cascades);
		shader_float(radiance_u_cascades_CascadeIndex, cascade_index + n);
		shader_float(radiance_u_cascades_CascadeLinear, radiance_linear);
		shader_float(radiance_u_cascades_CascadeInterval, radiance_interval);
			// Render the current cascade...
			surface_set_target(radiance_current.memory);
			draw_clear_alpha(c_black, 0);
				// Pass in the previous cascade...
				draw_surface(radiance_previous.memory, 0, 0);
			surface_reset_target();
		shader_reset();
		
		// Set current cascade as previous after rendering to prep for next cascade...
		surface_set_target(radiance_previous.memory);
		draw_clear_alpha(c_black, 0);
			draw_surface(radiance_current.memory, 0, 0);
		surface_reset_target();
	}

gpu_set_blendenable(gpu_blend);
gpu_set_texrepeat(gpu_texrepeat);
gpu_set_tex_filter(gpu_filter);

gpu_set_blendmode(bm_add);
var xscale = render_width / radiance_width;
var yscale = render_height / radiance_height;
draw_surface_ext(surface_source(radiance_current), 0, 0, xscale, yscale, 0, c_white, 1.0);
draw_surface_ext(surface_source(radiance_current), 0, 0, xscale, yscale, 0, c_white, 1.0);
gpu_set_blendmode(bm_normal);

draw_set_color(c_yellow);
draw_text(5, 5, "Frame Time: " + string(delta_time / 1000) + " / " + string(1000 * (1.0/game_get_speed(gamespeed_fps))));
draw_set_color(c_white);