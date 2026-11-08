extends Node
## Prueba de equilibrio sin pantalla (paso 16 del plan).
##
## Ejecutar:
##   godot --headless --path . --fixed-fps 60 res://tests/prueba_equilibrio.tscn
##
## Juega la misión con varias estrategias y comprueba:
## - Sin invocar nada se pierde.
## - Solo con luchadores baratos se gana, pero nunca con 3 estrellas.
## La estrategia mixta solo se informa, para ver si 3 estrellas es posible.

const ESCENA_BATALLA := preload("res://escenas/batalla/batalla.tscn")
const SEMILLAS := [1]

var _fallos: Array[String] = []


func _ready() -> void:
	# Las barras y el reloj sobran sin pantalla, pero la escena es la real.
	for estrategia in JugadorAutomatico.Estrategia.values():
		for semilla in SEMILLAS:
			var r := await _jugar(estrategia, semilla)
			_comprobar(estrategia, semilla, r)
	if _fallos.is_empty():
		print("RESULTADO: todas las pruebas pasan")
		get_tree().quit(0)
	else:
		for f in _fallos:
			printerr("FALLO: ", f)
		get_tree().quit(1)


func _jugar(estrategia: int, semilla: int) -> Dictionary:
	var batalla: Batalla = ESCENA_BATALLA.instantiate()
	batalla.semilla = semilla
	add_child(batalla)
	var jugador := JugadorAutomatico.new()
	jugador.estrategia = estrategia
	jugador.batalla = batalla
	batalla.add_child(jugador)
	var limite := 400.0  # segundos de juego, por si nadie gana
	while not batalla.terminada and batalla.tiempo < limite:
		await get_tree().physics_frame
	var r := {
		"terminada": batalla.terminada,
		"victoria": batalla.victoria,
		"estrellas": batalla.estrellas,
		"tiempo": batalla.tiempo,
		"vida_base": batalla.base.fraccion_vida(),
		"vida_obstaculo": batalla.obstaculo.fraccion_vida(),
		"unidades": batalla.unidades_invocadas,
		"bajas": batalla.bajas_enemigas,
	}
	print("%-16s semilla %d -> %s, %d estrellas, %.0f s, base %d %%, obstáculo %d %%, %d unidades, %d bajas" % [
		JugadorAutomatico.Estrategia.keys()[estrategia], semilla,
		"victoria" if r.victoria else ("derrota" if r.terminada else "sin terminar"),
		r.estrellas, r.tiempo, roundi(r.vida_base * 100), roundi(r.vida_obstaculo * 100),
		r.unidades, r.bajas])
	batalla.queue_free()
	await get_tree().process_frame
	return r


func _comprobar(estrategia: int, semilla: int, r: Dictionary) -> void:
	var nombre := "%s/semilla %d" % [JugadorAutomatico.Estrategia.keys()[estrategia], semilla]
	match estrategia:
		JugadorAutomatico.Estrategia.PASIVO:
			if r.victoria or not r.terminada:
				_fallos.append("%s: sin invocar nada debería perder" % nombre)
		JugadorAutomatico.Estrategia.SOLO_LUCHADORES:
			if not r.victoria:
				_fallos.append("%s: solo con luchadores baratos se debería poder ganar" % nombre)
			elif r.estrellas >= 3:
				_fallos.append("%s: solo con luchadores baratos no debería sacar 3 estrellas" % nombre)
