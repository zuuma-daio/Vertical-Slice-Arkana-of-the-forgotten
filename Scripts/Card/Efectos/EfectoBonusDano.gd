class_name EfectoBonusDano
extends EffectComponent

@export var bonus_dano: int = 3
@export var duracion: String = "este_turno"  # "este_turno", "proximo_turno"

func aplicar_efecto(contexto: CombatContext) -> Dictionary:
	var id_buff = "bonus_dano_%s" % duracion
	contexto.agregar_buff(id_buff, bonus_dano, 1 if duracion == "este_turno" else -1)
	return { "bonus_dano": bonus_dano, "duracion": duracion }

func obtener_descripcion() -> String:
	return "+%d al daño el %s" % [bonus_dano, duracion]
