class_name GeneradorEnemigos
extends Node
## Hace aparecer enemigos mientras el obstáculo siga en pie.
## Al pasar el límite de tiempo + aviso lanza la horda final.

## Pide un enemigo; desfase separa a los miembros de un grupo en el carril.
signal pidio_enemigo(tipo: String, desfase: float)

var aparicion: Dictionary = {}
var horda: Dictionary = {}
var inicio_horda := 190.0

var _siguiente := 0.0
var _horda_restante := 0
var _siguiente_horda := 0.0
var _horda_iniciada := false


func configurar(mision: Dictionary, inicio_horda_: float) -> void:
	aparicion = mision.get("aparicion", {})
	horda = mision.get("horda", {})
	inicio_horda = inicio_horda_
	_siguiente = float(aparicion.get("retraso_inicial", 0))
	_horda_restante = int(horda.get("cantidad", 0))
	_horda_iniciada = false


func intervalo_actual(tiempo: float) -> float:
	var inicial := float(aparicion.get("intervalo_inicial", 5))
	var minimo := float(aparicion.get("intervalo_minimo", 2))
	var reduccion := float(aparicion.get("reduccion_por_segundo", 0))
	return maxf(minimo, inicial - reduccion * tiempo)


## Cuántos enemigos salen juntos: empieza en grupo_inicial y suma uno cada
## grupo_crece_cada segundos, hasta grupo_maximo.
func tamano_grupo(tiempo: float) -> int:
	var inicial := int(aparicion.get("grupo_inicial", 1))
	var maximo := int(aparicion.get("grupo_maximo", 1))
	var cada := float(aparicion.get("grupo_crece_cada", 0))
	if cada <= 0.0:
		return inicial
	return mini(maximo, inicial + floori(tiempo / cada))


func avanzar(tiempo: float) -> void:
	if tiempo >= _siguiente:
		var separacion := float(aparicion.get("separacion_grupo", 30))
		for i in tamano_grupo(tiempo):
			pidio_enemigo.emit(aparicion.get("tipo", "basico"), i * separacion)
		_siguiente = tiempo + intervalo_actual(tiempo)
	if tiempo >= inicio_horda:
		if not _horda_iniciada:
			_horda_iniciada = true
			_siguiente_horda = tiempo
		if tiempo >= _siguiente_horda:
			pidio_enemigo.emit(horda.get("tipo", "horda"), 0.0)
			if _horda_restante > 0:
				_horda_restante -= 1
				_siguiente_horda = tiempo + float(horda.get("intervalo", 0.6))
			else:
				_siguiente_horda = tiempo + float(horda.get("intervalo_despues", 1.5))
