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


## Una estrategia razonable: peso pesado, francotirador y tiradores
## (las unidades eligen solas el carril), apoyo si la base sufre, luchadores de
## relleno, el explosivo sobre los grupos y el general cuando se puede.
func _jugar_mixto() -> void:
	if batalla.comandante_listo():
		batalla.usar_comandante()
	# El explosivo solo si sobra para el general, o ante un grupo grande.
	if batalla.poder.listo(batalla.recurso_combate):
		var objetivo := _mejor_grupo()
		var sobra := batalla.recurso_combate.actual >= batalla.poder.coste + batalla.comandante.coste
		if objetivo.y >= 0 and (sobra or _cuenta_grupo >= 5):
			batalla.soltar_poder(objetivo.x, int(objetivo.y))
	var carril := batalla.carril_mas_amenazado()
	# Urgencia: enemigos cerca de la base sin nadie que los frene.
	if _urgente(carril):
		for id: String in ["luchador_barato", "tirador", "peso_pesado"]:
			if batalla.invocar(id) != null:
				return
	var prioridad: Array[String] = []
	if batalla.base.fraccion_vida() < 0.85 and _contar("apoyo") == 0:
		prioridad.append("apoyo")
	prioridad.append_array(["peso_pesado", "francotirador", "tirador", "luchador_barato"])
	for id in prioridad:
		if batalla.preparacion_restante[id] <= 0.0:
			batalla.invocar(id)  # Si no alcanza, espera a tenerlo.
			return


## Urgencia: enemigos cerca de la base sin nadie que los frene, o ya en la
## puerta de la base y más que las unidades del carril (rápidos colados).
func _urgente(carril: int) -> bool:
	var en_puerta := 0
	for e: Enemigo in batalla.enemigos_en(carril):
		if e.position.x < 350.0:
			en_puerta += 1
	if en_puerta > batalla.unidades_en(carril).size():
		return true
	if not batalla.unidades_en(carril).is_empty():
		return false
	for e: Enemigo in batalla.enemigos_en(carril):
		if e.position.x < 800.0:
			return true
	return false


func _contar(id: String) -> int:
	var n := 0
	for u: Unidad in batalla.unidades():
		if u.id == id and u.esta_vivo():
			n += 1
	return n


## Posición (x) y carril (y) con más enemigos dentro del radio del poder.
## Devuelve y = -1 si no hay un grupo de al menos tres.
var _cuenta_grupo := 0


func _mejor_grupo() -> Vector2:
	var mejor := Vector2(0, -1)
	var mejor_cuenta := 2
	for c in batalla.suelos.size():
		var enemigos := batalla.enemigos_en(c)
		for e: Enemigo in enemigos:
			var cuenta := 0
			for otro: Enemigo in enemigos:
				if absf(otro.position.x - e.position.x) <= batalla.poder.radio:
					cuenta += 1
			if cuenta > mejor_cuenta:
				mejor = Vector2(e.position.x, c)
				mejor_cuenta = cuenta
	_cuenta_grupo = mejor_cuenta
	return mejor
