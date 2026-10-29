shader_type canvas_item;
uniform float ground_start=0.60;
uniform float ground_end=0.98;
uniform float floor_horizon=0.36;
uniform float arena_aspect=1.0;
uniform float source_aspect=1.777;
varying vec4 arena_tint;
void vertex(){arena_tint=COLOR;}
void fragment(){
	vec2 at=UV;
	at.x=(UV.x-0.5)*min(1.0,arena_aspect/source_aspect)+0.5;
	// Blend projection slopes across the horizon without blurring the art.
	float background_y=UV.y/floor_horizon*ground_start;
	float ground_y=mix(ground_start,ground_end,(UV.y-floor_horizon)/(1.0-floor_horizon));
	at.y=mix(background_y,ground_y,smoothstep(floor_horizon-0.12,floor_horizon+0.12,UV.y));
	COLOR=texture(TEXTURE,at)*arena_tint;
}
