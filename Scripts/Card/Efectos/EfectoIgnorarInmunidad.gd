class_name EfectoIgnorarInmunidad
extends EffectComponent

@export var duracion: int = 1  # turnos

func aplicar_efecto(contexto: CombatContext) -> Dictionary:
	contexto.agregar_buff("ignorar_inmunidad", true, duracion)
	return { "ignorar_inmunidad": true, "duracion": duracion }

func obtener_descripcion() -> String:
	return "Tu próximo ataque ignora inmunidad"
