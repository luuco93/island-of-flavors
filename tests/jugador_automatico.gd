class_name JugadorAutomatico
extends Node
## Juega una batalla sin manos siguiendo una estrategia fija.
## Sirve para las pruebas de equilibrio sin pantalla.

enum Estrategia { PASIVO, SOLO_LUCHADORES, MIXTO }

var estrategia := Estrategia.SOLO_LUCHADORES
var batalla: Batalla


func _physics_process(_delta: float) -> void:
	if batalla == null or batalla.terminada:
		return
	match estrategia:
		Estrategia.SOLO_LUCHADORES:
			batalla.invocar("luchador_barato")
		Estrategia.MIXTO:
			_jugar_mixto()


## Una estrategia razonable: apoyo si la base sufre, frente con peso pesado,
## francotirador y tiradores detrás, luchadores de relleno, y el explosivo
## sobre los grupos. Ahorra para la primera unidad lista de la lista.
func _jugar_mixto() -> void:
	if batalla.poder.listo(batalla.recurso_combate):
		var x := _centro_del_grupo()
		if not is_nan(x):
			batalla.soltar_poder(x)
	var prioridad: Array[String] = []
	if batalla.base.fraccion_vida() < 0.85 and _contar("apoyo") == 0:
		prioridad.append("apoyo")
	prioridad.append_array(["peso_pesado", "francotirador", "tirador", "luchador_barato"])
	for id in prioridad:
		if batalla.preparacion_restante[id] <= 0.0:
			batalla.invocar(id)  # Si no alcanza, espera a tenerlo.
			return


func _contar(id: String) -> int:
	var n := 0
	for u: Unidad in batalla.unidades():
		if u.id == id and u.esta_vivo():
			n += 1
	return n


## Posición con más enemigos dentro del radio del poder (NAN si hay pocos).
func _centro_del_grupo() -> float:
	var mejor := NAN
	var mejor_cuenta := 2
	for e: Enemigo in batalla.enemigos():
		var cuenta := 0
		for otro: Enemigo in batalla.enemigos():
			if absf(otro.position.x - e.position.x) <= batalla.poder.radio:
				cuenta += 1
		if cuenta > mejor_cuenta:
			mejor = e.position.x
			mejor_cuenta = cuenta
	return mejor
