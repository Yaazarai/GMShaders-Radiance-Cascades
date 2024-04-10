// User Settings:
size = 32;
angular = 4;
spacing = 1;
interval = 1;
cascadeIndex = 0;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
function power_of2(number) { return power(2, ceil(logn(2, number))); }
function power_of4(number) { return power(4, ceil(logn(4, number))); }

angular = power_of4(angular);
cascade_size = floor(size / spacing) * sqrt(angular);
render_size = 512;

cascadeCount = floor(logn(2, cascade_size / sqrt(angular))) - 1;
probeCount = floor(cascade_size / sqrt(angular));
probeSpacing = cascade_size / probeCount;

cascade_offsetx = 128 + 80;
cascade_offsety = 128;
cascade_offsetx2 = 128 + 80 + render_size;
cascade_offsety2 = 128;

current_spacingindex = 0;
current_spacing = spacing = max(2, power_of2(spacing));
current_angular = angular;
current_probex = 0;
current_probey = 0;
current_probesize = 0;
current_interval = (interval * (1.0 - power(4.0, cascadeIndex))) / (1.0 - 4.0);
current_intervalstart = interval * power(4.0, cascadeIndex);

render_surface = -1;
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////