class_name Base
extends Estructura
## La base del jugador, a la izquierda. Si llega a 0, la misión se pierde.
## Tiene una sola puerta, en el carril del medio: por ahí salen las unidades.

## Altura del suelo de la puerta, relativa a la base (negativa = arriba).
var puerta_y := 0.0
const ANCHO_PUERTA := 34.0
const ALTO_PUERTA := 64.0


func _draw() -> void:
	super()
	var x := ancho / 2.0 - ANCHO_PUERTA
	var tono := Color(0.25, 0.25, 0.25) if esta_vivo() else Color(0.1, 0.1, 0.1)
	draw_rect(Rect2(x, puerta_y - ALTO_PUERTA, ANCHO_PUERTA, ALTO_PUERTA), tono)
	draw_rect(Rect2(x, puerta_y - ALTO_PUERTA, ANCHO_PUERTA, ALTO_PUERTA), Color(0.15, 0.15, 0.15), false, 2.0)
