shader_type canvas_item;
render_mode unshaded;

uniform vec4 frame_shadow : source_color;
uniform vec4 frame_midtone : source_color;
uniform vec4 frame_highlight : source_color;

void fragment() {
	// Retain the carved lighting and the original cutout alpha.
	float value = dot(COLOR.rgb, vec3(0.299, 0.587, 0.114));
	vec3 base = mix(frame_shadow.rgb, frame_midtone.rgb, smoothstep(0.24, 0.64, value));
	COLOR.rgb = mix(base, frame_highlight.rgb, smoothstep(0.54, 0.92, value));
}
