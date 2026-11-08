class_name Hud
extends CanvasLayer
## Interfaz de la batalla: vidas, tiempo, recursos, mazo, poder de combate y
## habilidad del comandante.
## Se construye por código para que el prototipo gris sea fácil de cambiar.

@onready var batalla: Batalla = get_parent()

var _raiz := Control.new()
var _barra_base := ProgressBar.new()
var _barra_obstaculo := ProgressBar.new()
var _reloj := Label.new()
var _aviso := Label.new()
var _texto_despliegue := Label.new()
var _barra_despliegue := ProgressBar.new()
var _texto_combate := Label.new()
var _barra_combate := ProgressBar.new()
var _boton_poder := Button.new()
var _cortina_poder := ColorRect.new()
var _boton_comandante := Button.new()
var _zona_apuntado := Control.new()
var _pantalla_fin := PantallaFin.new()
var _apuntando := false


func _ready() -> void:
	# El HUD es hijo de la batalla: espera a que la batalla esté configurada.
	if not batalla.is_node_ready():
		await batalla.ready
	_raiz.set_anchors_preset(Control.PRESET_FULL_RECT)
	_raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tema := Theme.new()
	tema.default_font_size = 22
	tema.set_stylebox("background", "ProgressBar", _caja(Color(0.62, 0.62, 0.62)))
	tema.set_stylebox("fill", "ProgressBar", _caja(Color(0.22, 0.22, 0.22)))
	tema.set_color("font_color", "Label", Color(0.1, 0.1, 0.1))
	_raiz.theme = tema
	add_child(_raiz)

	# Zona invisible que recoge el toque en el carril al soltar un poder.
	_zona_apuntado.set_anchors_preset(Control.PRESET_FULL_RECT)
	_zona_apuntado.visible = false
	_zona_apuntado.gui_input.connect(_on_toque_carril)
	_raiz.add_child(_zona_apuntado)

	_construir_barra_superior()
	_construir_panel_inferior()

	_aviso.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_aviso.position.y = 90
	_aviso.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_aviso.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_aviso.add_theme_font_size_override("font_size", 34)
	_aviso.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(_aviso)

	_pantalla_fin.set_anchors_preset(Control.PRESET_CENTER)
	_pantalla_fin.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_pantalla_fin.grow_vertical = Control.GROW_DIRECTION_BOTH
	_raiz.add_child(_pantalla_fin)

	batalla.base.vida_cambiada.connect(_actualizar_barra.bind(_barra_base))
	batalla.obstaculo.vida_cambiada.connect(_actualizar_barra.bind(_barra_obstaculo))
	batalla.recurso_despliegue.cambiado.connect(_on_despliegue)
	batalla.recurso_combate.cambiado.connect(_on_combate)
	batalla.terminada_con.connect(_on_terminada)
	_actualizar_barra(batalla.base.vida, batalla.base.vida_maxima, _barra_base)
	_actualizar_barra(batalla.obstaculo.vida, batalla.obstaculo.vida_maxima, _barra_obstaculo)
	_on_despliegue(batalla.recurso_despliegue.actual, batalla.recurso_despliegue.maximo)
	_on_combate(batalla.recurso_combate.actual, batalla.recurso_combate.maximo)


func _caja(color: Color) -> StyleBoxFlat:
	var caja := StyleBoxFlat.new()
	caja.bg_color = color
	caja.set_corner_radius_all(4)
	return caja


func _construir_barra_superior() -> void:
	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_TOP_WIDE)
	for lado in ["left", "right", "top"]:
		margen.add_theme_constant_override("margin_" + lado, 16)
	margen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_raiz.add_child(margen)
	var fila := HBoxContainer.new()
	margen.add_child(fila)
	fila.add_child(_bloque_vida(Textos.t("base"), _barra_base))
	_reloj.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reloj.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_reloj.add_theme_font_size_override("font_size", 32)
	fila.add_child(_reloj)
	fila.add_child(_bloque_vida(Textos.t("obstaculo"), _barra_obstaculo))


func _bloque_vida(titulo: String, barra: ProgressBar) -> Control:
	var caja := VBoxContainer.new()
	var etiqueta := Label.new()
	etiqueta.text = titulo
	caja.add_child(etiqueta)
	barra.custom_minimum_size = Vector2(300, 22)
	barra.show_percentage = false
	caja.add_child(barra)
	return caja


func _construir_panel_inferior() -> void:
	var margen := MarginContainer.new()
	margen.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	margen.grow_vertical = Control.GROW_DIRECTION_BEGIN
	for lado in ["left", "right", "bottom"]:
		margen.add_theme_constant_override("margin_" + lado, 16)
	_raiz.add_child(margen)
	var columnas := HBoxContainer.new()
	columnas.add_theme_constant_override("separation", 24)
	margen.add_child(columnas)

	# Recurso de despliegue y mazo.
	var izquierda := VBoxContainer.new()
	izquierda.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columnas.add_child(izquierda)
	izquierda.add_child(_texto_despliegue)
	_barra_despliegue.show_percentage = false
	_barra_despliegue.custom_minimum_size.y = 18
	izquierda.add_child(_barra_despliegue)
	var fila_mazo := HBoxContainer.new()
	fila_mazo.add_theme_constant_override("separation", 8)
	izquierda.add_child(fila_mazo)
	for i in int(batalla.reglas.tamano_mazo):
		var boton := BotonUnidad.new()
		boton.configurar(batalla.mazo[i] if i < batalla.mazo.size() else "", batalla)
		fila_mazo.add_child(boton)

	# Recurso de combate, poder y habilidad del comandante.
	var derecha := VBoxContainer.new()
	derecha.custom_minimum_size.x = 300
	columnas.add_child(derecha)
	derecha.add_child(_texto_combate)
	_barra_combate.show_percentage = false
	_barra_combate.custom_minimum_size.y = 18
	derecha.add_child(_barra_combate)
	var fila_poderes := HBoxContainer.new()
	fila_poderes.add_theme_constant_override("separation", 8)
	derecha.add_child(fila_poderes)
	_boton_poder.custom_minimum_size = Vector2(140, 96)
	_boton_poder.focus_mode = Control.FOCUS_NONE
	_boton_poder.clip_contents = true
	_boton_poder.text = "%s\n%d" % [Textos.t("poder." + batalla.poder.id), int(batalla.poder.coste)]
	_boton_poder.pressed.connect(_on_boton_poder)
	_cortina_poder.color = Color(0, 0, 0, 0.55)
	_cortina_poder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_boton_poder.add_child(_cortina_poder)
	fila_poderes.add_child(_boton_poder)
	var comandante := batalla.comandante
	_boton_comandante.custom_minimum_size = Vector2(152, 96)
	_boton_comandante.focus_mode = Control.FOCUS_NONE
	_boton_comandante.text = "%s\n%s %d" % [Textos.t("comandante." + comandante.id),
		Textos.t("habilidad." + comandante.habilidad), int(comandante.coste)]
	_boton_comandante.pressed.connect(func() -> void: batalla.usar_comandante())
	fila_poderes.add_child(_boton_comandante)


func _process(_delta: float) -> void:
	if not batalla.is_node_ready():
		return
	_reloj.text = _formato_tiempo(maxf(0.0, batalla.inicio_aviso() - batalla.tiempo))
	match batalla.fase:
		Batalla.Fase.AVISO:
			_aviso.text = Textos.t("aviso.horda", {"segundos": ceili(batalla.tiempo_hasta_horda())})
		Batalla.Fase.HORDA:
			_aviso.text = Textos.t("aviso.horda_llego")
		_:
			_aviso.text = ""
	if _apuntando:
		_aviso.text = Textos.t("poder.apuntar", {"nombre": Textos.t("poder." + batalla.poder.id).to_lower()})
	elif batalla.tiempo < 6.0 and _aviso.text.is_empty():
		_aviso.text = Textos.t("carril.elegir")
	_boton_comandante.disabled = not batalla.comandante_listo()

	var poder := batalla.poder
	_boton_poder.disabled = not poder.listo(batalla.recurso_combate) or batalla.terminada
	if _boton_poder.disabled and _apuntando:
		_cancelar_apuntado()
	_cortina_poder.size = Vector2(_boton_poder.size.x, _boton_poder.size.y * poder.espera_restante / poder.espera)


func _formato_tiempo(segundos: float) -> String:
	var s := ceili(segundos)
	return "%d:%02d" % [s / 60, s % 60]


func _actualizar_barra(actual: float, maxima: float, barra: ProgressBar) -> void:
	barra.max_value = maxima
	barra.value = actual


func _on_despliegue(actual: float, maximo: float) -> void:
	_barra_despliegue.max_value = maximo
	_barra_despliegue.value = actual
	_texto_despliegue.text = "%s %d / %d" % [Textos.t("recurso_despliegue"), floori(actual), int(maximo)]


func _on_combate(actual: float, maximo: float) -> void:
	_barra_combate.max_value = maximo
	_barra_combate.value = actual
	_texto_combate.text = "%s %d / %d" % [Textos.t("recurso_combate"), floori(actual), int(maximo)]


func _on_boton_poder() -> void:
	if _apuntando:
		_cancelar_apuntado()
	else:
		_apuntando = true
		_zona_apuntado.visible = true


func _cancelar_apuntado() -> void:
	_apuntando = false
	_zona_apuntado.visible = false


func _on_toque_carril(evento: InputEvent) -> void:
	if evento is InputEventMouseButton and evento.pressed and evento.button_index == MOUSE_BUTTON_LEFT:
		var punto: Vector2 = batalla.get_canvas_transform().affine_inverse() * evento.global_position
		var carril := batalla.carril_en(punto.y)
		if carril < 0:
			return  # Fuera de los carriles: sigue apuntando.
		batalla.soltar_poder(punto.x, carril)
		_cancelar_apuntado()


func _on_terminada(victoria: bool, estrellas: int) -> void:
	_cancelar_apuntado()
	_pantalla_fin.mostrar(victoria, estrellas, batalla.base.fraccion_vida())
