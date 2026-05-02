extends Node

var contexto: CombatContext = null

# Cola de efectos activadores pendientes
var efectos_pendientes: Array[Dictionary] = []
var efectos_retrasados: Array[Dictionary] = []

# Señales
signal evento_combate(nombre: String, datos: Dictionary)
@warning_ignore("unused_signal")
signal efecto_aplicado(datos: Dictionary)


func _ready() -> void:
	contexto = CombatContext.new()
	print("[EffectResolver] Inicializado como Autoload")


func _exit_tree() -> void:
	# Limpieza al cerrar el juego
	efectos_pendientes.clear()
	efectos_retrasados.clear()
	print("[EffectResolver] Limpieza completada")


# Metodo para resolución de efectos
func resolver_efectos(carta: Carta, efectos: Array[EffectComponent]) -> Dictionary:
	var resultados = {}
	
	# Validar reglas de juego
	if not _validar_reglas_juego(carta):
		return { "error": "Regla de juego violada" }
	
	# Preparar contexto
	if contexto == null:
		contexto = CombatContext.new()
	
	contexto.carta_en_ejecucion = carta.NombreCarta
	contexto.faccion_carta = carta.FaccionCarta
	contexto.dano_base_carta = carta.DannoCarta
	contexto.cartas_jugadas_este_turno += 1
	
	# Ejecutar efectos en orden
	for efecto in efectos:
		if efecto.puede_aplicarse(contexto):
			var resultado = efecto.aplicar_efecto(contexto)
			resultados.merge(resultado, true)
			efecto.efecto_aplicado.emit(resultado)
			efecto.post_aplicacion(contexto)
			emit_signal("efecto_aplicado", resultado)
		else:
			efecto.efecto_fallo.emit("Condición no cumplida")
	
	# Procesar efectos activadores pendientes
	_procesar_efectos_pendientes()
	
	# Limpiar contexto de carta (NO todo el contexto)
	contexto.carta_en_ejecucion = ""
	contexto.faccion_carta = ""
	contexto.dano_base_carta = 0
	
	return resultados


func _validar_reglas_juego(carta: Carta) -> bool:
	if contexto == null:
		return true
	
	if not contexto.puede_atacar and _es_carta_ataque(carta):
		return false
	
	if not contexto.puede_robar and _es_carta_robo(carta):
		return false
	
	if contexto.limite_cartas_jugables >= 0:
		if contexto.cartas_jugadas_este_turno > contexto.limite_cartas_jugables:
			return false
	
	return true


func _es_carta_ataque(carta: Carta) -> bool:
	return carta.DannoCarta > 0 and carta.FaccionCarta != "Sumeria"


func _es_carta_robo(carta: Carta) -> bool:
	return "Roba" in carta.EfectoCarta or "roba" in carta.EfectoCarta


# Gestion de triggers o activadores
func registrar_efecto_activador(gatillo: String, efecto: EffectComponent, duracion: int = 1) -> void:
	efectos_pendientes.append({
		"gatillo": gatillo,
		"efecto": efecto,
		"turnos_restantes": duracion
	})


func notificar_evento(nombre: String, datos: Dictionary = {}) -> void:
	evento_combate.emit(nombre, datos)
	
	# Buscar efectos activadores que coincidan con este evento
	var efectos_a_activar = []
	for i in range(efectos_pendientes.size() - 1, -1, -1):
		var pendiente = efectos_pendientes[i]
		if pendiente.gatillo == nombre:
			efectos_a_activar.append(pendiente)
			pendiente.turnos_restantes -= 1
			if pendiente.turnos_restantes <= 0:
				efectos_pendientes.remove_at(i)
	
	# Ejecutar efectos activados
	for pendiente in efectos_a_activar:
		pendiente.efecto.aplicar_efecto(contexto)


func _procesar_efectos_pendientes() -> void:
	# Limpieza de efectos expirados
	for i in range(efectos_pendientes.size() - 1, -1, -1):
		if efectos_pendientes[i].turnos_restantes <= 0:
			efectos_pendientes.remove_at(i)


# Utitlidad para contexto
func obtener_dano_carta(carta: Carta) -> int:
	var dano = carta.DannoCarta
	
	# Aplicar buffs de daño
	if contexto.tiene_buff("aumento_dano"):
		dano += contexto.obtener_valor_buff("aumento_dano")
	
	# Aplicar debuffs de daño
	if contexto.tiene_debuff("reduccion_dano"):
		dano = max(0, dano - contexto.obtener_valor_debuff("reduccion_dano"))
	
	return dano


func obtener_defensa_carta(carta: Carta) -> int:
	var defensa = carta.DannoCarta
	
	# Aplicar buffs de defensa
	if contexto.tiene_buff("aumento_defensa"):
		defensa += contexto.obtener_valor_buff("aumento_defensa")
	
	# Bonus por turno de defensa
	if contexto.es_turno_defensa and contexto.tiene_buff("defensa_turno_defensa"):
		defensa += contexto.obtener_valor_buff("defensa_turno_defensa")
	
	return defensa


func calcular_bloqueo_total(cartas: Array[Carta]) -> int:
	var total = contexto.proteccion_actual
	for carta in cartas:
		total += obtener_defensa_carta(carta)
	return total


func registrar_efecto_retrasado(datos: Dictionary) -> void:
	efectos_retrasados.append(datos)


func _ejecutar_efecto_retrasado(efecto: Dictionary) -> void:
	match efecto.accion:
		"barajar_descarte":
			notificar_evento("barajar_descarte", { "cantidad": efecto.cantidad })


# Gestion de turno y avance
func avanzar_turno() -> void:
	contexto.avanzar_turno()
	notificar_evento("inicio_turno")
	
	# Procesar efectos retrasados
	var efectos_a_ejecutar = []
	for i in range(efectos_retrasados.size() - 1, -1, -1):
		efectos_retrasados[i].turnos_restantes -= 1
		if efectos_retrasados[i].turnos_restantes <= 0:
			efectos_a_ejecutar.append(efectos_retrasados[i])
			efectos_retrasados.remove_at(i)
	
	for efecto in efectos_a_ejecutar:
		_ejecutar_efecto_retrasado(efecto)


func resetear_contexto_combate() -> void:
	contexto = CombatContext.new()
	efectos_pendientes.clear()
	efectos_retrasados.clear()
	print("[EffectResolver] Contexto de combate reseteado")


func debug_print_estado() -> void:
	print("""
[EffectResolver Debug]
  Efectos pendientes: %d
  Efectos retrasados: %d
  Contexto: %s
""" % [
		efectos_pendientes.size(),
		efectos_retrasados.size(),
		"Activo" if contexto else "Nulo"
	])
