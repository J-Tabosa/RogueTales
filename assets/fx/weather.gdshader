shader_type canvas_item;
render_mode unshaded;
uniform int weather_mode=0;
uniform float clock=0.0;
uniform float aspect=1.0;
uniform float strength=0.65;
uniform int layers=3;
float hash21(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
	vec2 uv=UV;
	vec3 tint=vec3(0.83,0.94,1.0);
	float alpha=0.0;
	if(weather_mode==1||weather_mode==4){
		for(int layer=0;layer<3;layer++){
			if(layer>=layers){break;}
			float l=float(layer);
			float scale=12.0+l*9.0;
			float direction=weather_mode==4?1.0:-1.0;
			vec2 p=vec2(uv.x*aspect+sin(clock*0.27+l)*0.018,uv.y+direction*clock*(0.035+l*0.016))*scale;
			vec2 cell=floor(p);
			vec2 center=vec2(hash21(cell+l),hash21(cell+19.0+l))*0.7+0.15;
			float radius=weather_mode==4?0.045:0.055;
			float dot_mask=1.0-smoothstep(radius*0.3,radius,length(fract(p)-center));
			alpha+=dot_mask*(0.47-l*0.1);
		}
		if(weather_mode==4){
			tint=vec3(1.0,0.48,0.16);
			float edge=pow(abs(uv.x-0.5)*2.0,5.0)*0.06+pow(uv.y,5.0)*0.05;
			alpha=alpha*0.62+edge;
		}
	}else if(weather_mode==2){
		vec2 p=vec2((uv.x*aspect+uv.y*0.14)*38.0,(uv.y-clock*0.65)*14.0);
		vec2 cell=floor(p);
		float chance=step(0.5,hash21(cell));
		float line=1.0-smoothstep(0.012,0.037,abs(fract(p.x)-hash21(cell+5.0)*0.7-0.15));
		float tail=smoothstep(0.08,0.23,fract(p.y))*(1.0-smoothstep(0.46,0.86,fract(p.y)));
		alpha=line*tail*chance*0.43;
		tint=vec3(0.63,0.81,0.96);
	}else if(weather_mode==3){
		float beam=pow(max(0.0,sin((uv.x+uv.y*0.45)*18.0+sin(clock*0.13)*0.14)),8.0);
		float fade=(1.0-smoothstep(0.0,0.95,uv.y))*smoothstep(0.12,0.95,uv.x);
		alpha=(beam*0.12+0.025)*fade;
		tint=vec3(1.0,0.88,0.55);
	}
	COLOR=vec4(tint,min(alpha*strength,0.38));
}
