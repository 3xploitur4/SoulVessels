// canvas_post_vignette: darkened corners and a faint cool grade over the whole view.
// Story 028, decision D-033. Author: Soul Vessels team (built with Claude Code).
//
// Drawn on a full-screen ColorRect under the HUD. It only darkens (alpha blend of a dark tint),
// so it never needs the screen texture: no extra pass, safe on the Mobile renderer.
//
// Target: Godot 4.7 Mobile renderer, Android ARM64. Budget: 0 texture samples, no branches.
shader_type canvas_item;

// Where the darkening starts and where it is strongest, as distance from the centre
// (0 = centre, about 0.7 = corner).
const float INNER = 0.32;
const float OUTER = 0.78;

uniform vec4 tint : source_color = vec4(0.01, 0.02, 0.05, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.62;

void fragment() {
	vec2 d = UV - vec2(0.5);
	// Wider than tall, like the screen: corners darken more than top and bottom edges.
	float r = length(d * vec2(1.0, 0.82));
	COLOR = vec4(tint.rgb, smoothstep(INNER, OUTER, r) * strength);
}
