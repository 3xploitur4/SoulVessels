shader_type canvas_item;
// Soul Vessels, story 060 (decision D-071): recolour a painted item icon in the inventory while
// keeping its light and shade. The painting's brightness is carried into `tint` and mixed in by
// `amount` (0 = as painted). Target: every renderer (Mobile included); one texture read, no branch.

// Luminance weights (Rec. 601) and how much the recoloured brightness is lifted back up, since a
// painting's average brightness is well under 1.
const vec3 LUMA = vec3(0.299, 0.587, 0.114);
const float LIFT = 1.55;

group_uniforms recolour;
uniform vec4 tint : source_color = vec4(1.0);
uniform float amount : hint_range(0.0, 1.0) = 0.0;
group_uniforms;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float lum = dot(c.rgb, LUMA);
	// Brightness kept: dark stays dark, highlights take the colour.
	vec3 recoloured = tint.rgb * (lum * LIFT);
	COLOR = vec4(mix(c.rgb, recoloured, amount), c.a) * COLOR;
}
