class_name BotonUnidad
extends Button
## Botón del mazo: muestra la carta (si la unidad tiene), nombre y coste,
## y se tapa mientras la unidad se prepara. Con id vacío es un hueco libre.

var id := ""
var batalla: Batalla
var _cortina := ColorRect.new()
var _carta: TextureRect = null


func configurar(id_: String, batalla_: Batalla) -> void:
	id = id_
	batalla = batalla_
	custom_minimum_size = Vector2(120, 96)
	focus_mode = Control.FOCUS_NONE
	clip_contents = true
	if id.is_empty():
		text = Textos.t("mazo.vacio")
		disabled = true
		_agregar_cortina()
		return
	var texto := "%s\n%d" % [Textos.t("unidad." + id), int(batalla.coste_de(id))]
	var ruta_carta: String = Datos.unidad(id).get("carta", "")
	var textura: Texture2D = load(ruta_carta) if not ruta_carta.is_empty() else null
	if textura == null:
		text = texto
	else:
		_agregar_carta(textura, texto)
	_agregar_cortina()
	pressed.connect(func() -> void: batalla.invocar(id))


## Dibujo de la carta a todo el botón, con nombre y coste en una franja abajo.
func _agregar_carta(textura: Texture2D, texto: String) -> void:
	_carta = TextureRect.new()
	_carta.texture = textura
	_carta.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_carta.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_carta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_carta.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_MINSIZE, 3)
	add_child(_carta)
	var franja := Label.new()
	franja.text = texto.replace("\n", "  ")
	franja.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	franja.mouse_filter = Control.MOUSE_FILTER_IGNORE
	franja.add_theme_font_size_override("font_size", 14)
	franja.add_theme_color_override("font_color", Color.WHITE)
	var fondo := StyleBoxFlat.new()
	fondo.bg_color = Color(0, 0, 0, 0.6)
	franja.add_theme_stylebox_override("normal", fondo)
	franja.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	add_child(franja)


func _agregar_cortina() -> void:
	_cortina.color = Color(0, 0, 0, 0.55)
	_cortina.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cortina.size = Vector2.ZERO
	add_child(_cortina)


func _process(_delta: float) -> void:
	if id.is_empty() or batalla == null:
		return
	disabled = not batalla.puede_invocar(id)
	if _carta != null:
		_carta.modulate = Color(0.6, 0.6, 0.6) if disabled else Color.WHITE
	var fraccion: float = batalla.preparacion_restante.get(id, 0.0) / batalla.preparacion_de(id)
	_cortina.position = Vector2.ZERO
	_cortina.size = Vector2(size.x, size.y * fraccion)
