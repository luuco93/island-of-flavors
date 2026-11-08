class_name Combatiente
extends Node2D
## Comportamiento común de unidades y enemigos: avanzar por el carril,
## buscar el objetivo más cercano (también en los carriles vecinos, y
## cambiarse de carril para alcanzarlo), atacarlo y morir.

signal murio(combatiente: Combatiente)

const DURACION_DESTELLO := 0.12

var id := ""
var datos: Dictionary = {}
var batalla: Batalla

var vida_maxima := 1.0
var vida := 1.0
var dano := 0.0
var intervalo_ataque := 1.0
var alcance := 20.0
var rango_deteccion := 150.0
var velocidad := 0.0
## Carril en el que está (0 arriba). Solo ataca a quien esté en su carril;
## para atacar a alguien de otro carril primero se cambia a ese carril.
var carril := 0
## Carril al que se está moviendo (igual a carril si no cambia).
var carril_destino := 0
## +1 avanza hacia la derecha (unidades), -1 hacia la izquierda (enemigos).
var direccion := 1.0
var tamano := Vector2(26, 46)
var color := Color(0.5, 0.5, 0.5)

## Objetivo actual: un Combatiente o una Estructura.
var objetivo = null
var _espera_ataque := 0.0
var _destello := 0.0
var _destello_hasta := 0.0
var _vivo := true
var _desvio_y := 0.0


func configurar(id_: String, datos_: Dictionary, batalla_: Batalla, carril_: int = 0) -> void:
	id = id_
	carril = carril_
	carril_destino = carril_
	datos = datos_
	batalla = batalla_
	vida_maxima = float(datos.get("vida", 1))
	vida = vida_maxima
	dano = float(datos.get("dano", 0))
	intervalo_ataque = float(datos.get("intervalo_ataque", 1.0))
	alcance = float(datos.get("alcance", 20))
	rango_deteccion = float(datos.get("rango_deteccion", 150))
	velocidad = float(datos.get("velocidad", 0))
	var t: Array = datos.get("tamano", [26, 46])
	tamano = Vector2(t[0], t[1])
	color = Color.from_hsv(0.0, 0.0, float(datos.get("tono", 0.5)))


func esta_vivo() -> bool:
	return _vivo


func radio() -> float:
	return tamano.x / 2.0


func distancia_desde(x: float) -> float:
	return maxf(0.0, absf(x - position.x) - radio())


func _physics_process(delta: float) -> void:
	if not _vivo or batalla == null or batalla.terminada:
		return
	_espera_ataque = maxf(0.0, _espera_ataque - delta)
	if _destello > 0.0:
		_destello = maxf(0.0, _destello - delta)
		if _destello == 0.0:
			queue_redraw()
	actuar(delta)


## Un paso de comportamiento. Las subclases pueden reemplazarlo.
func actuar(delta: float) -> void:
	objetivo = elegir_objetivo()
	if objetivo == null:
		mover(delta)
		return
	# Un objetivo en otro carril: primero hay que llegar a su carril.
	if objetivo is Combatiente and objetivo.carril != carril:
		carril_destino = objetivo.carril
	if carril_destino != carril:
		cambiar_carril(delta)
	var distancia: float = objetivo.distancia_desde(position.x) - radio()
	if distancia <= alcance:
		if carril_destino == carril and _espera_ataque <= 0.0:
			atacar(objetivo)
	else:
		mover(delta)


## Se desplaza en vertical hacia el carril destino.
func cambiar_carril(delta: float) -> void:
	var y_destino: float = batalla.suelos[carril_destino] + _desvio_y
	var paso := batalla.velocidad_cambio_carril * delta
	if absf(y_destino - position.y) <= paso:
		position.y = y_destino
		carril = carril_destino
	else:
		position.y += signf(y_destino - position.y) * paso


## Las subclases devuelven a quién atacar (o hacia quién caminar).
func elegir_objetivo() -> Node2D:
	return null


func mover(delta: float) -> void:
	position.x += direccion * velocidad * delta


func atacar(blanco) -> void:
	blanco.recibir_dano(dano)
	_espera_ataque = intervalo_ataque
	_destello = DURACION_DESTELLO
	_destello_hasta = blanco.position.x - position.x
	queue_redraw()


func recibir_dano(cantidad: float) -> void:
	if not _vivo:
		return
	vida -= cantidad
	queue_redraw()
	if vida <= 0.0:
		morir()


func morir() -> void:
	_vivo = false
	murio.emit(self)
	queue_free()


## El combatiente vivo más cercano de una lista dentro del rango de
## detección. Cada carril de diferencia cuenta como una distancia extra, así
## que prefiere a los de su carril pero ve a los de los carriles vecinos.
func mas_cercano(candidatos: Array) -> Combatiente:
	var mejor: Combatiente = null
	var mejor_distancia := rango_deteccion
	for c: Combatiente in candidatos:
		if not c.esta_vivo():
			continue
		var d := c.distancia_desde(position.x) - radio() \
			+ absi(c.carril_destino - carril) * batalla.coste_cambio_carril
		if d <= mejor_distancia:
			mejor = c
			mejor_distancia = d
	return mejor


func _draw() -> void:
	var rect := Rect2(-tamano.x / 2.0, -tamano.y, tamano.x, tamano.y)
	draw_rect(rect, color)
	draw_rect(rect, Color(0.1, 0.1, 0.1), false, 1.5)
	# Barra de vida.
	var ancho_barra := tamano.x + 6.0
	var y := -tamano.y - 8.0
	draw_rect(Rect2(-ancho_barra / 2.0, y, ancho_barra, 4.0), Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(-ancho_barra / 2.0, y, ancho_barra * clampf(vida / vida_maxima, 0.0, 1.0), 4.0), Color(0.95, 0.95, 0.95))
	# Línea de ataque.
	if _destello > 0.0:
		var altura := -tamano.y * 0.6
		draw_line(Vector2(0, altura), Vector2(_destello_hasta, altura), Color(0.05, 0.05, 0.05), 2.0)
