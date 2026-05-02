class_name EfectoProteccion
extends EffectComponent

@export var cantidad_proteccion: int = 1
@export var solo_turno_defensa: bool = false
@export var bonus_defensa: int = 0  # Bonus adicional en turno de defensa

func puede_aplicarse(contexto: CombatContext) -> bool:
	if solo_turno_defensa and not contexto.es_turno_defensa:
		return false
	return true

func aplicar_efecto(contexto: CombatContext) -> Dictionary:
	var total_proteccion = cantidad_proteccion
	
	# Bonus si es turno de defensa
	if contexto.es_turno_defensa and bonus_defensa > 0:
		total_proteccion += bonus_defensa
	
	contexto.proteccion_actual += total_proteccion
	
	return { "proteccion": total_proteccion }

func obtener_descripcion() -> String:
	if solo_turno_defensa:
		return "En Bloqueo: Protección +%d" % (cantidad_proteccion + bonus_defensa)
	return "Protección +%d" % cantidad_proteccion

func duplicar() -> EffectComponent:
	var copia = EfectoProteccion.new()
	copia.id_efecto = id_efecto
	copia.descripcion = descripcion
	copia.cantidad_proteccion = cantidad_proteccion
	copia.solo_turno_defensa = solo_turno_defensa
	copia.bonus_defensa = bonus_defensa
	return copia
