class_name Enemigo
extends Combatiente
## Enemigo. Avanza hacia la base y ataca a la unidad más cercana que detecte.

var recurso_combate := 1.0


func configurar(id_: String, datos_: Dictionary, batalla_: Batalla) -> void:
	super(id_, datos_, batalla_)
	direccion = -1.0
	recurso_combate = float(datos.get("recurso_combate", 1))


func elegir_objetivo() -> Node2D:
	var unidad := mas_cercano(batalla.unidades())
	if unidad != null:
		return unidad
	if batalla.base.esta_vivo():
		return batalla.base
	return null


func _draw() -> void:
	super()
	# Marca para distinguir enemigos de unidades sin usar color.
	draw_line(Vector2(-tamano.x / 2.0, -tamano.y), Vector2(tamano.x / 2.0, 0), Color(0.9, 0.9, 0.9), 1.5)
