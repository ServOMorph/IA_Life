shader_type spatial;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D arm_tex : filter_linear_mipmap, repeat_enable;
uniform float texture_scale = 0.5;
uniform float blend_sharpness = 4.0;
uniform float min_roughness = 0.6;
uniform float normal_strength = 0.6;

varying vec3 world_position;
varying vec3 world_normal;

void vertex() {
	world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 blend_weights = pow(abs(world_normal), vec3(blend_sharpness));
	blend_weights /= (blend_weights.x + blend_weights.y + blend_weights.z);

	vec2 uv_x = world_position.zy * texture_scale;
	vec2 uv_y = world_position.xz * texture_scale;
	vec2 uv_z = world_position.xy * texture_scale;

	vec4 albedo_x = texture(albedo_tex, uv_x);
	vec4 albedo_y = texture(albedo_tex, uv_y);
	vec4 albedo_z = texture(albedo_tex, uv_z);
	ALBEDO = (albedo_x.rgb * blend_weights.x + albedo_y.rgb * blend_weights.y + albedo_z.rgb * blend_weights.z);

	vec4 arm_x = texture(arm_tex, uv_x);
	vec4 arm_y = texture(arm_tex, uv_y);
	vec4 arm_z = texture(arm_tex, uv_z);
	vec3 arm = arm_x.rgb * blend_weights.x + arm_y.rgb * blend_weights.y + arm_z.rgb * blend_weights.z;
	AO = arm.r;
	ROUGHNESS = max(arm.g, min_roughness);
	METALLIC = arm.b;

	vec3 normal_x = texture(normal_tex, uv_x).rgb * 2.0 - 1.0;
	vec3 normal_y = texture(normal_tex, uv_y).rgb * 2.0 - 1.0;
	vec3 normal_z = texture(normal_tex, uv_z).rgb * 2.0 - 1.0;
	NORMAL_MAP = normalize(normal_x * blend_weights.x + normal_y * blend_weights.y + normal_z * blend_weights.z);
	NORMAL_MAP_DEPTH = normal_strength;
}
