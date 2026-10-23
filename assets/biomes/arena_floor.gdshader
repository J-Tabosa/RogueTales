shader_type canvas_item;
uniform float ground_start = 0.44;
uniform float ground_end = 0.94;
uniform float floor_horizon = 0.36;
varying vec4 arena_tint;
void vertex(){ arena_tint=COLOR; }
void fragment(){
	vec2 at=UV;
	if(UV.y<floor_horizon){at.y=UV.y/floor_horizon*ground_start;}
	else{at.y=mix(ground_start,ground_end,(UV.y-floor_horizon)/(1.0-floor_horizon));}
	COLOR=texture(TEXTURE,at)*arena_tint;
}
