shader_type canvas_item;

uniform int streak_level = 0;
uniform vec2 wave_center = vec2(0.5);
uniform float wave_time = 0.0;
uniform float wave_flash = 0.0;
uniform float wave_duration = 0.6;

void fragment() {
	vec2 uv = UV;

	vec2 cell_uv = uv * vec2(30.0, 18.0);
	vec2 cell_id = floor(cell_uv);
	vec2 cell = fract(cell_uv) - 0.5;

	float radius = 0.22;
	float wave_glow = 0.0;
	float deform = 0.0;

	if (wave_time > 0.0) {
		float t = wave_time / wave_duration;
		if (t < 1.0) {
			vec2 tile_uv = uv * vec2(30.0, 18.0);
			vec2 tile_center = wave_center * vec2(30.0, 18.0);
			float tile_dist = max(abs(tile_uv.x - tile_center.x), abs(tile_uv.y - tile_center.y));
			float speed = 0.3 + float(streak_level) * 0.1;
			float max_dist = 48.0;
			float d_radius = t * max_dist * speed;
			float thickness = 0.5 + float(streak_level) * 0.3;

			float ring = step(d_radius - thickness, tile_dist) - step(d_radius, tile_dist);

			if (streak_level >= 3) {
				float t2 = (wave_time - 0.15) / wave_duration;
				if (t2 > 0.0 && t2 < 1.0) {
					float r2 = t2 * max_dist * speed;
					float ring2 = step(r2 - thickness * 0.7, tile_dist) - step(r2, tile_dist);
					ring = max(ring, ring2);
				}
			}

			wave_glow = ring * (1.0 - t);
			deform = ring * (1.0 - t) * 0.4;
			if (streak_level >= 4) deform += 0.12 * ring;
		}
	}

	radius += deform;

	float dot = 1.0 - smoothstep(radius - 0.02, radius, max(abs(cell.x), abs(cell.y)));

	vec3 bg = vec3(0.05);
	vec3 color = vec3(0.25);

	float brightness = (0.12 + float(streak_level) * 0.1) * wave_glow;
	color += vec3(brightness);
	bg += vec3(brightness * 0.08);

	vec3 final_color = bg + dot * color;

	if (wave_flash > 0.0) {
		float flash = (wave_flash / 0.15) * 0.5;
		final_color += vec3(flash);
	}

	COLOR = vec4(final_color, 1.0);
}