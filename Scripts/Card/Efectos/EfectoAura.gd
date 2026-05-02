class_name EfectoAura
extends EffectComponent

@export var objetivo: String = "todas_cartas_mano"  # "todas_cartas_mano", "enemigo", "proximo_ataque"
@export var estadistica: String = "defensa"  # "defensa", "dano", "robo", "dano_base", "multiplicador_dano"
@export var valor: int = 1
@export var duracion_variant: Variant = "este_turno"  # "este_turno", "permanente", "partida"

# Propiedad computada para compatibilidad
func get_duracion_string() -> String:
	if typeof(duracion_variant) == TYPE_STRING:
		return duracion_variant
	elif typeof(duracion_variant) == TYPE_INT:
		return "%d_turnos" % duracion_variant
	return "este_turno"

func get_duracion_turnos() -> int:
	if typeof(duracion_variant) == TYPE_INT:
		return duracion_variant
	elif typeof(duracion_variant) == TYPE_STRING:
		if duracion_variant == "permanente":
			return -1
		elif duracion_variant.ends_with("_turnos"):
			return int(duracion_variant.replace("_turnos", ""))
	return 1

func aplicar_efecto(contexto: CombatContext) -> Dictionary:
	var id_buff = "aura_%s_%s" % [estadistica, objetivo]
	var turnos = get_duracion_turnos()
	
	match objetivo:
		"enemigo":
			if estadistica == "dano_base":
				contexto.agregar_debuff(id_buff, valor, turnos)
			elif estadistica == "dano_maximo":
				contexto.agregar_debuff(id_buff, valor, -1)
		
		"jugador":  # Aura para jugador (Protección por turnos)
			if estadistica == "defensa":
				contexto.agregar_buff(id_buff, valor, turnos)
		
		"todas_cartas_mano":
			contexto.agregar_buff(id_buff, valor, turnos)
	
	return { 
		"aura_aplicada": { 
			"objetivo": objetivo, 
			"estadistica": estadistica, 
			"valor": valor,
			"turnos": turnos
		} 
	}

func obtener_descripcion() -> String:
	var turnos = get_duracion_turnos()
	if turnos == -1:
		return "+%d %s a %s (permanente)" % [valor, estadistica, objetivo]
	elif turnos > 1:
		return "+%d %s a %s (%d turnos)" % [valor, estadistica, objetivo, turnos]
	return "+%d %s a %s (este turno)" % [valor, estadistica, objetivo]

func duplicar() -> EffectComponent:
	var copia = EfectoAura.new()
	copia.id_efecto = id_efecto
	copia.descripcion = descripcion
	copia.objetivo = objetivo
	copia.estadistica = estadistica
	copia.valor = valor
	copia.duracion_variant = duracion_variant
	return copia
