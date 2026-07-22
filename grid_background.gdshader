shader_type canvas_item;

uniform float breath_speed = 1.0;
uniform float breath_amount = 0.06;
uniform float flow_speed = 1.0;
uniform float flow_strength = 0.12;
uniform int streak_level = 0;
uniform vec2 wave_center = vec2(0.5);
uniform float wave_time = 0.0;
uniform float wave_duration = 0.6;
uniform float wave_strength = 0.3;

void fragment() {
	vec2 uv = UV;
	vec3 color = COLOR.rgb;

	float str_spd = 1.0;
	float str_int = 1.0;
	float str_con = 1.0;
	if (streak_level >= 2) { str_spd = 1.10; }
	if (streak_level >= 3) { str_spd = 1.25; }
	if (streak_level >= 4) { str_con = 1.05; str_spd = 1.30; }
	if (streak_level >= 5) { str_int = 1.20; str_spd = 1.40; }

	float breath = sin(TIME * breath_speed * str_spd * 1.5) * breath_amount * str_int;
	color += breath;

	float flow = 0.0;
	flow += sin(uv.x * 3.0 + uv.y * 1.5 + TIME * 0.30 * flow_speed * str_spd) * 0.5;
	flow += sin(uv.x * 1.2 - uv.y * 2.8 + TIME * 0.20 * flow_speed * str_spd) * 0.3;
	flow += sin((uv.x + uv.y) * 2.0 + TIME * 0.15 * flow_speed * str_spd) * 0.2;
	flow *= 0.5;
	color += vec3(0.024, 0.012, 0.006) * flow * flow_strength * str_int;

	if (wave_time > 0.0) {
		float t = wave_time / wave_duration;
		if (t < 1.0) {
			float radius = t * 1.2;
			float dist = distance(uv, wave_center);
			float ring = (1.0 - t) * exp(-abs(dist - radius) * 20.0);
			ring *= wave_strength * str_int;
			color += vec3(0.10, 0.05, 0.02) * ring;
		}
	}

	color = mix(color, color * str_con, 0.3);

	COLOR = vec4(color, 1.0);
}
