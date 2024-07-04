draw_set_color(c_dkgray);

for(var xx = 0; xx < room_width; xx += cell_size;) {
	draw_line(xx, 0, xx, room_height);
}

for(var yy = 0; yy < room_height; yy += cell_size) {
	draw_line(0, yy, room_width, yy);
}

var cpx = x1, cpy = y1;
var px = x1;
var py = y1;

draw_set_color(c_blue);
draw_line(x1, y1, x2, y2);

for(var i = 0; i <= steps; i++) {
	////////////////////////////////////////////////////////////////////////////
	///////////////////////////// DRAWING CODE /////////////////////////////////
	var p_cpx = cpx- (cell_size * 0.5), p_cpy = cpy- (cell_size * 0.5);
	cpx = (floor(px / cell_size) * cell_size);
	cpy = (floor(py / cell_size) * cell_size);
	
	draw_set_color(c_red);
	draw_rectangle(cpx, cpy, cpx + cell_size, cpy + cell_size, false);
		
	if (p_cpx == cpx && p_cpy == cpy) {
		draw_set_color(c_green);
		draw_rectangle(cpx, cpy, cpx + cell_size, cpy + cell_size, false);
	}
	
	cpx += (cell_size * 0.5);
    cpy += (cell_size * 0.5);
	draw_set_color(c_lime);
	draw_circle(cpx, cpy, cell_size * 0.125, false);
	draw_set_color(c_aqua);
	draw_circle(px, py, cell_size * 0.125, false);
	////////////////////////////////////////////////////////////////////////////
	
	// Line iteration:
	px += dx;
	py += dy;
}

var dx1 = abs(dx), dy1 = abs(dy);
var amount = (dx1 < dy1)? dx1/dy1 : dy1/dx1;
draw_set_color(c_white);
draw_text(5, 5, "DELTA-X: " + string(dx1/dy1));
draw_text(5, 25, "DELTA-Y: " + string(dy1/dx1));
draw_text(5, 45, "DELTA-z: " + string(amount));