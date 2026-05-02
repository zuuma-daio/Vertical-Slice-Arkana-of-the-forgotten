class_name EfectoExilio
extends EffectComponent

@export var exiliar_carta_actual: bool = true
@export var exiliar_del_mazo: int = 0  # 0 = no exilia del mazo

func aplicar_efecto(_contexto: CombatContext) -> Dictionary:
	return { 
		"exiliar": exiliar_carta_actual,
		"exiliar_del_mazo": exiliar_del_mazo
	}

func obtener_descripcion() -> String:
	if exiliar_carta_actual:
		return "Exilia esta carta"
	return "Exilia %d carta(s) del mazo" % exiliar_del_mazo

func duplicar() -> EffectComponent:
	var copia = EfectoExilio.new()
	copia.exiliar_carta_actual = exiliar_carta_actual
	copia.exiliar_del_mazo = exiliar_del_mazo
	return copia
