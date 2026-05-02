class_name EfectoRegladeJuego
extends EffectComponent

@export var regla: String = ""  # "no_robar", "no_atacar", "limite_cartas", "descartar_al_fin"
@export var valor: int = 1
@export var duracion: int = 1  # turnos

func aplicar_efecto(contexto: CombatContext) -> Dictionary:
	match regla:
		"no_robar":
			contexto.puede_robar = false
			return { "regla_aplicada": "no_robar" }
		"no_atacar":
			contexto.puede_atacar = false
			return { "regla_aplicada": "no_atacar" }
		"limite_cartas":
			contexto.limite_cartas_jugables = valor
			return { "regla_aplicada": "limite_cartas", "valor": valor }
		"perder_turno":
			contexto.turno_saltado = true
			return { "regla_aplicada": "perder_turno" }
	return {}

func obtener_descripcion() -> String:
	match regla:
		"no_robar":
			return "No puedes robar cartas este turno"
		"no_atacar":
			return "No puedes atacar este turno"
		"limite_cartas":
			return "Solo puedes jugar %d carta(s) este turno" % valor
		"perder_turno":  # ← NUEVO CASO
			return "El enemigo pierde su próximo turno"
	return "Regla desconocida"
