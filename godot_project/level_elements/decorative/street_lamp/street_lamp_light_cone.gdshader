shader_type canvas_item;
render_mode blend_add, unshaded;

void fragment() {
	float half_width = mix(0.055, 0.5, smoothstep(0.0, 0.88, UV.y));
	float distance_from_center = abs(UV.x - 0.5) / half_width;
	float side_fade = 1.0 - smoothstep(0.68, 1.0, distance_from_center);
	float top_fade = smoothstep(0.0, 0.06, UV.y);
	float normalized_x = abs(UV.x - 0.5) * 2.0;
	float bottom_limit = 0.96 - 0.24 * normalized_x * normalized_x;
	float bottom_fade = 1.0 - smoothstep(bottom_limit - 0.14, bottom_limit, UV.y);
	float vertical_fade = mix(1.0, 0.12, smoothstep(0.04, 0.92, UV.y));
	float alpha = side_fade * top_fade * bottom_fade * vertical_fade;
	COLOR = vec4(1.0, 0.68, 0.28, alpha) * COLOR;
}
