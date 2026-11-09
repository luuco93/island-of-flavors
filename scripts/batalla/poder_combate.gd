class_name PoderCombate
extends Node
## Poder que se paga con el recurso de combate y se suelta en un punto del
## carril. El primero es el explosivo: daño en área.

var id := ""
var coste := 40.0
var espera := 15.0
var dano := 300.0
var radio := 120.0
var espera_restante := 0.0


func configurar(id_: String, datos: Dictionary) -> void:
	id = id_
	coste = float(datos.get("coste", 40))
	espera = float(datos.get("espera", 15))
	dano = float(datos.get("dano", 300))
	radio = float(datos.get("radio", 120))
	espera_restante = 0.0


func avanzar(delta: float) -> void:
	espera_restante = maxf(0.0, espera_restante - delta)


func listo(recurso: RecursoCombate) -> bool:
	return espera_restante <= 0.0 and recurso.puede_pagar(coste)


## Daña a todos los enemigos dentro del radio. Devuelve cuántos alcanzó.
func soltar(x: float, recurso: RecursoCombate, enemigos: Array) -> int:
	if not listo(recurso):
		return -1
	recurso.pagar(coste)
	espera_restante = espera
	var alcanzados := 0
	for e: Enemigo in enemigos:
		if e.esta_vivo() and absf(e.position.x - x) <= radio:
			e.recibir_dano(dano)
			alcanzados += 1
	return alcanzados
