shader_type canvas_item;

uniform vec3 tint_compensation = vec3(1.0);
uniform bool full_sprite = false;
uniform float particle_start = 0.64;

void fragment() {
	vec4 source = texture(TEXTURE, UV);
	float particle_mask = full_sprite ? step(0.001, source.a) : step(particle_start, UV.y) * step(0.001, source.a);
	COLOR.rgb *= mix(vec3(1.0), tint_compensation, particle_mask);
}
