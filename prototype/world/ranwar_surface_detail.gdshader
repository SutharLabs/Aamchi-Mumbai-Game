shader_type spatial;

uniform sampler2D plaster_tile : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D concrete_tile : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D clay_tile : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D timber_tile : source_color, filter_linear_mipmap_anisotropic, repeat_enable;

varying vec2 lot_offset;

void vertex() {
	lot_offset = fract(MODEL_MATRIX[3].xz * vec2(0.173, 0.137));
}

void fragment() {
	float finish = UV2.x;
	vec3 base = COLOR.rgb;
	if (finish >= 3.5) {
		vec3 tile = texture(timber_tile, UV).rgb;
		base = tile * mix(vec3(1.0), base, 0.25);
	} else if (finish >= 2.5) {
		vec3 tile = texture(clay_tile, UV).rgb;
		base = tile * mix(vec3(1.0), base, 0.20);
	} else if (finish >= 1.5) {
		vec3 tile = texture(concrete_tile, UV).rgb;
		base = mix(base, tile * mix(vec3(1.0), base, 0.26), 0.66);
	} else if (finish >= 0.5) {
		vec3 tile = texture(plaster_tile, UV + lot_offset).rgb;
		vec2 wider_uv = vec2(UV.y, -UV.x) * 0.19 + lot_offset + vec2(0.45, 0.24);
		vec3 weathering = texture(plaster_tile, wider_uv).rgb;
		base *= mix(vec3(1.0), tile * mix(vec3(0.95), weathering, 0.34), 0.84);
	}
	ALBEDO = base;
	ROUGHNESS = 0.92;
	SPECULAR = 0.22;
}
