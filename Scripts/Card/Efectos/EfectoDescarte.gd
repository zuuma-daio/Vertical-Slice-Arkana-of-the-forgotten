class_name EfectoDescarte
extends EffectComponent

@export var cantidad: int = 1
@export var aleatorio: bool = true
@export var gatillo: String = "fin_turno"  # "inmediato", "fin_turno"

func aplicar_efecto(_contexto: CombatContext) -> Dictionary:
	if gatillo == "inmediato":
		return { "descartar": cantidad, "aleatorio": aleatorio }
	else:
		# Registrar como efecto activador
		return { "activador_descarte": { "cantidad": cantidad, "aleatorio": aleatorio } }

func obtener_descripcion() -> String:
	if aleatorio:
		return "Descarta %d carta(s) aleatoria(s) al final del turno" % cantidad
	return "Descarta %d carta(s) al final del turno" % cantidad
