shader_type canvas_item;

instance uniform float desaturate_strength: hint_range(0.0, 1.0) = 1.0;

void fragment() {
	vec4 original_color = texture(TEXTURE, UV);
	float gray = (original_color.r + original_color.g + original_color.b) / 3.0;
	vec4 gray_color = vec4(gray, gray, gray, original_color.a);
	COLOR = mix(original_color, gray_color, desaturate_strength);
}