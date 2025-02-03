surface_set_target(radiance_world.memory);
draw_clear_alpha(c_black, 0);
draw_sprite(Spr_SampleScene, 0, 0, 0);
draw_set_color($00000000);
draw_circle(mouse_x, mouse_y, 128, false);
draw_set_color(c_white);
surface_reset_target();