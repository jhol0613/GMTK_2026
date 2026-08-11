shader_type canvas_item;
render_mode blend_mix, unshaded;

uniform sampler2D mask_texture : filter_nearest;

void fragment() {
	vec2 pixel = UV * vec2(textureSize(TEXTURE, 0));
	float inside = step(29.5, pixel.x) * step(pixel.x, 50.5) * step(85.5, pixel.y) * step(pixel.y, 88.5);
	float selected = inside * step(0.001, texture(mask_texture, UV).a);
	COLOR = texture(TEXTURE, UV) * COLOR * selected;
}
