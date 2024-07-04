if (mouse_check_button(mb_left)) {
	x2 = mouse_x;
	y2 = mouse_y;
}

if (mouse_check_button(mb_right)) {
	x1 = mouse_x;
	y1 = mouse_y;
}

// Directional-Delta of Line (normalized): 
dx = (x2 - x1);
dy = (y2 - y1);

// Cross-section of square as relationship to slope of line:
var dir = max(abs(dx), abs(dy));
var hyp = (1.0 / dir) * cell_size;

// Multiply line directional delta by cross-section length:
dx *= hyp;
dy *= hyp;

// Step length of the line:
steps = dir / cell_size;