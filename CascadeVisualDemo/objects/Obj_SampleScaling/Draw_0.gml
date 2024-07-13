

for(var j = 0; j < 3; j++) {
	switch(j) {
		case 0: draw_set_color(c_red); break;
		case 1: draw_set_color(c_lime); break;
		case 2: draw_set_color(c_aqua); break;
	}
	
	show_debug_message(string(j) + " : " + string(sectors * power(4, j)));
	for(var i = 0; i < sectors * power(4, j); i++) {
		//var sector_width = floor(width / (sectorsA * power(j, 2)));
		var sector_width = width / (sectors * power(4, j));
		
		draw_rectangle(
			offset + (sector_width * i),
			offset + (j * height) + 8,
			offset + (sector_width * i) + sector_width,
		offset + (j * height) + height, true);
	}
}