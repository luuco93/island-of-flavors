class_name Enemigo
extends Combatiente
## Enemigo. Avanza hacia la base por su carril y ataca a la unidad más
## cercana que detecte. Algunos tipos explotan al morir y el rápido no se
## detiene ante las unidades.

var recurso_combate := 1.0
var marca := "diagonal"
## Si es true no se detiene ante las unidades: va directo a la base
## (las unidades sí pueden atacarlo mientras pasa).
var ignora_unidades := false


func configurar(id_: String, datos_: Dictionary, batalla_: Batalla, carril_: int = 0) -> void:
	super(id_, datos_, batalla_, carril_)
	direccion = -1.0
	recurso_combate = float(datos.get("recurso_combate", 1))
	marca = datos.get("marca", "diagonal")
	ignora_unidades = bool(datos.get("ignora_unidades", false))


func elegir_objetivo() -> Node2D:
	if ignora_unidades:
		return batalla.base if batalla.base.esta_vivo() else null
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
