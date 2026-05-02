class_name EfectoMultiplicadorDano
extends EffectComponent

@export var multiplicador: float = 2.0
@export var duracion: String = "este_turno"  # "este_turno", "proximo_turno", "persistente"

func aplicar_efecto(contexto: CombatContext) -> Dictionary:
	var id_buff = "multiplicador_dano_%s" % duracion
	contexto.agregar_buff(id_buff, multiplicador, 1 if duracion == "este_turno" else -1)
	return { "multiplicador_dano": multiplicador, "duracion": duracion }

func obtener_descripcion() -> String:
	return "Tu próximo ataque hace x%d daño" % int(multiplicador)
