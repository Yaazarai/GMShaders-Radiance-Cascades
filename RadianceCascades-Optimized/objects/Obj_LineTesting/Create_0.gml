cell_size = 12;
sqrt_size = cell_size * sqrt(2);
diag_size = cell_size * sqrt(2);
step_size = 1;
steps = 0;

x1 = room_width / 2;
y1 = room_height / 2;
x2 = room_width / 2;
y2 = room_height / 2;

//x1 = floor(x1 / cell_size) * cell_size;
//y1 = floor(y1 / cell_size) * cell_size;
x1 = cell_size * 0.5;
y1 = cell_size * 0.5;

dx = (x2 - x1);
dy = (y2 - y1);