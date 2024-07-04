#macro INVALID_SURFACE -1

// Easy surface usage.
function surface(w, h, f) constructor { width = w; height = h; format = f; memory = INVALID_SURFACE; }
function surface_build(w, h, f, l) { var surf = new surface(w, h, f); ds_list_add(l, surf); return surf; }
function surface_rebuild(surf) { if (!surface_exists(surf.memory)) surf.memory = surface_create(surf.width, surf.height, surf.format); }
function surface_delete(surf) { if (surface_exists(surf.memory)) surface_free(surf.memory); delete surf; }
function surface_source(surf) { return surf.memory; }
function surface_update(surf, w, h, f) { surf.width = (w > 0)? w: surf.width; surf.height = (h > 0)? h : surf.height; surf.format = (f > 0)? f : surf.format; }
function surface_clear(surf) { surface_set_target(surf.memory); draw_clear_alpha(c_black, 0); surface_reset_target(); }

// Shader Functions
function texture(shd, uid) { return shader_get_sampler_index(shd, uid); }
function uniform(shd, uid) { return shader_get_uniform(shd, uid); }
function shader_texture(uid, surf) { texture_set_stage(uid, surface_get_texture(surf)); }
function shader_float(uid, f1) { shader_set_uniform_f(uid, f1); }
function shader_vec2(uid, f1, f2) { shader_set_uniform_f(uid, f1, f2); }

// Math Functions
function power_ofN(number, n) { return power(n, ceil(logn(n, number))); }
function multiple_ofN(number, n) { return (n == 0) ? number : ceil(number / n) * n; }
function geometric_ofN(number, n, p) { return (number * (1.0 - power(p, n))) / (1.0 - p); }

// Draw Functions
function draw_sprite_scalable(spr, xx, yy, w, h) { return draw_sprite_ext(spr, 0, xx, yy, w/sprite_get_width(spr), h/sprite_get_height(spr), 0, c_white, 1); }

// Color Functions
function make_color_normalized_rgb(red, green, blue) { return make_color_rgb(red * 255.0, green * 255.0, blue * 255.0); }

// Shader Specific Functions
function radiance_jfaseed(init, jfa, dist, shader) {
    surface_set_target(jfa);
    draw_clear_alpha(c_black, 0);
    shader_set(shader);
    draw_surface(init,0,0);
    shader_reset();
    surface_reset_target();
    
    surface_set_target(dist);
    draw_clear_alpha(c_black, 0);
    surface_reset_target();
}

function radiance_jumpflood(source, destination, shader, uniform_extent, uniform_jumpdist, width, height) {
    var passes = ceil(log2(max(width, height)));
    
    shader_set(shader);
    shader_set_uniform_f(uniform_extent, width, height);
	
	var tempA = source, tempB = destination, tempC = source;
    var i = 0; repeat(passes) {
        var offset = power(2, passes - i - 1);
        shader_set_uniform_f(uniform_jumpdist, offset);
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

function radiance_distancefield(jfa, dist, shader, uniform_extent, width, height) {
    surface_set_target(dist);
    draw_clear_alpha(c_black, 0);
    shader_set(shader);
	shader_set_uniform_f(uniform_extent, width, height);
    draw_surface(jfa, 0, 0);
    shader_reset();
    surface_reset_target();
}