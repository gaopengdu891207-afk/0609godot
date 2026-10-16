shader_type canvas_item;

// 从外部传入参数
uniform vec2 center_pixel = vec2(480.0, 270.0); 
uniform float radius_pixel = 150.0;

// 片段函数，逐像素遍历
void fragment() {
	vec2 px = UV / TEXTURE_PIXEL_SIZE;
	float d = distance(px, center_pixel);
	if (d > radius_pixel) {
		discard;
	}
	COLOR = texture(TEXTURE, UV);
}
