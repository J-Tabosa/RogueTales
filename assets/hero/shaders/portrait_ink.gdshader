shader_type canvas_item;
render_mode unshaded;
uniform float ink_width=2.0;
uniform float inner_width=0.35;
uniform vec4 ink_color:source_color=vec4(0.025,0.03,0.04,1.0);
varying vec4 ink_tint;
void vertex(){ink_tint=COLOR;}
void fragment(){
	vec4 source=texture(TEXTURE,UV);
	float edge=source.a;
	float dark=0.0;
	for(int i=0;i<8;i++){
		float angle=float(i)*0.785398163;
		vec2 direction=vec2(cos(angle),sin(angle))*TEXTURE_PIXEL_SIZE;
		edge=max(edge,texture(TEXTURE,UV+direction*ink_width).a);
		vec4 sample_ink=texture(TEXTURE,UV+direction*inner_width);
		dark=max(dark,sample_ink.a*(1.0-smoothstep(0.10,0.18,max(sample_ink.r,max(sample_ink.g,sample_ink.b)))));
	}
	vec3 reinforced=mix(source.rgb,ink_color.rgb,dark*0.35);
	COLOR=vec4(mix(ink_color.rgb,reinforced,source.a),edge)*ink_tint;
}
