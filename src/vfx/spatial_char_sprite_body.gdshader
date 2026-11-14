// spatial_char_sprite_body: paper-puppet body for painted characters and enemies.
// Story 027, decision D-032. Author: Soul Vessels team (built with Claude Code).
//
// One painted sprite on a subdivided quad. The vertex stage bends it so a single pose can walk
// (each half of the lower body lifts in turn), lean, breathe and flutter at its edges. The
// fragment stage cuts it out with an alpha scissor, so it writes depth like solid geometry:
// no transparency sorting and no overdraw blending.
//
// Target: Godot 4.7 Mobile renderer (Forward Mobile), Android ARM64, 60 FPS on a Snapdragon 778.
// Budget: 1 texture sample, no loops, no dynamic branches. One variant (no keywords).
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled, shadows_disabled;

// Screen-door pattern period for the stealth look (every other pixel).
const float DITHER_PERIOD = 2.0;
// Dissolve noise grid: cells across and down the sprite.
const vec2 DISSOLVE_CELLS = vec2(40.0, 64.0);
// Width of the glowing rim ahead of the dissolve front (in noise units).
const float BURN_RIM = 0.12;
// Hash constants (the usual sine hash).
const vec2 HASH_DOT = vec2(12.9898, 78.233);
const float HASH_SCALE = 43758.5453;
// Stealth tint.
const vec3 GHOST_TINT = vec3(0.16, 0.1, 0.32);
const float GHOST_TINT_AMOUNT = 0.7;
// Share of the albedo that still receives scene light at full self-light.
const float LIT_SHARE = 0.5;
// Sideways leg swing as a share of the lift.
const float STRIDE_SHARE = 0.6;
// Cape flutter: speed (rad/s), waves along the height, and how much the head is spared.
const float WIND_SPEED = 2.6;
const float WIND_WAVES = 5.0;
const float WIND_HEAD_DAMP = 0.5;
// Breathing starts at this share of the height (the chest).
const float BREATH_FROM = 0.35;

group_uniforms surface;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_disable;
// The painting carries its own shading: most of its brightness is self-light, the scene only tints.
// Multiplied into the painting (variants that share one sprite, e.g. the Fungal Stalker).
uniform vec4 tint : source_color = vec4(1.0);
uniform float emission_amount : hint_range(0.0, 1.5) = 0.62;
uniform float glow : hint_range(0.0, 2.0) = 0.0;

group_uniforms effects;
uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform vec4 dissolve_color : source_color = vec4(0.55, 0.9, 1.0, 1.0);
uniform float ghost : hint_range(0.0, 1.0) = 0.0;

group_uniforms motion;
// Shear in metres at the head (positive = forward).
uniform float lean = 0.0;
uniform float step_phase = 0.0;
// Metres a foot lifts at the top of a step.
uniform float step_amount = 0.0;
// Share of the height that counts as legs.
uniform float leg_height : hint_range(0.1, 1.0) = 0.42;
// Metres per metre of height the chest rises (animated by the script).
uniform float breath = 0.0;
// Metres the outer edges sway (capes, robes).
uniform float wind = 0.0;
uniform float height_m = 2.0;

void vertex() {
	float h = 1.0 - UV.y;                       // 0 at the feet, 1 at the head
	float side = sign(UV.x - 0.5);              // which leg this column belongs to
	float leg = clamp(1.0 - h / leg_height, 0.0, 1.0);
	VERTEX.x += lean * h * h;                   // quadratic: feet stay planted
	VERTEX.y += step_amount * leg * max(0.0, sin(step_phase) * side);
	VERTEX.x += step_amount * STRIDE_SHARE * leg * cos(step_phase) * side;
	VERTEX.y += breath * smoothstep(BREATH_FROM, 1.0, h) * height_m;
	float edge = abs(UV.x - 0.5) * 2.0;         // 0 at the spine, 1 at the silhouette edge
	VERTEX.x += sin(TIME * WIND_SPEED + h * WIND_WAVES) * wind * edge * edge * (1.0 - h * WIND_HEAD_DAMP);
}

void fragment() {
	vec4 c = texture(tex, UV);
	float n = fract(sin(dot(floor(UV * DISSOLVE_CELLS), HASH_DOT)) * HASH_SCALE);
	float alive = step(dissolve, n);                                  // 0 where the cell has burned away
	float burn = (1.0 - step(dissolve + BURN_RIM, n)) * step(0.001, dissolve);
	float checker = mod(floor(FRAGCOORD.x) + floor(FRAGCOORD.y), DITHER_PERIOD);
	float seen = 1.0 - step(0.5, ghost) * (1.0 - checker);            // stealth drops every other pixel
	vec3 col = mix(c.rgb * tint.rgb, GHOST_TINT, GHOST_TINT_AMOUNT * ghost);
	col = mix(col, flash_color.rgb, flash);
	ALBEDO = col * (1.0 - emission_amount * LIT_SHARE);
	EMISSION = col * (emission_amount + glow) + flash_color.rgb * flash + dissolve_color.rgb * burn * 3.0;
	ROUGHNESS = 1.0;
	ALPHA = c.a * alive * seen;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
}
