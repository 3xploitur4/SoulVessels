// Story 031: the moving shimmer on a water surface (src/world/water.gd).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform vec4 tint : source_color = vec4(0.45, 0.78, 0.9, 0.55);
void fragment() {
	vec2 uv = UV * vec2(18.0, 3.0);
	float a = sin(uv.x * 1.7 + TIME * 1.3) * 0.5 + 0.5;
	float b = sin(uv.x * 3.1 - TIME * 2.1 + uv.y * 2.0) * 0.5 + 0.5;
	float glint = smoothstep(0.82, 1.0, a * b);
	ALBEDO = tint.rgb + vec3(glint * 0.6);
	ALPHA = tint.a + glint * 0.35;
}
