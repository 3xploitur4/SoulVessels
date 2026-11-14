// spatial_env_mist: a band of ground mist drifting across a room.
// Story 028, decision D-033. Author: Soul Vessels team (built with Claude Code).
//
// One wide quad per layer with a tileable cloud texture scrolling sideways at two speeds. Alpha
// fades to nothing at the quad's top, bottom and ends, so the band has no visible edge.
//
// Target: Godot 4.7 Mobile renderer (Forward Mobile), Android ARM64. Budget: 2 texture samples,
// no branches, unshaded, no depth write. Used at most twice per room (two large blended quads).
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// Second cloud layer: scale and speed relative to the first, so the two never line up.
const float SECOND_SCALE = 1.7;
const float SECOND_SPEED = -0.6;
// Share of the height over which the band fades in at the bottom and out at the top.
const float FADE_V = 0.35;
// Share of the width over which it fades at each end.
const float FADE_U = 0.08;

group_uniforms look;
uniform sampler2D clouds : filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(0.6, 0.75, 0.9, 1.0);
uniform float density : hint_range(0.0, 1.0) = 0.35;

group_uniforms motion;
// Texture repeats along the band.
uniform float repeats = 3.0;
// UV units per second.
uniform float speed = 0.012;

void fragment() {
	vec2 uv = vec2(UV.x * repeats + TIME * speed, UV.y);
	float a = texture(clouds, uv).a;
	float b = texture(clouds, uv * SECOND_SCALE + vec2(TIME * speed * SECOND_SPEED, 0.37)).a;
	float fade_v = smoothstep(0.0, FADE_V, UV.y) * smoothstep(0.0, FADE_V, 1.0 - UV.y);
	float fade_u = smoothstep(0.0, FADE_U, UV.x) * smoothstep(0.0, FADE_U, 1.0 - UV.x);
	ALBEDO = tint.rgb;
	ALPHA = (a * 0.65 + b * 0.35) * density * fade_v * fade_u;
}
