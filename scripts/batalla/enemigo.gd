class_name Enemigo
extends Combatiente
## Enemigo. Avanza hacia la base por su carril y ataca a la unidad más
## cercana que detecte. Algunos tipos explotan al morir.

var recurso_combate := 1.0
var marca := "diagonal"


func configurar(id_: String, datos_: Dictionary, batalla_: Batalla, carril_: int = 0) -> void:
	super(id_, datos_, batalla_, carril_)
	direccion = -1.0
	recurso_combate = float(datos.get("recurso_combate", 1))
	marca = datos.get("marca", "diagonal")


func elegir_objetivo() -> Node2D:
	var unidad := mas_cercano(batalla.unidades())
	if unidad != null:
		return unidad
	if batalla.base.esta_vivo():
		return batalla.base
	return null


func morir() -> void:
	var explosion: Dictionary = datos.get("explota_al_morir", {})
	if not explosion.is_empty():
		batalla.explosion_enemiga(position.x, carril, float(explosion.dano), float(explosion.radio))
	super()


func _draw() -> void:
	super()
	# Marcas para distinguir tipos de enemigo sin usar color.
	var claro := Color(0.9, 0.9, 0.9)
	var w := tamano.x / 2.0
	var h := tamano.y
	match marca:
		"diagonal":
			draw_line(Vector2(-w, -h), Vector2(w, 0), claro, 1.5)
		"doble":
			draw_line(Vector2(-w, -h), Vector2(w, 0), claro, 1.5)
			draw_line(Vector2(w, -h), Vector2(-w, 0), claro, 1.5)
		"flecha":
			draw_polyline([Vector2(w * 0.4, -h * 0.75), Vector2(-w * 0.6, -h * 0.5), Vector2(w * 0.4, -h * 0.25)], claro, 2.0)
		"mira":
			draw_arc(Vector2(0, -h * 0.55), w * 0.6, 0, TAU, 16, claro, 1.5)
			draw_line(Vector2(-w, -h * 0.55), Vector2(w, -h * 0.55), claro, 1.0)
		"circulo":
			draw_circle(Vector2(0, -h * 0.5), w * 0.55, claro)
