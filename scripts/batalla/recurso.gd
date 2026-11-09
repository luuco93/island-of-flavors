class_name Recurso
extends Node
## Una barra de recurso con máximo.

signal cambiado(actual: float, maximo: float)

var maximo := 100.0
var actual := 0.0


func configurar(inicial: float, maximo_: float) -> void:
	maximo = maximo_
	actual = clampf(inicial, 0.0, maximo)
	cambiado.emit(actual, maximo)


func sumar(cantidad: float) -> void:
	var antes := actual
	actual = clampf(actual + cantidad, 0.0, maximo)
	if actual != antes:
		cambiado.emit(actual, maximo)


func puede_pagar(coste: float) -> bool:
	return actual >= coste


func pagar(coste: float) -> bool:
	if not puede_pagar(coste):
		return false
	sumar(-coste)
	return true
