class_name GeneradorEnemigos
extends Node
## Hace aparecer las oleadas de la misión mientras el obstáculo siga en pie.
## Al acabar la lista la repite desde "repetir_desde", cada vez con un
## enemigo más por grupo. Pasado el límite de tiempo + aviso lanza la horda.

## Pide un enemigo en un carril; desfase separa a los miembros de un grupo.
signal pidio_enemigo(tipo: String, carril: int, desfase: float)

var oleadas: Array = []
var repetir_desde := 0
var aumento_por_repeticion := 0
var separacion := 25.0
var horda: Dictionary = {}
var inicio_horda := 190.0
var num_carriles := 3

var _indice := 0
var _repeticiones := 0
var _siguiente := 0.0
var _horda_restante := 0
var _siguiente_horda := 0.0
var _horda_iniciada := false
var _azar: RandomNumberGenerator


func configurar(mision: Dictionary, inicio_horda_: float, num_carriles_: int, azar: RandomNumberGenerator) -> void:
	oleadas = mision.get("oleadas", [])
	repetir_desde = int(mision.get("repetir_desde", 0))
	aumento_por_repeticion = int(mision.get("aumento_por_repeticion", 0))
	separacion = float(mision.get("separacion_grupo", 25))
	horda = mision.get("horda", {})
	inicio_horda = inicio_horda_
	num_carriles = num_carriles_
	_azar = azar
	_indice = 0
	_repeticiones = 0
	_siguiente = float(oleadas[0].get("espera", 0)) if not oleadas.is_empty() else INF
	_horda_restante = int(horda.get("cantidad", 0))
	_horda_iniciada = false


func avanzar(tiempo: float) -> void:
	if not oleadas.is_empty() and tiempo >= _siguiente:
		_lanzar(oleadas[_indice])
		_indice += 1
		if _indice >= oleadas.size():
			_indice = clampi(repetir_desde, 0, oleadas.size() - 1)
			_repeticiones += 1
		_siguiente = tiempo + float(oleadas[_indice].get("espera", 10))
	if tiempo >= inicio_horda:
		if not _horda_iniciada:
			_horda_iniciada = true
			_siguiente_horda = tiempo
		if tiempo >= _siguiente_horda:
			pidio_enemigo.emit(horda.get("tipo", "horda"), _azar.randi_range(0, num_carriles - 1), 0.0)
			if _horda_restante > 0:
				_horda_restante -= 1
				_siguiente_horda = tiempo + float(horda.get("intervalo", 0.6))
			else:
				_siguiente_horda = tiempo + float(horda.get("intervalo_despues", 1.5))


func _lanzar(oleada: Dictionary) -> void:
	for grupo: Dictionary in oleada.get("grupos", []):
		var cantidad := int(grupo.get("cantidad", 1)) + _repeticiones * aumento_por_repeticion
		for c in _carriles_de(grupo.get("carril", "azar")):
			for i in cantidad:
				pidio_enemigo.emit(grupo.get("tipo", "basico"), c, i * separacion)


func _carriles_de(valor: Variant) -> Array[int]:
	if valor is String and valor == "todos":
		return Array(range(num_carriles), TYPE_INT, "", null)
	if valor is String:
		return [_azar.randi_range(0, num_carriles - 1)]
	return [clampi(int(valor), 0, num_carriles - 1)]
