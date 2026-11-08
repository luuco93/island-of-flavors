extends Node
## Tablas de datos del juego (todas las cifras de equilibrio).
##
## Las cifras viven en res://datos/*.json para poder ajustarlas sin tocar el
## código.

const RUTA := "res://datos/"

var reglas: Dictionary = {}
var unidades: Dictionary = {}
var enemigos: Dictionary = {}
var poderes: Dictionary = {}
var comandantes: Dictionary = {}


func _init() -> void:
	cargar()


func cargar() -> void:
	reglas = LectorJson.leer(RUTA + "reglas.json")
	unidades = LectorJson.leer(RUTA + "unidades.json")
	enemigos = LectorJson.leer(RUTA + "enemigos.json")
	poderes = LectorJson.leer(RUTA + "poderes.json")
	comandantes = LectorJson.leer(RUTA + "comandante.json")


func mision(id: String) -> Dictionary:
	return LectorJson.leer(RUTA + "misiones/%s.json" % id)


func unidad(id: String) -> Dictionary:
	assert(unidades.has(id), "Unidad desconocida: %s" % id)
	return unidades[id]


func enemigo(id: String) -> Dictionary:
	assert(enemigos.has(id), "Enemigo desconocido: %s" % id)
	return enemigos[id]


func poder(id: String) -> Dictionary:
	assert(poderes.has(id), "Poder desconocido: %s" % id)
	return poderes[id]



func comandante(id: String) -> Dictionary:
	assert(comandantes.has(id), "Comandante desconocido: %s" % id)
	return comandantes[id]
