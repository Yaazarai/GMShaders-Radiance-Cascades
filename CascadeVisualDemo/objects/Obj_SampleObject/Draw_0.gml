gpu_set_blendenable(false);
shader_set(Shd_CascadeVisual);
shader_set_uniform_f(shader_get_uniform(Shd_CascadeVisual, "in_CascadeSize"), cascade_size);
shader_set_uniform_f(shader_get_uniform(Shd_CascadeVisual, "in_CascadeIndex"), cascadeIndex);
shader_set_uniform_f(shader_get_uniform(Shd_CascadeVisual, "in_CascadeAngular"), angular);

surface_set_target(render_surface);
var sprw = sprite_get_width(Spr_SampleSprite);
var sprh = sprite_get_height(Spr_SampleSprite);
draw_sprite_ext(Spr_SampleSprite, 0, 0, 0, cascade_size/sprw, cascade_size/sprh, 0, c_white, 1);
surface_reset_target();
shader_reset();
gpu_set_blendenable(true);
gpu_set_tex_filter(false);
draw_surface_ext(render_surface, cascade_offsetx, cascade_offsety, render_size/cascade_size, render_size/cascade_size, 0, c_white, 1);
gpu_set_tex_filter(true);

draw_set_color(c_white);
draw_set_font(Fnt_Sample);
draw_set_halign(fa_left);
draw_text(cascade_offsetx, cascade_offsety - 32, "Cascade Memory:");
draw_text(cascade_offsetx2, cascade_offsety2 - 32, "Screen Probe/Ray Spacing:");
draw_set_halign(fa_center);
draw_text(cascade_offsetx + render_size, cascade_offsety + render_size + 16,
	"Controls: [Up]/[Down] Probe Spacing; [Left]/[Right] Cascade Index");
draw_text(cascade_offsetx + render_size, cascade_offsety + render_size + 40,
	"[Space] to switch to Direction-First Probe Layout");

draw_set_color(c_red);
draw_rectangle(cascade_offsetx2, cascade_offsety2, cascade_offsetx2 + render_size - 1, cascade_offsety2 + render_size - 1, true);

for(var xx = 0; xx < probeCount; xx++) {
	for(var yy = 0; yy < probeCount; yy++) {
		var pspacing = probeSpacing * (render_size / cascade_size);
		draw_circle(cascade_offsetx2 + (pspacing * 0.5) + (pspacing * xx), cascade_offsety2 + (pspacing * 0.5) + (pspacing * yy), 2, false);
	}
}

draw_set_color(c_blue);

draw_rectangle(cascade_offsetx2 + current_probex,
				cascade_offsety2 + current_probey,
				cascade_offsetx2 + current_probex + current_probesize - 1,
				cascade_offsety2 + current_probey + current_probesize - 1, true);

draw_set_color(c_aqua);

for(var r = 0; r < current_angular; r++) {
	var dx1, dy1, dx2, dy2, dt, intrs, intr;
	intrs = current_intervalstart * (render_size / cascade_size);
	intr = current_interval * (render_size / cascade_size);
	dt = ((r + 0.5) / current_angular) * 2.0 * pi;
	dx1 = lengthdir_x(intrs, radtodeg(dt));
	dy1 = lengthdir_y(intrs, radtodeg(dt));
	dx2 = lengthdir_x(intrs + intr, radtodeg(dt));
	dy2 = lengthdir_y(intrs + intr, radtodeg(dt));
	draw_line(
		cascade_offsetx2 + current_probex + (current_probesize * 0.5) + dx1,
		cascade_offsety2 + current_probey + (current_probesize * 0.5) + dy1,
		cascade_offsetx2 + current_probex + (current_probesize * 0.5) + dx2,
		cascade_offsety2 + current_probey + (current_probesize * 0.5) + dy2);
}

draw_set_color(c_fuchsia);

var mrindex = floor((point_direction(
	cascade_offsetx2 + current_probex + (current_probesize * 0.5),
	cascade_offsety2 + current_probey + (current_probesize * 0.5),
	mouse_x, mouse_y) / 360.0) * current_angular);
var dx, dy, dr;
var croffset = (render_size / cascade_size) * 0.5;
dr = ((mrindex + 0.5) / current_angular) * 2.0 * pi;
dx = lengthdir_x(intrs + intr, radtodeg(dr));
dy = lengthdir_y(intrs + intr, radtodeg(dr));
draw_circle(cascade_offsetx2 + current_probex + (current_probesize * 0.5) + dx,
	cascade_offsety2 + current_probey + (current_probesize * 0.5) + dy, croffset, false);

var rayx = mrindex mod sqrt(current_angular) * (render_size / cascade_size);
var rayy = floor(mrindex / sqrt(current_angular)) * (render_size / cascade_size);
draw_circle(cascade_offsetx + current_probex + croffset + rayx,
	cascade_offsety + current_probey + croffset + rayy, croffset, false);

draw_set_color(c_white);