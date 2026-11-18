// canvas_post_pixel: draws the game world as pixel art (story 054, decision D-059).
// Author: Soul Vessels team (built with Claude Code).
//
// A full-screen ColorRect between the world (and its darkness overlay) and the HUD. It reads the
// screen, snaps it to a grid of `virtual_height` rows of square cells, takes each cell's colour
// from its centre, darkens a cell whose neighbours are much brighter (a soft pixel outline that
// keeps silhouettes crisp at low resolution), and posterizes with a 4x4 ordered dither.
//
// Target: Godot 4.7 Mobile renderer, Android ARM64. Budget: 3 screen samples per pixel.
shader_type canvas_item;

uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
uniform float virtual_height = 360.0;
uniform float levels = 22.0;
uniform float dither_amount : hint_range(0.0, 1.0) = 0.55;
uniform float outline : hint_range(0.0, 1.0) = 0.35;

float bayer4(vec2 p) {
	int x = int(mod(p.x, 4.0));
	int y = int(mod(p.y, 4.0));
	int i = x + y * 4;
	// 4x4 Bayer matrix, values 0..15.
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0 - 0.5;
}

float luma(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 screen_size = 1.0 / SCREEN_PIXEL_SIZE;
	float cell = screen_size.y / virtual_height;
	vec2 cell_id = floor(FRAGCOORD.xy / cell);
	vec2 centre = (cell_id + 0.5) * cell * SCREEN_PIXEL_SIZE;
	vec3 c = textureLod(screen_tex, centre, 0.0).rgb;
	// Outline: a cell darker than the cell above-left by a margin gets darker still.
	vec3 n = textureLod(screen_tex, centre - vec2(cell, cell) * SCREEN_PIXEL_SIZE, 0.0).rgb;
	float edge = clamp((luma(n) - luma(c)) * 3.0, 0.0, 1.0);
	c *= 1.0 - edge * outline;
	// Posterize with an ordered dither, per virtual pixel.
	float d = bayer4(cell_id) * dither_amount;
	c = floor(c * levels + 0.5 + d) / levels;
	COLOR = vec4(clamp(c, 0.0, 1.0), 1.0);
}
