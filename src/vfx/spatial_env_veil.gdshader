// spatial_env_veil: the shadow veil, a curtain of black mist only a Shadowstep passes.
// Story 028, decision D-033. Author: Soul Vessels team (built with Claude Code).
//
// Near-black smoke rising through the curtain, densest at its centre line, with a violet rim
// where it thins. Reads as "solid but not stone" next to rock.
//
// Target: Godot 4.7 Mobile renderer (Forward Mobile), Android ARM64. Budget: 2 texture samples,
// no branches, unshaded, no depth write. One quad per curtain.
shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// Rise speed of the two smoke layers (UV units per second).
const float RISE_A = 0.09;
const float RISE_B = 0.15;
// How far in from each side the curtain reaches full density.
const float SIDE_FADE = 0.45;
// Density under which the violet rim shows.
const float RIM_BELOW = 0.55;

uniform sampler2D clouds : filter_linear_mipmap, repeat_enable;
uniform vec4 smoke : source_color = vec4(0.015, 0.01, 0.03, 1.0);
uniform vec4 rim : source_color = vec4(0.55, 0.3, 0.95, 1.0);
// Texture repeats up the curtain (so tall curtains keep the same smoke size).
uniform float repeats_v = 1.0;

void fragment() {
	vec2 uv = vec2(UV.x * 0.6, UV.y * repeats_v);
	float a = texture(clouds, uv + vec2(0.0, TIME * RISE_A)).a;
	float b = texture(clouds, uv * 1.9 + vec2(0.3, TIME * RISE_B)).a;
	float side = smoothstep(0.0, SIDE_FADE, UV.x) * smoothstep(0.0, SIDE_FADE, 1.0 - UV.x);
	float d = clamp(side * (0.75 + 0.5 * (a * 0.6 + b * 0.4)), 0.0, 1.0);
	float edge = (1.0 - smoothstep(0.0, RIM_BELOW, d)) * step(0.02, d);
	ALBEDO = mix(smoke.rgb, rim.rgb, edge * 0.8);
	ALPHA = d;
}
