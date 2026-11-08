class_name PantallaFin
extends PanelContainer
## Resultado de la misión: victoria o derrota, estrellas y vida de la base.

var _titulo := Label.new()
var _estrellas := Label.new()
var _vida := Label.new()
var _reintentar := Button.new()


func _ready() -> void:
	visible = false
	var caja := VBoxContainer.new()
	caja.add_theme_constant_override("separation", 16)
	add_child(caja)
	for etiqueta: Label in [_titulo, _estrellas, _vida]:
		etiqueta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caja.add_child(etiqueta)
	_titulo.add_theme_font_size_override("font_size", 48)
	_estrellas.add_theme_font_size_override("font_size", 56)
	_reintentar.text = Textos.t("fin.reintentar")
	_reintentar.custom_minimum_size = Vector2(240, 64)
	_reintentar.pressed.connect(func() -> void: get_tree().reload_current_scene())
	caja.add_child(_reintentar)


func mostrar(victoria: bool, estrellas: int, fraccion_vida_base: float) -> void:
	_titulo.text = Textos.t("fin.victoria" if victoria else "fin.derrota")
	_estrellas.text = "★".repeat(estrellas) + "☆".repeat(3 - estrellas)
	_vida.text = Textos.t("fin.vida_base", {"porcentaje": roundi(fraccion_vida_base * 100.0)})
	visible = true
