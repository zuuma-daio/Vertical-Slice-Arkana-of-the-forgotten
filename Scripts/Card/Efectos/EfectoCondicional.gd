class_name EfectoCondicional
extends EffectComponent

@export var condicion: String = ""  # "enemigo_quemado", "bloqueo_completo", "turno_defensa", "solo_una_carta"
@export var efecto_contenido: EffectComponent

func puede_aplicarse(contexto: CombatContext) -> bool:
	return _verificar_condicion(contexto)

func aplicar_efecto(contexto: CombatContext) -> Dictionary:
	if efecto_contenido:
		return efecto_contenido.aplicar_efecto(contexto)
	return {}

func _verificar_condicion(contexto: CombatContext) -> bool:
	match condicion:
		"enemigo_quemado":
			return contexto.quemadura_enemigo > 0
		"bloqueo_completo":
			return contexto.bloqueo_completo
		"turno_defensa":
			return contexto.es_turno_defensa
		"solo_una_carta":
			return contexto.cartas_jugadas_este_turno == 1
		"mazo_vacio":
			return contexto.mazo_tamano == 0
		"jugador_dañado":
			return contexto.vidas_jugador < contexto.max_vidas_jugador
		"":
			return true
	return false

func obtener_descripcion() -> String:
	if efecto_contenido:
		return "Si %s: %s" % [condicion, efecto_contenido.obtener_descripcion()]
	return "Si %s: (sin efecto)" % condicion

func duplicar() -> EffectComponent:
	var copia = EfectoCondicional.new()
	copia.id_efecto = id_efecto
	copia.descripcion = descripcion
	copia.condicion = condicion
	if efecto_contenido and efecto_contenido.has_method("duplicar"):
		copia.efecto_contenido = efecto_contenido.duplicar()
	return copia
