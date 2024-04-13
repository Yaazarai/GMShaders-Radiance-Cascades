surface_set_target(gameworld_worldscene);
draw_clear_alpha(c_black, 0);

draw_set_color($F0F066);
draw_circle(mouse_x, mouse_y, 8, false);
draw_set_color(c_white);

draw_sprite_ext(Spr_SampleScene, 0, 0, 0, 1, 1, 0, c_white, 1.0);
surface_reset_target();