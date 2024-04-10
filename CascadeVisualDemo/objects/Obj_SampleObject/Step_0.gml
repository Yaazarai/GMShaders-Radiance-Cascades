cascadeIndex += keyboard_check_pressed(vk_right) - keyboard_check_pressed(vk_left);
cascadeIndex = clamp(cascadeIndex, 0, cascadeCount);
current_spacingindex += keyboard_check_pressed(vk_down) - keyboard_check_pressed(vk_up);
current_spacingindex = clamp(current_spacingindex, 0, logn(2, size) - 1);

current_spacing = spacing * power(2.0, current_spacingindex);
cascade_size = floor(size / current_spacing) * sqrt(angular);
cascadeCount = floor(logn(2, cascade_size / sqrt(angular))) - 1;

current_angular = angular * power(4.0, cascadeIndex);
probeCount = floor(cascade_size / sqrt(current_angular));
probeSpacing = cascade_size / probeCount;

current_probesize = sqrt(current_angular) * (render_size / cascade_size);

if (mouse_check_button(mb_left)) {
	current_probex = floor((mouse_x - cascade_offsetx2) / current_probesize) * current_probesize;
	current_probey = floor((mouse_y - cascade_offsety2) / current_probesize) * current_probesize;
}

current_probex = floor(current_probex / current_probesize) * current_probesize;
current_probey = floor(current_probey / current_probesize) * current_probesize;
current_probex = clamp(current_probex, 0, render_size-current_probesize);
current_probey = clamp(current_probey, 0, render_size-current_probesize);

current_intervalstart = (interval * (1.0 - power(4.0, cascadeIndex))) / (1.0 - 4.0);
current_interval = interval * power(4.0, cascadeIndex);