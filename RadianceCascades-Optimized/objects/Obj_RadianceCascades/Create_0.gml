/*
	Implementation assumes pre-averging--cannot be disabled.
	Due to pre-averaging, angular resolution for cascade0 is defaulted to 4-rays per-pixel. Instead decrease linear
	spacing-as explained below--to increase visual fidelity. With 4-ray-per-pixel and pre-averaging cascade0 always
	contains the final displayable output radiance.
*/

game_set_speed(60, gamespeed_fps);

// Should be pow2 sizes only (either whole or fractional: 0.25, 0.5, 1.0, 2.0, 4.0, 8.0, etc.).
// Increasing linear spacing will reduce quality, decreasing linear spacing will increase quality.
render_linear = 0.5;

// Should be equal to diagonal of the square of linear resolution.
// Set to a large distance for debugging (should see individually cascaded rays in scene).
render_interval = point_distance(0.0, 0.0, render_linear, render_linear) * 0.5;

render_width = 1250;
render_height = 900;

// PENDING IMPLEMENTATION:
// render_skybox = make_color_normalized_rgb(0.2, 0.5, 1.0);
// render_sunbox = make_color_normalized_rgb(1.0, 0.7, 0.1);

// Calculate the max cascade count based on the highest interval distance that would reach outside the screen.
// Valdiate intput and correct input settings.
// Divide the final cascade size by 2, since we're "pre-avergaing."
// Angular resolution is now set to a minimuim default 4-rays per probe (keeps cascade size consistent).
// Fidelity can be increased by decreasing spacing between probes instead of rays per probe.
radiance_cascades = ceil(logn(4, point_distance(0, 0, render_width, render_height)));
radiance_linear = power_ofN(render_linear, 2);
radiance_interval = multiple_ofN(render_interval, 2);

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// FIXES CASCADE RAY/PROBE TRADE-OFF ERROR RATE FOR NON-POW2 RESOLUTIONS: (very important).
error_rate = power(2.0, radiance_cascades - 1);
errorx = ceil(render_width / error_rate);
errory = ceil(render_height / error_rate);
render_width = errorx * error_rate;
render_height = errory * error_rate;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

radiance_width = floor(render_width / radiance_linear);
radiance_height = floor(render_height / radiance_linear);
cascade_index = 0;

show_debug_message("Render Extent: " + string(render_width) + " : " + string(render_height));
show_debug_message("Radiance Extent: " + string(radiance_width) + " : " + string(radiance_height));
show_debug_message("Radiance Cascades: " + string(radiance_cascades));

// Create a render list of surfaces that will be re-built everyframe.
radiance_renderlist = ds_list_create();
radiance_world = surface_build(render_width, render_height, surface_rgba8unorm, radiance_renderlist); // Intput game/world scene to process.
radiance_jfa = surface_build(render_width, render_height, surface_rgba8unorm, radiance_renderlist); // Intput game/world scene to process.
radiance_sdf = surface_build(render_width, render_height, surface_rgba8unorm, radiance_renderlist); // Intput game/world scene to process.
radiance_current = surface_build(radiance_width, radiance_height, surface_rgba16float, radiance_renderlist); // Fetch texture for current cascade.
radiance_previous = surface_build(radiance_width, radiance_height, surface_rgba16float, radiance_renderlist); // Fetch texture for previous cascade.

// Shader uniform inputs for Intervals and Merging combined into a single shader.
//radiance_u_cascades = Shd_RadianceCascades;
//radiance_u_cascades = Shd_RadianceCascades_FPFixed;
radiance_u_cascades = Shd_RadianceCascades_Final;
radiance_u_cascades_RenderScene = texture(radiance_u_cascades, "in_RenderScene");
radiance_u_cascades_DistanceField = texture(radiance_u_cascades, "in_DistanceField");
radiance_u_cascades_RenderExtent = uniform(radiance_u_cascades, "in_RenderExtent");
radiance_u_cascades_CascadeExtent = uniform(radiance_u_cascades, "in_CascadeExtent");
radiance_u_cascades_CascadeCount = uniform(radiance_u_cascades, "in_CascadeCount");
radiance_u_cascades_CascadeIndex = uniform(radiance_u_cascades, "in_CascadeIndex");
radiance_u_cascades_CascadeLinear = uniform(radiance_u_cascades, "in_CascadeLinear");
radiance_u_cascades_CascadeInterval = uniform(radiance_u_cascades, "in_CascadeInterval");

radiance_u_jumpflood = Shd_JumpFlood;
radiance_u_jumpflood_uRenderExtent = uniform(radiance_u_jumpflood, "in_RenderExtent");
radiance_u_jumpflood_uJumpDistance = uniform(radiance_u_jumpflood, "in_JumpDistance");

radiance_u_distancefield = Shd_DistanceField;
radiance_u_distancefield_uRenderExtent = uniform(radiance_u_distancefield, "in_RenderExtent");

/*
	Forced Optimizations:
	1. Pre-Averaging
		Merging happens top-down, e.g. we merge Cascade N into N-1.
		Since cascade N has 4x the number of rays per ray in cascade N-1,
		cascade N-1 must lookup the associated 4 rays per probe, average their
		results and then merge the results into the current ray.
		
		Instead we can cast 4 rays per texel, then average and store their
		results. That way during merging we only need to perform 1 texel lookup.
		This is called pre-merge averaging, which allows for a 75% memory reduction.
		
		Also pre-averaging causes inconcsistent cascade sizes if you start cascade0
		with 1 ray-per-probe which complicates the implementation. Instead angular
		resolution is fixed (4 rays per probe in cascade0) to maintain consistency.
		Instead you can adjust the linear resolution (up or down) to change visual
		fidelity. Linear Resolution (probe spacing) can be less than one (0.5 or 1/2,
		0.25 or 1/4, 0.125 or 1/8, etc.) so long as the number is a power of 2.
		
		NOTE: We're dividng the memory space by 4x, but we do so across two axis, so
		we actually divide each individual x/y-axis by 2x for a total 4x reduction.
	
	2. Direction First Storage
		Each cascade stores results for ray hits cast from each probe. These rays
		are grouped together by their probe position in memory. So one "block,"
		in memory represents on probe and each pixel in that block represents a ray.
		
		Instead we can store rays direction first, so that each "block," represents
		one ray direction and each pixel within that block represents a ray that is
		cast from a probe in that direction.
		
		This direction first approach allows us to utilize hardware interpolation
		between probes, since we interpolate between adjacent N+1 probes when merging.
		
		NOTE: That direction first + pre-averaging means that each ray actually
		represents 4 rays and each direction actually represents 4 directions.
		
		This combined result uses 75% less memory and 75% less merge samples and also
		benefits from texture cache localization and hardware interpolation.
*/