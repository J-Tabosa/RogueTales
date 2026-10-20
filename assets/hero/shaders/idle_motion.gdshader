shader_type canvas_item;
// Gentle deformation in the saved frame canvas (720 × 600).
// Feet are at (360, 580), so the lower body remains planted.
uniform float idle_weight : hint_range(0.0, 1.0) = 0.0;
uniform float motion_phase = 0.0;
uniform float breath_amplitude : hint_range(0.0, 12.0) = 4.0;
uniform float cloth_amplitude : hint_range(0.0, 20.0) = 8.0;

void vertex() {
	vec2 point = VERTEX;
	float planted = 1.0 - smoothstep(440.0, 580.0, point.y);
	float upper_body = 1.0 - smoothstep(345.0, 510.0, point.y);
	float cape = (1.0 - smoothstep(285.0, 370.0, point.x)) * planted;
	float hair = (1.0 - smoothstep(345.0, 400.0, point.y))
		* (1.0 - smoothstep(315.0, 370.0, point.x));
	float breathing = sin(motion_phase);
	float delayed_sway = sin(motion_phase - 0.7 + (point.y - 300.0) * 0.007);
	VERTEX.y -= breathing * breath_amplitude * upper_body * idle_weight;
	VERTEX.x += idle_weight * (
		breathing * breath_amplitude * 0.18 * upper_body
		+ delayed_sway * cloth_amplitude * cape
		+ sin(motion_phase - 0.35) * cloth_amplitude * 0.3 * hair
	);
	VERTEX.y += sin(motion_phase - 1.0) * cloth_amplitude * 0.18 * cape * idle_weight;
}
