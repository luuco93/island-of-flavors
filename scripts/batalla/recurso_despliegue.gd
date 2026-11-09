class_name RecursoDespliegue
extends Recurso
## Se llena solo con el tiempo y paga las unidades.

var recarga_por_segundo := 2.0


func avanzar(delta: float) -> void:
	sumar(recarga_por_segundo * delta)
