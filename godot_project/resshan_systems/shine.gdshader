shader_type canvas_item;

uniform int pixel_size = 10;
uniform vec4 color : source_color;
uniform float time = -.5;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	
	COLOR.a = 0.0;
	
	vec2 grid_uv = round(UV * float(pixel_size)) / float(pixel_size);
	
	float phase = (-grid_uv.y + UV.x + 1.0) * 0.5;
	
	if (phase >= tan(time)) {
		if (phase <= tan(time) + 0.5) {
			COLOR.rgba = vec4(color.rgb, sin(phase * 3.0));
		}
	}
	
	if (UV.x > 0.99) {
		COLOR.a = 0.0;
	}
	if (UV.x < 0.01) {
		COLOR.a = 0.0;
	}
	if (UV.y > 0.99) {
		COLOR.a = 0.0;
	}
	if (UV.y < 0.01) {
		COLOR.a = 0.0;
	}
	
	if (abs(time) > 1.0) {
		COLOR.a = 0.0;
	}
	
	//vec4 text = texture(TEXTURE, grid_uv);
	//
	//COLOR = text;
	
	// End:
	// UV.y = 0.0
	// UV.x = 1.0
	
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
