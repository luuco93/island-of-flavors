class_name Carriles
extends Node2D
## Dibuja los carriles.

var batalla: Batalla


func _draw() -> void:
	if batalla == null or batalla.suelos.is_empty():
		return
	var alto := batalla.alto_carril
	for i in batalla.suelos.size():
		var y: float = batalla.suelos[i]
		draw_rect(Rect2(-600, y - alto + 20, 2480, alto), Color(0.79, 0.79, 0.79))
		draw_line(Vector2(-600, y), Vector2(1880, y), Color(0.55, 0.55, 0.55), 2.0)
