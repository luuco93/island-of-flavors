shader_type canvas_item;
render_mode unshaded;
// Para un CanvasGroup: dibuja el personaje completo con un borde blanco de
// recorte alrededor de la silueta y una sombra corta de papel debajo.
// Los grosores van en píxeles de pantalla; el script los ajusta al tamaño
// real de la pantalla para que se vean igual en cualquier móvil.

uniform float grosor = 2.5;
uniform vec4 color_borde : source_color = vec4(1.0, 0.99, 0.96, 1.0);
uniform vec2 desfase_sombra = vec2(2.0, 3.0);
uniform vec4 color_sombra : source_color = vec4(0.18, 0.12, 0.10, 0.30);
uniform sampler2D pantalla : hint_screen_texture, repeat_disable, filter_linear_mipmap;

float alfa_en(vec2 uv) {
	return textureLod(pantalla, uv, 0.0).a;
}

// Cuánto cubre la silueta engordada "radio" píxeles alrededor de uv.
float silueta(vec2 uv, float radio, vec2 px) {
	float a = alfa_en(uv);
	for (int i = 0; i < 12; i++) {
		float ang = float(i) * 0.5235988;
		a = max(a, alfa_en(uv + vec2(cos(ang), sin(ang)) * radio * px));
	}
	return a;
}

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE;
	vec4 c = textureLod(pantalla, SCREEN_UV, 0.0);
	if (c.a > 0.0001) {
		c.rgb /= c.a;
	}
	float borde = silueta(SCREEN_UV, grosor, px);
	float sombra = silueta(SCREEN_UV - desfase_sombra * px, grosor, px) * color_sombra.a;
	// abajo la sombra, encima el borde blanco y encima el personaje
	vec4 fondo = vec4(color_sombra.rgb, sombra);
	vec4 con_borde = mix(fondo, vec4(color_borde.rgb, 1.0), borde);
	con_borde.a = max(fondo.a, borde);
	COLOR = mix(con_borde, vec4(c.rgb, 1.0), c.a);
	COLOR.a = max(con_borde.a, c.a);
}
