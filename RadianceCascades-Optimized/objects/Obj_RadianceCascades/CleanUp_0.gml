for(var i = 0; i < ds_list_size(radiance_renderlist); i++)
	surface_delete(ds_list_find_value(radiance_renderlist, i));

ds_list_destroy(radiance_renderlist);