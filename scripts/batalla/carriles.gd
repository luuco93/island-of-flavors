class_name Carriles
extends Node2D
## Dibuja los carriles y resalta el elegido para invocar.

var batalla: Batalla


func _draw() -> void:
	if batalla == null or batalla.suelos.is_empty():
		return
	var alto := batalla.alto_carril
	for i in batalla.suelos.size():
		var y: float = batalla.suelos[i]
		var rect := Rect2(-600, y - alto + 20, 2480, alto)
		var elegido := i == batalla.carril_elegido
		draw_rect(rect, Color(0.74, 0.74, 0.74) if elegido else Color(0.8, 0.8, 0.8))
		draw_line(Vector2(-600, y), Vector2(1880, y), Color(0.55, 0.55, 0.55), 2.0)
		if elegido:
			# Flecha junto a la base: aquí aparecerán las unidades.
			var x := float(batalla.reglas.campo.aparicion_unidades_x) + 30.0
			draw_colored_polygon([Vector2(x, y - 50), Vector2(x + 22, y - 38), Vector2(x, y - 26)], Color(0.2, 0.2, 0.2))
