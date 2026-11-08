class_name LectorJson
## Lee un archivo JSON con un objeto en la raíz.
## Las claves que empiezan por "_" son comentarios y se descartan.


static func leer(ruta: String) -> Dictionary:
	var archivo := FileAccess.open(ruta, FileAccess.READ)
	if archivo == null:
		push_error("No se pudo abrir %s" % ruta)
		return {}
	var contenido: Variant = JSON.parse_string(archivo.get_as_text())
	if not contenido is Dictionary:
		push_error("%s no contiene un objeto JSON" % ruta)
		return {}
	var limpio: Dictionary = {}
	for clave: String in contenido:
		if not clave.begins_with("_"):
			limpio[clave] = contenido[clave]
	return limpio
