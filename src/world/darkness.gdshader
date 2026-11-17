// Story 043: the dark-room overlay. Black everywhere except soft circles ("holes") of light.
shader_type canvas_item;
uniform vec4 holes[8];
uniform int count = 0;
uniform float darkness = 0.94;
uniform vec2 screen = vec2(1280.0, 720.0);
void fragment() {
	vec2 p = SCREEN_UV * screen;
	float light = 0.0;
	for (int i = 0; i < 8; i++) {
		if (i >= count) { break; }
		float d = distance(p, holes[i].xy);
		float r = max(holes[i].z, 1.0);
		light = max(light, 1.0 - smoothstep(r * 0.55, r, d));
	}
	COLOR = vec4(0.0, 0.005, 0.015, darkness * (1.0 - light));
}
