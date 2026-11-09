class_name Comandante
extends Node2D
## El comandante de la base (el general de la región). Se ve sobre la base y
## tiene una habilidad activa que se paga con el recurso de combate.
## Habilidad "andanada": daña a todos los enemigos del campo y los empuja
## hacia atrás.

signal habilidad_usada

var id := ""
var habilidad := "andanada"
var coste := 100.0
var dano := 200.0
var empuje := 120.0
var _destello := 0.0


func configurar(id_: String, datos: Dictionary) -> void:
	id = id_
	habilidad = datos.get("habilidad", "andanada")
	coste = float(datos.get("coste", 100))
	dano = float(datos.get("dano", 200))
	empuje = float(datos.get("empuje", 0))


func listo(recurso: RecursoCombate) -> bool:
	return recurso.puede_pagar(coste)


## Devuelve cuántos enemigos alcanzó, o -1 si no se pudo usar.
func usar(recurso: RecursoCombate, enemigos: Array, limite_x: float) -> int:
	if not listo(recurso):
		return -1
	recurso.pagar(coste)
	var alcanzados := 0
	for e: Enemigo in enemigos:
		if not e.esta_vivo():
			continue
		e.position.x = minf(limite_x, e.position.x + empuje)
		e.recibir_dano(dano)
		alcanzados += 1
	_destello = 0.5
	habilidad_usada.emit()
	return alcanzados


func _process(delta: float) -> void:
	if _destello > 0.0:
		_destello = maxf(0.0, _destello - delta)
		queue_redraw()


func _draw() -> void:
	# Figura gris del general sobre la base: cuerpo, cabeza y banderín.
	var oscuro := Color(0.12, 0.12, 0.12)
	draw_rect(Rect2(-14, -34, 28, 34), Color(0.55, 0.55, 0.55))
	draw_rect(Rect2(-14, -34, 28, 34), oscuro, false, 1.5)
	draw_circle(Vector2(0, -46), 12, Color(0.75, 0.75, 0.75))
	draw_arc(Vector2(0, -46), 12, 0, TAU, 20, oscuro, 1.5)
	draw_line(Vector2(18, 0), Vector2(18, -70), oscuro, 2.0)
	draw_colored_polygon([Vector2(18, -70), Vector2(42, -62), Vector2(18, -54)], oscuro)
	if _destello > 0.0:
		var a := _destello / 0.5
		draw_arc(Vector2(0, -40), 40 + (1.0 - a) * 60, 0, TAU, 32, Color(0.05, 0.05, 0.05, a), 3.0)
