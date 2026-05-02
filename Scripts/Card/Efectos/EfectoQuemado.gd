class_name EfectoQuemadura
extends EffectComponent

@export var cantidad_quemadura: int = 1
@export var acumulable: bool = true
@export var multiplicador: float = 1.0  # Para nok_01 (duplicar quemadura)

func puede_aplicarse(contexto: CombatContext) -> bool:
	# Verificar inmunidad del enemigo
	return not contexto.inmunidades_enemigo.has(contexto.faccion_carta)

func aplicar_efecto(contexto: CombatContext) -> Dictionary:
	var cantidad_final = cantidad_quemadura
	
	# Si hay multiplicador (nok_01: duplicar quemadura existente)
	if multiplicador > 1.0 and contexto.quemadura_enemigo > 0:
		cantidad_final = int(contexto.quemadura_enemigo * multiplicador)
	
	if acumulable:
		contexto.quemadura_enemigo += cantidad_final
	else:
		contexto.quemadura_enemigo = max(contexto.quemadura_enemigo, cantidad_final)
	
	return { 
		"quemadura_aplicada": cantidad_final,
		"quemadura_total": contexto.quemadura_enemigo
	}

func obtener_descripcion() -> String:
	if multiplicador > 1.0:
		return "Duplica quemaduras activas (x%s)" % str(multiplicador)
	return "Aplica %d de quemadura" % cantidad_quemadura

func duplicar() -> EffectComponent:
	var copia = EfectoQuemadura.new()
	copia.id_efecto = id_efecto
	copia.descripcion = descripcion
	copia.cantidad_quemadura = cantidad_quemadura
	copia.acumulable = acumulable
	copia.multiplicador = multiplicador
	return copia
