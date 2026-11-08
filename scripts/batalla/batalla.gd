class_name Batalla
extends Node2D
## Una misión en tres carriles: base a la izquierda, obstáculo a la derecha,
## ambos cubren todos los carriles. Lleva el tiempo, los dos recursos, el
## mazo, el carril elegido, el comandante y las condiciones de fin.

signal unidad_invocada(unidad: Unidad)
signal fase_cambiada(fase: Fase)
signal carril_cambiado(carril: int)
signal terminada_con(victoria: bool, estrellas: int)

enum Fase { NORMAL, AVISO, HORDA }

@export var mision_id := "mision_01"
## Semilla del azar (carril de las oleadas y posición vertical).
@export var semilla := 1

@onready var base: Base = $Base
@onready var obstaculo: Obstaculo = $Obstaculo
@onready var punto_aparicion: Marker2D = $PuntoAparicion
@onready var capa_unidades: Node2D = $Unidades
@onready var capa_enemigos: Node2D = $Enemigos
@onready var capa_efectos: Node2D = $Efectos
@onready var recurso_despliegue: RecursoDespliegue = $RecursoDespliegue
@onready var recurso_combate: RecursoCombate = $RecursoCombate
@onready var generador: GeneradorEnemigos = $GeneradorEnemigos
@onready var poder: PoderCombate = $PoderCombate
@onready var comandante: Comandante = $Comandante
@onready var carriles: Carriles = $Carriles

var reglas: Dictionary = {}
var mazo: Array[String] = []
## Segundos que faltan para poder volver a invocar cada unidad del mazo.
var preparacion_restante: Dictionary = {}
var tiempo := 0.0
var fase := Fase.NORMAL
var terminada := false
var victoria := false
var estrellas := 0
var unidades_invocadas := 0
var bajas_enemigas := 0
var usos_comandante := 0
## Altura del suelo de cada carril (0 arriba).
var suelos: Array[float] = []
var alto_carril := 120.0
## Carril donde aparecen las unidades que se invocan.
var carril_elegido := 1

var _azar := RandomNumberGenerator.new()


func _ready() -> void:
	_azar.seed = semilla
	reglas = Datos.reglas
	var campo: Dictionary = reglas.campo
	for y in campo.suelos_y:
		suelos.append(float(y))
	alto_carril = float(campo.alto_carril)
	carril_elegido = int(campo.carril_inicial)
	var fondo := suelos[-1] + 10.0
	var alto_total := fondo - (suelos[0] - alto_carril) + 20.0
	base.position = Vector2(campo.base_x, fondo)
	base.alto = alto_total
	obstaculo.position = Vector2(campo.obstaculo_x, fondo)
	obstaculo.alto = alto_total
	punto_aparicion.position = Vector2(campo.aparicion_enemigos_x, 0)
	comandante.position = Vector2(campo.base_x, fondo - alto_total)
	var id_comandante: String = reglas.comandante
	comandante.configurar(id_comandante, Datos.comandante(id_comandante))
	carriles.batalla = self
	carriles.queue_redraw()

	base.configurar(reglas.vida_base)
	obstaculo.configurar(reglas.vida_obstaculo)
	base.destruida.connect(_terminar.bind(false))
	obstaculo.destruida.connect(_terminar.bind(true))

	var rd: Dictionary = reglas.recurso_despliegue
	recurso_despliegue.recarga_por_segundo = rd.recarga_por_segundo
	recurso_despliegue.configurar(rd.inicial, rd.maximo)
	var rc: Dictionary = reglas.recurso_combate
	recurso_combate.configurar(rc.inicial, rc.maximo)

	for id: String in reglas.mazo_inicial:
		if mazo.size() < int(reglas.tamano_mazo):
			mazo.append(id)
			preparacion_restante[id] = 0.0

	var id_poder: String = reglas.poderes_iniciales[0]
	poder.configurar(id_poder, Datos.poder(id_poder))

	generador.configurar(Datos.mision(mision_id), inicio_horda(), suelos.size(), _azar)
	generador.pidio_enemigo.connect(_aparecer_enemigo)


func _physics_process(delta: float) -> void:
	if terminada:
		return
	tiempo += delta
	recurso_despliegue.avanzar(delta)
	poder.avanzar(delta)
	for id: String in preparacion_restante:
		preparacion_restante[id] = maxf(0.0, preparacion_restante[id] - delta)
	if obstaculo.esta_vivo():
		generador.avanzar(tiempo)
	_actualizar_fase()


# --- Tiempo -----------------------------------------------------------------

func inicio_aviso() -> float:
	return float(reglas.limite_tiempo)


func inicio_horda() -> float:
	return float(reglas.limite_tiempo) + float(reglas.aviso_horda)


## Segundos hasta la horda (negativo cuando ya llegó).
func tiempo_hasta_horda() -> float:
	return inicio_horda() - tiempo


func _actualizar_fase() -> void:
	var nueva := Fase.NORMAL
	if tiempo >= inicio_horda():
		nueva = Fase.HORDA
	elif tiempo >= inicio_aviso():
		nueva = Fase.AVISO
	if nueva != fase:
		fase = nueva
		fase_cambiada.emit(fase)


# --- Mazo -------------------------------------------------------------------

func coste_de(id: String) -> float:
	return float(Datos.unidad(id).coste)


func preparacion_de(id: String) -> float:
	return float(Datos.unidad(id).preparacion)


func puede_invocar(id: String) -> bool:
	return (not terminada
		and mazo.has(id)
		and preparacion_restante.get(id, 0.0) <= 0.0
		and recurso_despliegue.puede_pagar(coste_de(id)))


func elegir_carril(carril: int) -> void:
	carril = clampi(carril, 0, suelos.size() - 1)
	if carril != carril_elegido:
		carril_elegido = carril
		carriles.queue_redraw()
		carril_cambiado.emit(carril)


## El carril bajo una altura de pantalla, o -1 si no hay ninguno.
func carril_en(y: float) -> int:
	for i in suelos.size():
		if y <= suelos[i] + 20.0 and y >= suelos[i] - alto_carril + 20.0:
			return i
	return -1


## Invoca en el carril indicado, o en el elegido si no se indica.
func invocar(id: String, carril: int = -1) -> Unidad:
	if not puede_invocar(id):
		return null
	if carril < 0:
		carril = carril_elegido
	recurso_despliegue.pagar(coste_de(id))
	preparacion_restante[id] = preparacion_de(id)
	var unidad := Unidad.new()
	unidad.configurar(id, Datos.unidad(id), self, carril)
	unidad.position = Vector2(reglas.campo.aparicion_unidades_x, suelos[carril] + _desvio_y())
	capa_unidades.add_child(unidad)
	unidades_invocadas += 1
	unidad_invocada.emit(unidad)
	return unidad


# --- Enemigos y poderes -----------------------------------------------------

func _aparecer_enemigo(tipo: String, carril: int, desfase: float) -> void:
	var enemigo := Enemigo.new()
	enemigo.configurar(tipo, Datos.enemigo(tipo), self, carril)
	enemigo.position = Vector2(punto_aparicion.position.x + desfase, suelos[carril] + _desvio_y())
	enemigo.murio.connect(_on_enemigo_murio)
	capa_enemigos.add_child(enemigo)


func _on_enemigo_murio(enemigo: Combatiente) -> void:
	bajas_enemigas += 1
	recurso_combate.sumar((enemigo as Enemigo).recurso_combate)


## Suelta el poder de combate en un punto de un carril.
func soltar_poder(x: float, carril: int) -> bool:
	if terminada or carril < 0:
		return false
	var alcanzados := poder.soltar(x, recurso_combate, enemigos_en(carril))
	if alcanzados < 0:
		return false
	_efecto_area(x, carril, poder.radio)
	return true


func comandante_listo() -> bool:
	return not terminada and comandante.listo(recurso_combate)


## Habilidad activa del comandante.
func usar_comandante() -> bool:
	if terminada:
		return false
	var limite := obstaculo.position.x - obstaculo.ancho / 2.0
	if comandante.usar(recurso_combate, enemigos(), limite) < 0:
		return false
	usos_comandante += 1
	return true


## Un enemigo que explota al morir daña a las unidades cercanas de su carril.
func explosion_enemiga(x: float, carril: int, dano: float, radio: float) -> void:
	for u: Unidad in unidades_en(carril):
		if u.esta_vivo() and absf(u.position.x - x) <= radio:
			u.recibir_dano(dano)
	_efecto_area(x, carril, radio)


func _efecto_area(x: float, carril: int, radio: float) -> void:
	var efecto := EfectoArea.new()
	efecto.radio = radio
	efecto.position = Vector2(x, suelos[carril] - 20.0)
	capa_efectos.add_child(efecto)


func unidades() -> Array:
	return capa_unidades.get_children()


func enemigos() -> Array:
	return capa_enemigos.get_children()


func unidades_en(carril: int) -> Array:
	return unidades().filter(func(u: Unidad) -> bool: return u.carril == carril)


func enemigos_en(carril: int) -> Array:
	return enemigos().filter(func(e: Enemigo) -> bool: return e.carril == carril)


func _unhandled_input(evento: InputEvent) -> void:
	# Tocar un carril lo elige para las próximas invocaciones.
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		var punto: Vector2 = get_canvas_transform().affine_inverse() * evento.position
		var c := carril_en(punto.y)
		if c >= 0:
			elegir_carril(c)


func _desvio_y() -> float:
	var d := float(reglas.campo.dispersion_y)
	return _azar.randf_range(-d, d)


# --- Fin --------------------------------------------------------------------

static func estrellas_para(fraccion_vida: float, umbrales: Dictionary) -> int:
	if fraccion_vida <= 0.0:
		return 0
	if fraccion_vida >= float(umbrales.tres):
		return 3
	if fraccion_vida >= float(umbrales.dos):
		return 2
	return 1


func _terminar(gano: bool) -> void:
	if terminada:
		return
	terminada = true
	victoria = gano
	estrellas = estrellas_para(base.fraccion_vida(), reglas.estrellas) if gano else 0
	terminada_con.emit(victoria, estrellas)
