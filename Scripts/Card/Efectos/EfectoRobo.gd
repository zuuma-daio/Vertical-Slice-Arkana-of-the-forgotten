class_name EfectoRobo
extends EffectComponent

@export var cartas_a_robar: int = 1
@export var condicion: String = ""  # "enemigo_quemado", "turno_defensa", "solo_una_carta"

func puede_aplicarse(contexto: CombatContext) -> bool:
	if not contexto.puede_robar:
		return false
	return _verificar_condicion(contexto)

func aplicar_efecto(_contexto: CombatContext) -> Dictionary:
	return { "robar": cartas_a_robar }

func _verificar_condicion(contexto: CombatContext) -> bool:
	match condicion:
		"enemigo_quemado":
			return contexto.quemadura_enemigo > 0
		"turno_defensa":
			return contexto.es_turno_defensa
		"solo_una_carta":
			return contexto.cartas_jugadas_este_turno == 1
		"mazo_vacio":
			return contexto.mazo_tamano == 0
		"":
			return true
	return false

func obtener_descripcion() -> String:
	if condicion != "":
		return "Si %s, roba %d carta(s)" % [condicion, cartas_a_robar]
	return "Roba %d carta(s)" % cartas_a_robar

func duplicar() -> EffectComponent:
	var copia = EfectoRobo.new()
	copia.id_efecto = id_efecto
	copia.descripcion = descripcion
	copia.cartas_a_robar = cartas_a_robar
	copia.condicion = condicion
	return copia
