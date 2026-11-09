extends Node
## Textos que ve el jugador, separados del código.
##
## El código pide textos por clave (por ejemplo "unidad.tirador") y este
## archivo los busca en res://textos/<idioma>.json. Así se puede re-tematizar
## el juego cambiando solo ese archivo.

const RUTA := "res://textos/%s.json"

var idioma := "es"
var _textos: Dictionary = {}


func _init() -> void:
	cargar(idioma)


func cargar(codigo: String) -> void:
	idioma = codigo
	_textos = LectorJson.leer(RUTA % codigo)


## Devuelve el texto de una clave. Los valores sustituyen {marcadores}.
func t(clave: String, valores: Dictionary = {}) -> String:
	var texto: String = _textos.get(clave, clave)
	return texto.format(valores) if not valores.is_empty() else texto
