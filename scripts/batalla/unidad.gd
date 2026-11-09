class_name Unidad
extends Combatiente
## Unidad del jugador. Avanza hacia el obstáculo y ataca al enemigo más
## cercano que detecte por el camino.

var comportamiento := "combate"
var reparacion_por_segundo := 0.0
## Al salir por la puerta de la base va primero a este carril; mientras
## tanto no se distrae con objetivos.
var carril_asignado := 0
var saliendo := false


func configurar(id_: String, datos_: Dictionary, batalla_: Batalla, carril_: int = 0) -> void:
	super(id_, datos_, batalla_, carril_)
	direccion = 1.0
	comportamiento = datos.get("comportamiento", "combate")
	reparacion_por_segundo = float(datos.get("reparacion_por_segundo", 0))


## Empieza en la puerta y se abre hacia su carril.
func salir_por_puerta(carril_puerta: int, carril_final: int) -> void:
	carril = carril_puerta
	carril_destino = carril_final
	carril_asignado = carril_final
	saliendo = carril_puerta != carril_final


func actuar(delta: float) -> void:
	if saliendo:
		carril_destino = carril_asignado
		cambiar_carril(delta, batalla.velocidad_salida_puerta)
		if comportamiento != "reparar_base":
			mover(delta)
		saliendo = carril != carril_asignado
		return
	match comportamiento:
		"reparar_base":
			# El apoyo se queda junto a la base y la repara mientras viva.
			batalla.base.reparar(reparacion_por_segundo * delta)
		_:
			super(delta)


func elegir_objetivo() -> Node2D:
	var enemigo := mas_cercano(batalla.enemigos())
	if enemigo != null:
		return enemigo
	if batalla.obstaculo.esta_vivo():
		return batalla.obstaculo
	return null
