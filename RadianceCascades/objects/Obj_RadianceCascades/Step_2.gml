global.showcascade += keyboard_check_pressed(vk_down) - keyboard_check_pressed(vk_up);
global.showcascade = clamp(global.showcascade, 0, global.radiance_cascade_count - 1);

global.radiance_cascade_interval += (keyboard_check_pressed(vk_right) - keyboard_check_pressed(vk_left)) * 16.0;
global.radiance_cascade_interval = clamp(global.radiance_cascade_interval, 4, 256);