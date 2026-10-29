shader_type canvas_item;
// Normalized frame canvas. The feet stay at (360, 580).
uniform float idle_weight : hint_range(0.0, 1.0) = 0.0;
uniform float idle_phase = 0.0;
uniform float idle_sway_amplitude : hint_range(0.0, 8.0) = 2.0;
uniform float walk_weight : hint_range(0.0, 1.0) = 0.0;
uniform float walk_phase = 0.0;
uniform float shoulder_swing : hint_range(0.0, 16.0) = 6.0;
uniform float shoulder_roll : hint_range(0.0, 12.0) = 4.0;

uniform bool use_alpha_mask = false;
uniform sampler2D alpha_mask : filter_linear, repeat_disable;
uniform vec2 frame_anchor=vec2(360.0,580.0);
uniform float ink_width=0.0;
varying vec4 hero_tint;
void vertex() {
	hero_tint=COLOR;
	vec2 point = VERTEX - (frame_anchor-vec2(360.0,580.0));
	float upper_body = 1.0 - smoothstep(345.0, 410.0, point.y);
	float cape = (1.0 - smoothstep(285.0, 370.0, point.x))
		* (1.0 - smoothstep(440.0, 580.0, point.y));
	// No continuous breathing. This weight is zero throughout the long rests.
	VERTEX.x += idle_weight * idle_sway_amplitude * (
		sin(idle_phase) * upper_body * 0.35
		+ sin(idle_phase - 0.4) * cape
	);
	VERTEX.y -= sin(idle_phase) * idle_sway_amplitude * 0.25 * upper_body * idle_weight;

	// Opposing shoulder heights and a slight torso shift, synchronized to the walk.
	float shoulders = smoothstep(265.0, 325.0, point.y)
		* (1.0 - smoothstep(365.0, 410.0, point.y));
	float side = clamp((point.x - 360.0) / 80.0, -1.0, 1.0);
	float stride = sin(walk_phase);
	VERTEX.x += stride * shoulder_swing * upper_body * walk_weight;
	VERTEX.y += stride * shoulder_roll * side * shoulders * walk_weight;
	VERTEX.y -= sin(walk_phase * 2.0) * shoulder_roll * 0.18 * upper_body * walk_weight;
}

void fragment(){
	if(ink_width>0.0){
		vec4 source=texture(TEXTURE,UV);
		if(use_alpha_mask){source.a=texture(alpha_mask,UV).r;}
		float edge=source.a;
		float dark=0.0;
		for(int i=0;i<8;i++){
			vec2 direction=vec2(cos(float(i)*0.785398163),sin(float(i)*0.785398163))*TEXTURE_PIXEL_SIZE;
			vec2 outer_uv=UV+direction*ink_width;
			edge=max(edge,use_alpha_mask?texture(alpha_mask,outer_uv).r:texture(TEXTURE,outer_uv).a);
			vec2 inner_uv=UV+direction*ink_width*0.35;
			vec4 sample_ink=texture(TEXTURE,inner_uv);
			float opacity=use_alpha_mask?texture(alpha_mask,inner_uv).r:sample_ink.a;
			dark=max(dark,opacity*(1.0-smoothstep(0.10,0.18,max(sample_ink.r,max(sample_ink.g,sample_ink.b)))));
		}
		vec3 ink=vec3(0.025,0.03,0.04);
		COLOR=vec4(mix(ink,mix(source.rgb,ink,dark*0.35),source.a),edge)*hero_tint;
	}else if(use_alpha_mask){COLOR.a*=texture(alpha_mask,UV).r;}
}
