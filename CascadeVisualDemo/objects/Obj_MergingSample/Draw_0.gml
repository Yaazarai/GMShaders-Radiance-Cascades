draw_set_color(c_yellow);

draw_circle(offsetN1X, offsetN1Y, radiusN * 2, true);
draw_circle(offsetN1X + box_sizeN1, offsetN1Y, radiusN * 2, true);
draw_circle(offsetN1X, offsetN1Y + box_sizeN1, radiusN * 2, true);
draw_circle(offsetN1X + box_sizeN1, offsetN1Y + box_sizeN1, radiusN * 2, true);

shader_set(Shd_Bilinear);
shader_set_uniform_f(shader_get_uniform(Shd_Bilinear, "colorTL"), 1, 0, 1, 1);
shader_set_uniform_f(shader_get_uniform(Shd_Bilinear, "colorTR"), 0, 1, 0, 1);
shader_set_uniform_f(shader_get_uniform(Shd_Bilinear, "colorBL"), 0, 0, 1, 1);
shader_set_uniform_f(shader_get_uniform(Shd_Bilinear, "colorBR"), 1, 1, 1, 1);
var xscale = box_sizeN1 / sprite_get_width(Spr_SampleSprite);
var yscale = box_sizeN1 / sprite_get_height(Spr_SampleSprite);
draw_sprite_ext(Spr_SampleSprite, 0, offsetN1X, offsetN1Y, xscale, yscale, 0, c_white, 1);
shader_reset();

for(var i = 0; i < 4; i++) {
	for(var j = 0; j < 4; j++) {
		draw_set_color(c_red);
		draw_circle(offsetNX + box_sizeN + (box_sizeN * i), offsetNY + (box_sizeN * j), radiusN, true);
		
		if (i == 2 && j == 1) {
			draw_set_color(c_black);
			draw_circle(offsetNX + box_sizeN + (box_sizeN * i), offsetNY + (box_sizeN * j), radiusN+1, false);
			draw_set_color(colorMR);
			draw_circle(offsetNX + box_sizeN + (box_sizeN * i), offsetNY + (box_sizeN * j), radiusN-1, false);
		}
	}
}

var dNx1, dNy1, dNx2, dNy2, dNt, posNx, posNx;
dNt = (0.5 / angularN) * 2.0 * pi;
dNx1 = lengthdir_x(radiusN, radtodeg(dNt));
dNy1 = lengthdir_y(radiusN, radtodeg(dNt));
dNx2 = lengthdir_x(radiusN + intervalN, radtodeg(dNt));
dNy2 = lengthdir_y(radiusN + intervalN, radtodeg(dNt));
posNx = offsetNX + box_sizeN + (box_sizeN * 2);
posNy = offsetNY + (box_sizeN * 1);

draw_set_color(c_black);
draw_line_width(
	posNx + dNx1,
	posNy + dNy1,
	posNx + dNx2,
	posNy + dNy2, 8);
draw_set_color(colorMR);
draw_line_width(
	posNx + dNx1,
	posNy + dNy1,
	posNx + dNx2,
	posNy + dNy2, 6);

for(var i = 0; i < 2; i++) {
	for(var j = 0; j < 2; j++) {
		var posx = offsetN1X + (box_sizeN1 * i);
		var posy = offsetN1Y + (box_sizeN1 * j);
		
		for(var r = 0; r < angularN1; r++) {
			var dx1, dy1, dx2, dy2, dt;
			dt = ((r + 0.5) / angularN1) * 2.0 * pi;
			dx1 = lengthdir_x((radiusN * 2), radtodeg(dt));
			dy1 = lengthdir_y((radiusN * 2), radtodeg(dt));
			dx2 = lengthdir_x((radiusN * 2) + intervalN1, radtodeg(dt));
			dy2 = lengthdir_y((radiusN * 2) + intervalN1, radtodeg(dt));
			
			switch((i * 2) + j) {
				case 0: draw_set_color(colorTL); break;
				case 1: draw_set_color(colorBL); break;
				case 2: draw_set_color(colorTR); break;
				case 3: draw_set_color(colorBR); break;
			}
			
			draw_line_width(
				posx + dx1,
				posy + dy1,
				posx + dx2,
				posy + dy2, 6);
			
			if (r == 3) break;
		}
	}
}