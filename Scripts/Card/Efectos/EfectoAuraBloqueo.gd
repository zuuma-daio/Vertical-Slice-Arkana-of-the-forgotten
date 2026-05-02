class_name EfectoAuraBloqueo
extends EffectComponent

@export var valor_bonus: int = 1
@export var duracion: String = "permanente"  # "permanente" = todo el combate

func aplicar_efecto(contexto: CombatContext) -> Dictionary:
	# Registrar un buff que persiste durante el combate
	# Este buff se consulta cuando se calcula la protección de cartas en bloqueo
	var id_buff = "aura_bloqueo_permanente"
	contexto.agregar_buff(id_buff, valor_bonus, -1)  # -1 = permanente (hasta fin de combate)
	
	return { 
		"aura_bloqueo_aplicada": true,
		"valor": valor_bonus,
		"duracion": duracion
	}

func obtener_descripcion() -> String:
	return "Tus cartas usadas en bloqueo ganan +%d de Protección permanentemente" % valor_bonus

func duplicar() -> EffectComponent:
	var copia = EfectoAuraBloqueo.new()
	copia.id_efecto = id_efecto
	copia.descripcion = descripcion
	copia.valor_bonus = valor_bonus
	copia.duracion = duracion
	return copia
