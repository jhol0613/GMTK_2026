shader_type canvas_item;
render_mode blend_add, unshaded;

void fragment() {
	vec2 pixel = UV * vec2(textureSize(TEXTURE, 0));
	float inside = step(16.5, pixel.x) * step(pixel.x, 30.5) * step(49.5, pixel.y) * step(pixel.y, 53.5);
	COLOR = texture(TEXTURE, UV) * COLOR * (1.0 - inside);
}
