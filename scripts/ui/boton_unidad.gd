class_name BotonUnidad
extends Button
## Botón del mazo: muestra nombre y coste, y se tapa mientras la unidad
## se prepara. Con id vacío es un hueco libre del mazo.

var id := ""
var batalla: Batalla
var _cortina := ColorRect.new()


func configurar(id_: String, batalla_: Batalla) -> void:
	id = id_
	batalla = batalla_
	custom_minimum_size = Vector2(120, 96)
	focus_mode = Control.FOCUS_NONE
	clip_contents = true
	_cortina.color = Color(0, 0, 0, 0.55)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.size = Vector2.ZERO
	add_child(_cortina)
	if id.is_empty():
		text = Textos.t("mazo.vacio")
		disabled = true
		return
	text = "%s\n%d" % [Textos.t("unidad." + id), int(batalla.coste_de(id))]
	pressed.connect(func() -> void: batalla.invocar(id))


func _process(_delta: float) -> void:
	if id.is_empty() or batalla == null:
		return
	disabled = not batalla.puede_invocar(id)
	var fraccion: float = batalla.preparacion_restante.get(id, 0.0) / batalla.preparacion_de(id)
	_cortina.position = Vector2.ZERO
	_cortina.size = Vector2(size.x, size.y * fraccion)
