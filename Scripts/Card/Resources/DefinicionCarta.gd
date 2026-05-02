class_name DefinicionCarta
extends Resource

@export_group("Datos Base")
@export var id_carta: String = ""
@export var nombre_carta: String = ""
@export var dano: int = 0
@export var faccion: String = ""
@export var efecto_descripcion: String = ""

@export_group("Recursos Visuales")
@export var ruta_escena: String = ""
@export var ruta_sprite_base: String = ""
@export var ruta_sprite_calma: String = ""
@export var ruta_sprite_agresiva: String = ""
@export var ruta_icono: String = ""

@export_group("Efectos")
@export var efectos: Array[Dictionary] = []
# Legacy
@export var efectos_ids: Array[String] = []
@export var efectos_parametros: Array[Dictionary] = []

@export_group("Mejoras (Futuro)")
# Estas variables existen pero pueden estar vacías por ahora
@export var bonus_dano_calma: int = 0
@export var bonus_dano_agresiva: int = 0
@export var efectos_calma: Array[Dictionary] = []
@export var efectos_agresiva: Array[Dictionary] = []
@export var mejora_agresiva: DefinicionCarta
@export var mejora_pacifica: DefinicionCarta
# Flag para saber si la mejora reemplaza efectos completamente o los modifica
@export var mejora_sobrescribe_efectos: bool = false

@export_group("Metadatos")
@export var rareza: String = "comun"
@export var descripcion_personalizada: String = ""
@export var tags: Array[String] = []

# IDs válidos de efectos
const EFECTOS_VALIDOS = [
	"robo", "proteccion", "quemadura", "recuperacion",
	"reduccion", "aura", "condicional", "activador",
	"regla_juego", "porcentaje", "retrasado", "exilio",
	"bonus_dano", "descarte", "ignorar_inmunidad", "multiplicador_dano",
	"aura_bloqueo"
]

# Tags válidos para el juego
const TAGS_VALIDOS = [
	# Mecánicas base
	"defensa", "ataque", "robo", "proteccion", "quemadura",
	"reduccion", "reciclaje", "descarte", "exilio",
	
	# Tipos de efecto
	"debuff", "buff", "condicional", "permanente",
	"retrasado", "multiplicador", "aura", "regla_juego",
	
	# Estados de juego
	"turno", "turnos", "flujo", "tempo", "mazo", "mano",
	
	# Elementos/Arquetipos
	"fuego", "agua", "tierra", "aire", "ritual", "ancestral",
	
	# Intensidad/Rareza
	"basico", "alto", "persistente", "riesgo", "ultimatum",
	"control", "burst",
	
	# Sinergias específicas
	"sacrificio", "curacion"
]

# Factory para crear efectos desde IDs
func crear_efectos() -> Array[EffectComponent]:
	var efectos_creados: Array[EffectComponent] = []
	
	# Usar nuevo sistema si existe
	if not efectos.is_empty():
		for efecto_data in efectos:
			var id = efecto_data.get("id", "")
			var params = efecto_data.get("parametros", {})
			var efecto = _crear_efecto_desde_id(id, params)
			if efecto:
				efectos_creados.append(efecto)
		return efectos_creados
	
	# FALLBACK a Sistema legacy (para migración)
	for i in range(efectos_ids.size()):
		var id = efectos_ids[i]
		var params = efectos_parametros[i] if i < efectos_parametros.size() else {}
		var efecto = _crear_efecto_desde_id(id, params)
		if efecto:
			efectos_creados.append(efecto)
	
	return efectos_creados


func _crear_efecto_desde_id(id: String, params: Dictionary) -> EffectComponent:
	match id:
		"robo":
			var efecto = EfectoRobo.new()
			efecto.cartas_a_robar = params.get("cartas_a_robar", 1)
			efecto.condicion = params.get("condicion", "")
			return efecto
		
		"proteccion":
			var efecto = EfectoProteccion.new()
			efecto.cantidad_proteccion = params.get("cantidad_proteccion", 1)
			efecto.solo_turno_defensa = params.get("solo_turno_defensa", false)
			efecto.bonus_defensa = params.get("bonus_defensa", 0)
			return efecto
		
		"quemadura":
			var efecto = EfectoQuemadura.new()
			efecto.cantidad_quemadura = params.get("cantidad_quemadura", 1)
			efecto.acumulable = params.get("acumulable", true)
			efecto.multiplicador = params.get("multiplicador", 1.0)
			return efecto
		
		"recuperacion":
			var efecto = EfectoRecuperacion.new()
			efecto.cantidad = params.get("cantidad", 1)
			efecto.origen = params.get("origen", "descarte")
			efecto.destino = params.get("destino", "mazo")
			return efecto
		
		"reduccion":
			var efecto = EfectoReduccion.new()
			efecto.reduccion = params.get("reduccion", 1)
			efecto.duracion = params.get("duracion", 1)
			efecto.objetivo = params.get("objetivo", "enemigo")
			efecto.estadistica = params.get("estadistica", "dano_base")
			return efecto
		
		"aura":
			var efecto = EfectoAura.new()
			efecto.objetivo = params.get("objetivo", "todas_cartas_mano")
			efecto.estadistica = params.get("estadistica", "defensa")
			efecto.valor = params.get("valor", 1)
			# Usar duracion_variant para aceptar String o int
			efecto.duracion_variant = params.get("duracion", "este_turno")
			return efecto
		
		"aura_bloqueo":
			var efecto = EfectoAuraBloqueo.new()
			efecto.valor_bonus = params.get("valor_bonus", 1)
			efecto.duracion = params.get("duracion", "permanente")
			return efecto
		
		"condicional":
			var efecto = EfectoCondicional.new()
			efecto.condicion = params.get("condicion", "")
			if params.has("efecto_contenido"):
				efecto.efecto_contenido = _crear_efecto_desde_id(
					params["efecto_contenido"].get("id", ""),
					params["efecto_contenido"].get("parametros", {})
				)
			return efecto
		
		"activador":
			var efecto = EfectoActivador.new()
			efecto.gatillo = params.get("gatillo", "")
			efecto.duracion = params.get("duracion", 1)
			if params.has("efecto_contenido"):
				efecto.efecto_contenido = _crear_efecto_desde_id(
					params["efecto_contenido"].get("id", ""),
					params["efecto_contenido"].get("parametros", {})
				)
			return efecto
		
		"regla_juego":
			var efecto = EfectoRegladeJuego.new()
			efecto.regla = params.get("regla", "")
			efecto.valor = params.get("valor", 1)
			efecto.duracion = params.get("duracion", 1)
			return efecto
		
		"porcentaje":
			var efecto = EfectoPorcentaje.new()
			efecto.porcentaje = params.get("porcentaje", 0.25)
			efecto.estadistica = params.get("estadistica", "dano_enemigo")
			efecto.duracion = params.get("duracion", 3)
			efecto.objetivo = params.get("objetivo", "enemigo")
			return efecto
		
		"retrasado":
			var efecto = EfectoRetrasado.new()
			efecto.turnos_retraso = params.get("turnos_retraso", 2)
			efecto.accion = params.get("accion", "barajar_descarte")
			efecto.cantidad = params.get("cantidad", 6)
			return efecto
		
		"exilio":
			var efecto = EfectoExilio.new()
			efecto.exiliar_carta_actual = params.get("exiliar_carta_actual", true)
			efecto.exiliar_del_mazo = params.get("exiliar_del_mazo", 0)
			return efecto
		
		"bonus_dano":
			var efecto = EfectoBonusDano.new()
			efecto.bonus_dano = params.get("bonus_dano", 3)
			efecto.duracion = params.get("duracion", "este_turno")
			return efecto
		
		"descarte":
			var efecto = EfectoDescarte.new()
			efecto.cantidad = params.get("cantidad", 1)
			efecto.aleatorio = params.get("aleatorio", true)
			efecto.gatillo = params.get("gatillo", "fin_turno")
			return efecto
		
		"ignorar_inmunidad":
			var efecto = EfectoIgnorarInmunidad.new()
			efecto.duracion = params.get("duracion", 1)
			return efecto
		
		"multiplicador_dano":
			var efecto = EfectoMultiplicadorDano.new()
			efecto.multiplicador = params.get("multiplicador", 2.0)
			efecto.duracion = params.get("duracion", "este_turno")
			return efecto
	
	push_warning("[DefinicionCarta] Efecto desconocido: %s" % id)
	return null


func obtener_resumen_efectos() -> String:
	if efectos_ids.is_empty():
		if descripcion_personalizada != "":
			return descripcion_personalizada
		return "Sin efectos"
	
	var resumenes: Array[String] = []
	for i in range(efectos_ids.size()):
		var id = efectos_ids[i]
		var params = efectos_parametros[i] if i < efectos_parametros.size() else {}
		resumenes.append(_get_nombre_efecto_con_parametros(id, params))
	
	return ", ".join(resumenes)


func _get_nombre_efecto_con_parametros(id: String, params: Dictionary) -> String:
	match id:
		"robo":
			var cantidad = params.get("cartas_a_robar", 1)
			return "Roba %d" % cantidad
		
		"proteccion":
			var cantidad = params.get("cantidad_proteccion", 1)
			var solo_defensa = params.get("solo_turno_defensa", false)
			if solo_defensa:
				return "En Bloqueo: Protección +%d" % cantidad
			return "Protección +%d" % cantidad
		
		"quemadura":
			var cantidad = params.get("cantidad_quemadura", 1)
			var mult = params.get("multiplicador", 1.0)
			if mult > 1.0:
				return "Duplica Quemadura"
			return "Aplica %d Quemadura" % cantidad
		
		"recuperacion":
			var cantidad = params.get("cantidad", 1)
			var destino = params.get("destino", "mazo")
			if destino == "mano":
				return "Recobra %d" % cantidad
			return "Recupera %d" % cantidad
		
		"reduccion":
			var cantidad = params.get("reduccion", 1)
			var duracion = params.get("duracion", 1)
			if duracion == 0:
				return "Daño enemigo -%d permanente" % cantidad
			elif duracion == 1:
				return "Daño enemigo -%d" % cantidad
			return "Daño enemigo -%d por %d turnos" % [cantidad, duracion]
		
		"porcentaje":
			var pct = int(params.get("porcentaje", 0.25) * 100)
			var duracion = params.get("duracion", 3)
			return "Daño enemigo -%d%% por %d turnos" % [pct, duracion]
		
		"aura":
			var valor = params.get("valor", 1)
			var estadistica = params.get("estadistica", "defensa")
			var objetivo = params.get("objetivo", "enemigo")
			var duracion = params.get("duracion", "este_turno")
			
			if objetivo == "enemigo" and estadistica == "dano_base":
				if valor < 0:
					if duracion == "permanente":
						return "Daño enemigo %d permanente" % valor
					return "Daño enemigo %d" % valor
				else:
					return "Próximo ataque enemigo +%d" % valor
			
			if duracion == "permanente":
				return "Protección +%d permanente" % valor
			return "Protección +%d" % valor
			
		"aura_bloqueo":
			var valor = params.get("valor_bonus", 1)
			return "En Bloqueo: Protección +%d permanente" % valor
			
		"multiplicador_dano":
			var mult = int(params.get("multiplicador", 2.0))
			var duracion = params.get("duracion", "este_turno")
			if duracion == "proximo_turno":
				return "Próximo ataque: Daño x%d" % mult
			return "En este ataque: Daño x%d" % mult
		
		"condicional":
			var condicion = params.get("condicion", "")
			match condicion:
				"turno_defensa":
					return "En Bloqueo:"
				"enemigo_quemado":
					return "Si está Quemado:"
				"solo_una_carta":
					return "Si es única carta:"
				"bloqueo_completo":
					return "Si bloqueo completo:"
			return "Si %s:" % condicion
		
		"regla_juego":
			var regla = params.get("regla", "")
			match regla:
				"no_robar": return "No Robas próximo turno"
				"no_atacar": return "No Atacas próximo turno"
				"perder_turno": return "Enemigo pierde turno"
			return "Regla: %s" % regla
		
		"retrasado":
			var turnos = params.get("turnos_retraso", 2)
			return "En %d turnos:" % turnos
		
		"exilio":
			return "Exilia"
		
		"descarte":
			var cantidad = params.get("cantidad", 1)
			return "Descarta %d" % cantidad
		
		"ignorar_inmunidad":
			return "Ignora Inmunidad"
	
	return id


func validar() -> Array[String]:
	var errores: Array[String] = []
	
	# Validaciones básicas
	if id_carta == "":
		errores.append("ID de carta vacío")
	if nombre_carta == "":
		errores.append("Nombre de carta vacío")
	if ruta_escena == "":
		errores.append("Ruta de escena no definida")
	elif not ResourceLoader.exists(ruta_escena):
		errores.append("Escena no existe: %s" % ruta_escena)
	
	# Validar arrays paralelos
	if efectos_ids.size() != efectos_parametros.size():
		errores.append("Mismatch: %d IDs vs %d parámetros" % [
			efectos_ids.size(),
			efectos_parametros.size()
		])
	
	# Validar IDs de efectos
	for id in efectos_ids:
		if not EFECTOS_VALIDOS.has(id):
			errores.append("Efecto desconocido: %s" % id)
	
	# Validar tags
	for tag in tags:
		if not TAGS_VALIDOS.has(tag):
			errores.append("Tag no registrado: %s" % tag)
	
	# Validar rareza
	var rarezas_validas = ["comun", "poco_comun", "raro", "epico"]
	if rareza != "" and not rarezas_validas.has(rareza):
		errores.append("Rareza inválida: %s" % rareza)
	
	return errores


func _validate_property(property: Dictionary) -> void:
	# Sincronizar tamaño de arrays paralelos
	if property.name == "efectos_parametros":
		while efectos_parametros.size() < efectos_ids.size():
			efectos_parametros.append({})
		while efectos_parametros.size() > efectos_ids.size():
			efectos_parametros.pop_back()
	
	# Validar tags en tiempo de edición
	if property.name == "tags":
		for tag in tags:
			if not TAGS_VALIDOS.has(tag):
				push_warning("Tag no registrado: %s. Tags válidos: %s" % [
					tag,
					", ".join(TAGS_VALIDOS)
				])
