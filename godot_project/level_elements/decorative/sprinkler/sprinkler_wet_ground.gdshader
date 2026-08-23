shader_type canvas_item;
render_mode unshaded, blend_mul;

uniform float wet_strength : hint_range(0.0, 1.0) = 0.0;
uniform vec3 wet_multiplier = vec3(0.86, 0.88, 0.86);

void fragment() {
	vec3 multiplier = mix(
		vec3(1.0),
		wet_multiplier,
		wet_strength
	);
	COLOR = vec4(multiplier, 1.0);
}
