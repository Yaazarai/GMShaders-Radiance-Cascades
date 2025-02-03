/*
	Updates to "render_*" variables go here before radiance_* variables updates.
*/

radiance_cascades = ceil(logn(4, point_distance(0, 0, render_width, render_height)));
radiance_linear = power_ofN(render_linear, 2);
radiance_width = floor(render_width / radiance_linear);
radiance_height = floor(render_height / radiance_linear);

surface_update(radiance_world, render_width, render_height, -1);
surface_update(radiance_jfa, render_width, render_height, -1);
surface_update(radiance_sdf, render_width, render_height, -1);
surface_update(radiance_current, radiance_width, radiance_height, -1);
surface_update(radiance_previous, radiance_width, radiance_height, -1);

cascade_index += keyboard_check_pressed(vk_right) - keyboard_check_pressed(vk_left);
cascade_index = clamp(cascade_index, 0, radiance_cascades);

radiance_interval += (keyboard_check(vk_up) - keyboard_check(vk_down));
radiance_interval = clamp(radiance_interval, sqrt(2.0)*1.0, 128);