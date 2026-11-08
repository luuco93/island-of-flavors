class_name Batalla
extends Node2D
## Una misión en un carril: base a la izquierda, obstáculo a la derecha.
## Lleva el tiempo, los dos recursos, el mazo y las condiciones de fin.

signal unidad_invocada(unidad: Unidad)
signal fase_cambiada(fase: Fase)
signal terminada_con(victoria: bool, estrellas: int)

enum Fase { NORMAL, AVISO, HORDA }

@export var mision_id := "mision_01"
## Semilla del azar (solo afecta a la posición vertical de cada combatiente).
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

var _azar := RandomNumberGenerator.new()


func _ready() -> void:
	_azar.seed = semilla
	reglas = Datos.reglas
	var carril: Dictionary = reglas.carril
	var suelo := float(carril.suelo_y)
	base.position = Vector2(carril.base_x, suelo)
	obstaculo.position = Vector2(carril.obstaculo_x, suelo)
	punto_aparicion.position = Vector2(carril.aparicion_enemigos_x, suelo)

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

	generador.configurar(Datos.mision(mision_id), inicio_horda())
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


func invocar(id: String) -> Unidad:
	if not puede_invocar(id):
		return null
	recurso_despliegue.pagar(coste_de(id))
	preparacion_restante[id] = preparacion_de(id)
	var unidad := Unidad.new()
	unidad.configurar(id, Datos.unidad(id), self)
	var carril: Dictionary = reglas.carril
	unidad.position = Vector2(carril.aparicion_unidades_x, float(carril.suelo_y) + _desvio_y())
	capa_unidades.add_child(unidad)
	unidades_invocadas += 1
	unidad_invocada.emit(unidad)
	return unidad


# --- Enemigos y poderes -----------------------------------------------------

func _aparecer_enemigo(tipo: String, desfase: float) -> void:
	var enemigo := Enemigo.new()
	enemigo.configurar(tipo, Datos.enemigo(tipo), self)
	enemigo.position = punto_aparicion.position + Vector2(desfase, _desvio_y())
	enemigo.murio.connect(_on_enemigo_murio)
	capa_enemigos.add_child(enemigo)


func _on_enemigo_murio(enemigo: Combatiente) -> void:
	bajas_enemigas += 1
	recurso_combate.sumar((enemigo as Enemigo).recurso_combate)


func soltar_poder(x: float) -> bool:
	if terminada:
		return false
	var alcanzados := poder.soltar(x, recurso_combate, enemigos())
	if alcanzados < 0:
		return false
	var efecto := EfectoArea.new()
	efecto.radio = poder.radio
	efecto.position = Vector2(x, float(reglas.carril.suelo_y) - 20.0)
	capa_efectos.add_child(efecto)
	return true


func unidades() -> Array:
	return capa_unidades.get_children()


func enemigos() -> Array:
	return capa_enemigos.get_children()


func _desvio_y() -> float:
	var d := float(reglas.carril.dispersion_y)
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
