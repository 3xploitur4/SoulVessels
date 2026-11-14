// spatial_env_shaft: a shaft of pale light falling through the cavern dust.
// Story 028, decision D-033. Author: Soul Vessels team (built with Claude Code).
//
// A tall slanted quad, additive, brightest at the top and soft at its sides, with a slow
// shimmer. No texture.
//
// Target: Godot 4.7 Mobile renderer (Forward Mobile), Android ARM64. Budget: 0 texture samples,
// no branches, unshaded additive, no depth write. Two or three small quads per room.
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

// Shimmer speed (rad/s) and depth (share of brightness).
const float SHIMMER_SPEED = 0.7;
const float SHIMMER_DEPTH = 0.18;
// How fast the shaft dies toward the floor (higher = shorter).
const float FALLOFF = 1.6;

uniform vec4 tint : source_color = vec4(0.6, 0.78, 1.0, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.16;
// Offsets the shimmer so neighbouring shafts do not pulse together.
uniform float phase = 0.0;

void fragment() {
	float side = smoothstep(0.0, 0.5, UV.x) * smoothstep(0.0, 0.5, 1.0 - UV.x);
	float down = pow(1.0 - UV.y, FALLOFF);
	float shimmer = 1.0 - SHIMMER_DEPTH * (0.5 + 0.5 * sin(TIME * SHIMMER_SPEED + phase));
	ALBEDO = tint.rgb * strength * side * down * shimmer;
}
