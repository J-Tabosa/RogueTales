shader_type canvas_item;
uniform float progress : hint_range(0.0,1.0)=0.0;
uniform float opacity : hint_range(0.0,1.0)=0.0;
uniform bool reduced_motion=false;
float hash(vec2 p){return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453);}
void fragment(){
	float crest=mix(-0.35,1.35,progress)+sin(UV.x*10.0+progress*2.4)*0.045+sin(UV.x*23.0)*0.013;
	float grain=hash(floor(UV*vec2(75.0,44.0)));
	float distance=abs(UV.y-crest);
	float band=(1.0-smoothstep(0.035,0.19,distance))*(0.75+0.25*grain);
	float edge=(1.0-smoothstep(0.008,0.035,distance))*0.35;
	float alpha=opacity*(reduced_motion?0.24:0.17+band*0.58+edge);
	vec3 tint=mix(vec3(0.14,0.52,0.76),vec3(0.66,0.88,0.96),edge);
	COLOR=vec4(tint,alpha);
}
