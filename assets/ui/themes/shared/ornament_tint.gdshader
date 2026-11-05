shader_type canvas_item;
// Preserve generated relief; every visible color comes from the active theme.
uniform vec4 theme_tint : source_color = vec4(1.0);
void fragment() {
    vec4 art = texture(TEXTURE, UV);
    float relief = mix(0.55, 1.0, max(art.r, max(art.g, art.b)));
    COLOR = vec4(theme_tint.rgb * relief, art.a * theme_tint.a);
}
