if (!surface_exists(render_surface)) {
	render_surface = surface_create(cascade_size, cascade_size);
} else {
	if (surface_get_width(render_surface) != cascade_size) {
		surface_free(render_surface);
		render_surface = surface_create(cascade_size, cascade_size);
	}
}