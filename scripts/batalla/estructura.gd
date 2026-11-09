class_name Estructura
extends Node2D
## Algo fijo con vida en el carril: la base o el obstáculo.

signal vida_cambiada(actual: float, maxima: float)
signal destruida

@export var ancho := 100.0
@export var alto := 160.0
@export var color := Color(0.4, 0.4, 0.4)

var vida_maxima := 1.0
var vida := 1.0


func configurar(vida_inicial: float) -> void:
	vida_maxima = vida_inicial
	vida = vida_inicial
	vida_cambiada.emit(vida, vida_maxima)
	queue_redraw()


func esta_vivo() -> bool:
	return vida > 0.0


func fraccion_vida() -> float:
	return vida / vida_maxima


## Distancia desde un punto del carril hasta el borde más cercano.
func distancia_desde(x: float) -> float:
	return maxf(0.0, absf(x - position.x) - ancho / 2.0)


func recibir_dano(cantidad: float) -> void:
	if not esta_vivo():
		return
	vida = maxf(0.0, vida - cantidad)
	vida_cambiada.emit(vida, vida_maxima)
	queue_redraw()
	if vida <= 0.0:
		destruida.emit()


func reparar(cantidad: float) -> void:
	if not esta_vivo():
		return
	vida = minf(vida_maxima, vida + cantidad)
	vida_cambiada.emit(vida, vida_maxima)
	queue_redraw()


func _draw() -> void:
	var tono := color if esta_vivo() else color.darkened(0.6)
	draw_rect(Rect2(-ancho / 2.0, -alto, ancho, alto), tono)
	draw_rect(Rect2(-ancho / 2.0, -alto, ancho, alto), Color(0.15, 0.15, 0.15), false, 2.0)
