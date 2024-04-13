function sampler(shd, id) { return shader_get_sampler_index(shd, id); }
function uniform(shd, id) { return shader_get_uniform(shd, id); }
function uniform_tx(id, surf) { texture_set_stage(id, surface_get_texture(surf)); }
function uniform_f1(id, f1) { shader_set_uniform_f(id, f1); }
function uniform_f2(id, f1, f2) { shader_set_uniform_f(id, f1, f2); }
function multiple_of2(number) { return ( ( number + ( 2 - 1 ) ) & ~( 2 - 1 ) ); }
function power_of4(number) { return power(4, ceil(logn(4, number))); }
function power_of2(number) { return power(2, ceil(logn(2, number))); }

function radiance_initialize(extent, angular = 4.0, interval = 4.0, spacing = 4.0, boost = 1.0, decayrate = 0.65) {
	global.radiance_render_extent    = extent;              // extent resolution.. output resolution will be SQUARE.
	global.radiance_render_decay     = decayrate;           // How quickly light bounces decay.
	global.radiance_render_boost     = boost;               // How much to boost light levels.
	global.radiance_cascade_angular  = power_of4(angular);  // angular resolution or initial rays per probe in cascade[0].
	global.radiance_cascade_interval = multiple_of2(interval); // radiance interval or raymarch distance of probes.
	global.radiance_cascade_spacing  = power_of2(spacing);  // Initial probe spacing of cascade0, each next cascade is N*4.0 spacing.
	global.radiance_cascade_extent   = floor(global.radiance_render_extent / global.radiance_cascade_spacing) * sqrt(global.radiance_cascade_angular);
	
	// Maximum cascade count.
	global.radiance_cascade_count    = ceil(logn(2, global.radiance_cascade_extent / sqrt(global.radiance_cascade_angular)));
	
	// Desired cascade count.
	var diagonal = point_distance(0,0,extent,extent);
	global.radiance_cascade_count    = min(floor(logn(4, 4.0 * diagonal))-1, global.radiance_cascade_count);
	
	// Find Cascade count by maximum radiance interval.
	// for(var i = 0; i < global.radiance_cascade_count; i++) {
	// 	var max_interval = global.radiance_cascade_interval * power(4, i);
	// 	if (max_interval > global.radiance_render_extent) {
	// 		global.radiance_cascade_count = i;
	// 		break;
	// 	}
	// }
}

function radiance_defaultshaders(jfaseed, jumpflood, distfield, shd_intervals, shd_merging, shd_mipmap) {
	global.radiance_jfaseeding = jfaseed;
	global.radiance_jumpfloodalgorithm = jumpflood;
	global.radiance_distancefield = distfield;
	global.radiance_intervals = shd_intervals;
	global.radiance_merging = shd_merging;
	global.radiance_mipmap = shd_mipmap;
	
	global.radiance_jumpfloodalgorithm_uRenderExtent = uniform(global.radiance_jumpfloodalgorithm, "in_RenderExtent");
	global.radiance_jumpfloodalgorithm_uJumpDistance = uniform(global.radiance_jumpfloodalgorithm, "in_JumpDistance");
	
	global.radiance_intervals_uRenderExtent = uniform(global.radiance_intervals, "in_RenderExtent");
	global.radiance_intervals_uRenderDecayRate = uniform(global.radiance_intervals, "in_RenderDecayRate");
	global.radiance_intervals_uDistanceField = sampler(global.radiance_intervals, "in_DistanceField");
	global.radiance_intervals_uWorldScene = sampler(global.radiance_intervals, "in_WorldScene");
	global.radiance_intervals_uCascadeExtent = uniform(global.radiance_intervals, "in_CascadeExtent");
	global.radiance_intervals_uCascadeSpacing = uniform(global.radiance_intervals, "in_CascadeSpacing");
	global.radiance_intervals_uCascadeInterval = uniform(global.radiance_intervals, "in_CascadeInterval");
	global.radiance_intervals_uCascadeAngular = uniform(global.radiance_intervals, "in_CascadeAngular");
	global.radiance_intervals_uCascadeIndex = uniform(global.radiance_intervals, "in_CascadeIndex");
	
	global.radiance_merging_uCascadeExtent = uniform(global.radiance_merging, "in_CascadeExtent");
	global.radiance_merging_uCascadeAngular = uniform(global.radiance_merging, "in_CascadeAngular");
	global.radiance_merging_uCascadeCount = uniform(global.radiance_merging, "in_CascadeCount");
	global.radiance_merging_uCascadeIndex = uniform(global.radiance_merging, "in_CascadeIndex");
	global.radiance_merging_uCascadeUpper = sampler(global.radiance_merging, "in_CascadeAtlas");
	
	global.radiance_mipmap_uMipMapExtent = uniform(global.radiance_mipmap, "in_MipMapExtent");
	global.radiance_mipmap_uCascadeExtent = uniform(global.radiance_mipmap, "in_CascadeExtent");
	global.radiance_mipmap_uCascadeAngular = uniform(global.radiance_mipmap, "in_CascadeAngular");
	global.radiance_mipmap_uCascadeIndex = uniform(global.radiance_mipmap, "in_CascadeIndex");
	global.radiance_mipmap_uCascadeAtlas = sampler(global.radiance_mipmap, "in_CascadeAtlas");
}

function radiance_clear(surface) {
    surface_set_target(surface);
    draw_clear_alpha(c_black, 0);
    surface_reset_target();
}

function radiance_jfaseed(init, jfaA, jfaB) {
    surface_set_target(jfaB);
    draw_clear_alpha(c_black, 0);
    shader_set(global.radiance_jfaseeding);
    draw_surface(init,0,0);
    shader_reset();
    surface_reset_target();
    
    surface_set_target(jfaA);
    draw_clear_alpha(c_black, 0);
    surface_reset_target();
}

function radiance_jumpflood(source, destination) {
    var passes = ceil(log2(max(global.radiance_render_extent, global.radiance_render_extent)));
    
    shader_set(global.radiance_jumpfloodalgorithm);
    shader_set_uniform_f(global.radiance_jumpfloodalgorithm_uRenderExtent, global.radiance_render_extent, global.radiance_render_extent);
	
	var tempA = source, tempB = destination, tempC = source;
    var i = 0; repeat(passes) {
        var offset = power(2, passes - i - 1);
        shader_set_uniform_f(global.radiance_jumpfloodalgorithm_uJumpDistance, offset);
        surface_set_target(tempA);
			draw_surface(tempB,0,0);
        surface_reset_target();
		
		tempC = tempA;
		tempA = tempB;
		tempB = tempC;
        i++;
    }
    
    shader_reset();
	if (destination != tempC) {
		surface_set_target(destination);
			draw_surface(tempC,0,0);
        surface_reset_target();
	}
}

function radiance_distancefield(jfa, surface) {
    surface_set_target(surface);
    draw_clear_alpha(c_black, 0);
    shader_set(global.radiance_distancefield);
    draw_surface(jfa, 0, 0);
    shader_reset();
    surface_reset_target();
}

function radiancecascades_intervals(worldscene, distfield, cascade_surfarray, storage) {
	if (is_array(cascade_surfarray)) {
		for(var n = 0; n < global.radiance_cascade_count; n++) {
			shader_set(global.radiance_intervals);
			uniform_f1(global.radiance_intervals_uRenderExtent, global.radiance_render_extent);
			uniform_f1(global.radiance_intervals_uRenderDecayRate, global.radiance_render_decay);
			uniform_tx(global.radiance_intervals_uDistanceField, distfield);
			uniform_tx(global.radiance_intervals_uWorldScene, worldscene);
			
			uniform_f1(global.radiance_intervals_uCascadeExtent, global.radiance_cascade_extent);
			uniform_f1(global.radiance_intervals_uCascadeSpacing, global.radiance_cascade_spacing);
			uniform_f1(global.radiance_intervals_uCascadeInterval, global.radiance_cascade_interval);
			uniform_f1(global.radiance_intervals_uCascadeAngular, global.radiance_cascade_angular);
			uniform_f1(global.radiance_intervals_uCascadeIndex, n);
			
				surface_set_target(cascade_surfarray[n]);
				draw_clear_alpha(c_black, 0);
				// It doesn't matter what we render here, we just need a render source to set the render area size.
				draw_surface(storage, 0, 0);
				surface_reset_target();
			
			shader_reset();
		}
	}
}

function radiancecascades_merging(cascade_surfarray, cascade_temporary) {
	if (is_array(cascade_surfarray)) {
		for(var n = global.radiance_cascade_count - 1; n >= 0; n--) {
			shader_set(global.radiance_merging);
			uniform_f1(global.radiance_merging_uCascadeExtent, global.radiance_cascade_extent);
			uniform_f1(global.radiance_merging_uCascadeAngular, global.radiance_cascade_angular);
			uniform_f1(global.radiance_merging_uCascadeCount, global.radiance_cascade_count);
			uniform_f1(global.radiance_merging_uCascadeIndex, n);
			
			var cascaden1 = (n + 1) % global.radiance_cascade_count;
			uniform_tx(global.radiance_merging_uCascadeUpper, cascade_surfarray[cascaden1]);
			
			surface_set_target(cascade_temporary);
			draw_clear_alpha(c_black, 0);
			
			// In this pass we're reading from cascade N+1 to merge cascade N with cascade N+1.
			draw_surface(cascade_surfarray[n], 0, 0);
			surface_reset_target();
			shader_reset();
			
			// Copy from the tmeporary cascade surface to cascade N.
			surface_set_target(cascade_surfarray[n]);
			draw_clear_alpha(c_black, 0);
			draw_surface(cascade_temporary, 0, 0);
			surface_reset_target();
		}
	}
}

function radiancecascades_mipmap(cascade_surfarray, mipmaps_surfarray) {
	if (is_array(mipmaps_surfarray)) {
		var mipmap_width = surface_get_width(mipmaps_surfarray[global.showcascade]);
		var mipmap_height = surface_get_width(mipmaps_surfarray[global.showcascade]);
		var mipmap0_width = surface_get_width(mipmaps_surfarray[0]);
		var mipmap0_height = surface_get_width(mipmaps_surfarray[0]);
	
		shader_set(global.radiance_mipmap);
		uniform_f1(global.radiance_mipmap_uMipMapExtent, max(mipmap_width, mipmap_height));
		uniform_f1(global.radiance_mipmap_uCascadeExtent, global.radiance_cascade_extent);
		uniform_f1(global.radiance_mipmap_uCascadeAngular, global.radiance_cascade_angular);
		uniform_f1(global.radiance_mipmap_uCascadeIndex, global.showcascade);
		uniform_tx(global.radiance_mipmap_uCascadeAtlas, cascade_surfarray[global.showcascade]);
	
			surface_set_target(mipmaps_surfarray[global.showcascade]);
			draw_clear_alpha(c_black, 0);
			draw_surface_ext(mipmaps_surfarray[0], 0, 0, mipmap_width/mipmap0_width, mipmap_height/mipmap0_height, 0, c_black,1);
			surface_reset_target();
	
		shader_reset();
	}
}