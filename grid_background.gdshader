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

	float str_spd = 1.0;
	float str_int = 1.0;
	float str_con = 1.0;
	if (streak_level >= 2) { str_spd = 1.10; }
	if (streak_level >= 3) { str_spd = 1.25; }
	if (streak_level >= 4) { str_con = 1.05; str_spd = 1.35; }
	if (streak_level >= 5) { str_int = 1.25; str_spd = 1.50; }

	vec2 flow_uv = uv;
	if (wave_time > 0.0) {
		float t = wave_time / wave_duration;
		if (t < 1.0) {
			float dist = distance(uv, wave_center);
			float radius = t * 0.8;
			float ripple = sin((dist - radius) * 80.0 * (1.0 - t * 0.5)) * (1.0 - t) * 0.04 * wave_strength;
			vec2 dir = normalize(uv - wave_center);
			if (dist < 0.001) { dir = vec2(0.0); }
			flow_uv += dir * ripple * str_int;
		}
	}

	float flow = 0.0;

	{
		float a = 0.5;
		vec2 p;
		p.x = flow_uv.x * cos(a) - flow_uv.y * sin(a);
		p.y = flow_uv.x * sin(a) + flow_uv.y * cos(a);
		p *= 2.0;
		flow += sin(p.x * 1.8 + p.y * 0.6 + TIME * 0.35 * flow_speed * str_spd) * 0.40;
		flow += sin(p.x * 0.4 - p.y * 2.2 + TIME * 0.28 * flow_speed * str_spd) * 0.30;
	}

	{
		float a = 1.2;
		vec2 p;
		p.x = flow_uv.x * cos(a) - flow_uv.y * sin(a);
		p.y = flow_uv.x * sin(a) + flow_uv.y * cos(a);
		p *= 4.5;
		flow += sin(p.x * 2.5 + p.y * 1.8 + TIME * 0.45 * flow_speed * str_spd) * 0.20;
		flow += sin(p.x * 1.0 - p.y * 3.5 + TIME * 0.32 * flow_speed * str_spd) * 0.15;
	}

	{
		float a = -0.8;
		vec2 p;
		p.x = flow_uv.x * cos(a) - flow_uv.y * sin(a);
		p.y = flow_uv.x * sin(a) + flow_uv.y * cos(a);
		p *= 8.0;
		flow += sin(p.x * 3.2 + p.y * 2.0 + TIME * 0.55 * flow_speed * str_spd) * 0.10;
		flow += sin(p.x * 2.0 - p.y * 4.0 + TIME * 0.40 * flow_speed * str_spd) * 0.08;
	}

	flow = flow * 0.5 + 0.5;

	vec3 dark = vec3(0.020, 0.035, 0.045);
	vec3 mid = vec3(0.030, 0.060, 0.075);
	vec3 light = vec3(0.040, 0.090, 0.110);
	vec3 highlight = vec3(0.050, 0.150, 0.200);

	vec3 fluid_color = mix(dark, mid, smoothstep(0.3, 0.6, flow));
	fluid_color = mix(fluid_color, light, smoothstep(0.5, 0.8, flow));
	fluid_color = mix(fluid_color, highlight, smoothstep(0.7, 0.95, flow));

	float shimmer = sin(flow_uv.x * 10.0 + flow_uv.y * 7.0 + TIME * 0.5) * 0.5 + 0.5;
	fluid_color += vec3(0.015, 0.030, 0.040) * shimmer * flow * flow_strength * str_int;

	if (streak_level >= 4) {
		vec3 warm = vec3(0.3, 0.1, 0.0);
		float warm_mix = float(streak_level - 3) * 0.08;
		fluid_color = mix(fluid_color, fluid_color + warm * 0.5, warm_mix);
	}
	if (streak_level >= 5) {
		vec3 purple = vec3(0.15, 0.0, 0.25);
		fluid_color = mix(fluid_color, fluid_color + purple * 0.3, 0.15);
	}

	float breath = sin(TIME * breath_speed * str_spd * 1.2) * breath_amount * str_int;
	fluid_color += breath * 0.5;

	fluid_color = mix(fluid_color, fluid_color * str_con, 0.2);

	if (wave_time > 0.0) {
		float t = wave_time / wave_duration;
		if (t < 1.0) {
			float dist = distance(uv, wave_center);
			float radius = t * 0.8;
			float ring = (1.0 - t) * exp(-abs(dist - radius) * 25.0);
			ring *= wave_strength * str_int;
			fluid_color += vec3(0.08, 0.15, 0.20) * ring;
		}
	}

	COLOR = vec4(fluid_color, 1.0);
}
