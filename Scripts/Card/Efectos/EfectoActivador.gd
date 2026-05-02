class_name EfectoActivador
extends EffectComponent

@export var gatillo: String = ""  # "al_robar", "al_defender", "al_atacar", "inicio_turno", "fin_turno", "al_jugar_carta"
@export var efecto_contenido: EffectComponent
@export var duracion: int = 1  # turnos que permanece activo

func aplicar_efecto(_contexto: CombatContext) -> Dictionary:
	# Registrar el efecto para activarse después
	if Engine.has_singleton("EffectResolver"):
		var resolver = Engine.get_singleton("EffectResolver")
		resolver.registrar_efecto_activador(gatillo, efecto_contenido, duracion)
	return { "activador_registrado": gatillo }

func obtener_descripcion() -> String:
	if efecto_contenido:
		return "Cuando %s: %s" % [gatillo, efecto_contenido.obtener_descripcion()]
	return "Cuando %s: (sin efecto)" % [gatillo]

func duplicar() -> EffectComponent:
	var copia = EfectoActivador.new()
	copia.id_efecto = id_efecto
	copia.descripcion = descripcion
	copia.gatillo = gatillo
	copia.duracion = duracion
	if efecto_contenido and efecto_contenido.has_method("duplicar"):
		copia.efecto_contenido = efecto_contenido.duplicar()
	return copia
