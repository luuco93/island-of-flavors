class_name EfectoArea
extends Node2D
## Círculo que se desvanece donde cayó un poder de combate.

var radio := 120.0
var duracion := 0.4
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= duracion:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var a := 1.0 - _t / duracion
	draw_circle(Vector2.ZERO, radio, Color(0.1, 0.1, 0.1, 0.35 * a))
	draw_arc(Vector2.ZERO, radio, 0, TAU, 48, Color(0.05, 0.05, 0.05, a), 3.0)
