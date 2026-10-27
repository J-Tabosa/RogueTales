shader_type canvas_item;
render_mode unshaded;
uniform float progress=0.0;
uniform float opacity=0.0;
uniform bool reduced_motion=false;
void fragment(){
	float t=reduced_motion?0.5:progress;
	float flicker=sin(UV.x*24.0-t*12.0)*0.023+sin(UV.x*57.0+t*8.0)*0.012;
	float bottom=smoothstep(0.68+flicker,1.0,UV.y);
	float side=pow(abs(UV.x-0.5)*2.0,7.0)*0.48;
	float brush=0.76+0.24*sin(UV.x*83.0+UV.y*39.0-t*14.0);
	float mask=clamp((bottom+side)*brush,0.0,1.0);
	vec3 warm=mix(vec3(0.95,0.21,0.08),vec3(1.0,0.74,0.25),bottom*0.75);
	COLOR=vec4(warm,mask*opacity);
}
