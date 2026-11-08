class_name Unidad
extends Combatiente
## Unidad del jugador. Avanza hacia el obstáculo y ataca al enemigo más
## cercano que detecte por el camino.

var comportamiento := "combate"
var reparacion_por_segundo := 0.0


func configurar(id_: String, datos_: Dictionary, batalla_: Batalla) -> void:
	super(id_, datos_, batalla_)
	direccion = 1.0
	comportamiento = datos.get("comportamiento", "combate")
	reparacion_por_segundo = float(datos.get("reparacion_por_segundo", 0))


func actuar(delta: float) -> void:
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
