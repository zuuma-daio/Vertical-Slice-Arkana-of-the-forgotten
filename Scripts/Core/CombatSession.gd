extends Node2D

# Referencias
@onready var deck_visual: Node2D = $DeckVisual if has_node("DeckVisual") else null
@onready var descarte_visual: Node2D = $DescarteVisual if has_node("DescarteVisual") else null
@onready var mano_visual: Node2D = $Mano if has_node("Mano") else null
@onready var deck_logic: Node = $Deck if has_node("Deck") else null

# Estado interno
var _is_active: bool = false
var _current_enemy: String = ""
var _turn_count: int = 0


func _ready() -> void:
	# Conectar señales de RunManager para sincronización automática
	var rm = _get_run_manager()
	if rm:
		rm.mazo_actualizado.connect(_on_mazo_actualizado)
		rm.salud_actualizada.connect(_on_salud_actualizada)
		rm.piso_avanzado.connect(_on_piso_avanzado)
		rm.reliquia_activada.connect(_on_reliquia_activada)
	
	_sync_view_with_runstate()


func _exit_tree() -> void:
	# Desconectar señales al destruir la sesión
	var rm = _get_run_manager()
	if rm:
		if rm.mazo_actualizado.is_connected(_on_mazo_actualizado):
			rm.mazo_actualizado.disconnect(_on_mazo_actualizado)
		if rm.salud_actualizada.is_connected(_on_salud_actualizada):
			rm.salud_actualizada.disconnect(_on_salud_actualizada)
		if rm.piso_avanzado.is_connected(_on_piso_avanzado):
			rm.piso_avanzado.disconnect(_on_piso_avanzado)
		if rm.reliquia_activada.is_connected(_on_reliquia_activada):
			rm.reliquia_activada.disconnect(_on_reliquia_activada)


# API publica
func start_combat(enemy_id: String, enemy_data: Dictionary = {}) -> void:
	_is_active = true
	_current_enemy = enemy_id
	_turn_count = 0
	
	print("[CombatSession] Iniciando combate vs %s" % enemy_id)
	
	# Sincronizar vista con estado actual de RunManager
	_sync_view_with_runstate()
	
	# Emitir señal para que Main.gd prepare el enemigo visual
	if enemy_data.has("scene_path"):
		emit_signal("enemigo_cargado", enemy_id, enemy_data.scene_path)
	else:
		emit_signal("enemigo_cargado", enemy_id, "")


func end_combate(victoria: bool) -> void:
	_is_active = false
	_turn_count = 0
	
	print("[CombatSession] Combate finalizado. Victoria: %s" % victoria)
	emit_signal("combate_terminado", victoria)


func is_combat_active() -> bool:
	return _is_active


# Orquestación
@warning_ignore("unused_signal")
signal enemigo_cargado(enemy_id: String, scene_path: String)
@warning_ignore("unused_signal")
signal combate_terminado(victoria: bool)
@warning_ignore("unused_signal")
signal turno_iniciado(turn_number: int)
@warning_ignore("unused_signal")
signal turno_finalizado(turn_number: int)


# Sincronización con RunManager
func _sync_view_with_runstate() -> void:
	var rm = _get_run_manager()
	if not rm or not _is_active:
		return
	
	var run_state = rm.get_current_run_state()
	
	# Sincronizar mano visual
	if mano_visual and mano_visual is Node:
		# Limpiar mano visual actual
		for i in range(mano_visual.cartas_en_mano.size() - 1, -1, -1):
			var carta = mano_visual.cartas_en_mano[i]
			mano_visual.Remover_carta(i)
			carta.queue_free()
		
		# Crear nodos Carta para cada CardData en hand
		for card_data in run_state.hand:
			_create_card_node_from_data(card_data, mano_visual)
	
	# Actualizar contadores visuales
	if deck_visual:
		deck_visual.label.text = str(run_state.deck.size())
	
	if descarte_visual:
		descarte_visual.label.text = str(run_state.discard.size())


func _create_card_node_from_data(card_data: Dictionary, target_mano: Node) -> void:
	if not card_data.has("escena_path") or card_data.escena_path == "":
		push_error("[CombatSession] Carta sin escena_path: %s" % card_data)
		return
	
	var scene = load(card_data.escena_path)
	if not scene:
		push_error("[CombatSession] Escena no encontrada: %s" % card_data.escena_path)
		return
	
	var carta_node = scene.instantiate() as Node
	if not carta_node:
		push_error("[CombatSession] Falló instancia de carta: %s" % card_data.escena_path)
		return
	
	# Configurar carta con datos de RunManager
	if carta_node.has_method("set_datos"):
		carta_node.set_datos(
			card_data.get("nombre", "Carta"),
			card_data.get("danno", 1),
			card_data.get("faccion", "Pueblo"),
			card_data.get("efecto", "Sin efecto")
		)
	
	# Añadir a la mano visual
	if target_mano and target_mano.has_method("Agregar_carta"):
		target_mano.Agregar_carta(carta_node)
	else:
		push_warning("[CombatSession] target_mano no tiene método Agregar_carta")


# Señales con RunManager
func _on_mazo_actualizado(deck_size: int, discard_size: int, _hand_size: int) -> void:
	if not _is_active:
		return
	
	# Actualizar contadores UI
	if deck_visual and deck_visual.has_node("Label"):
		deck_visual.get_node("Label").text = str(deck_size)
	
	if descarte_visual and descarte_visual.has_node("Label"):
		descarte_visual.get_node("Label").text = str(discard_size)
	
	# Sincronizar mano visual
	_sync_view_with_runstate()


func _on_salud_actualizada(current: int, max_health: int) -> void:
	if not _is_active:
		return
	# Conexión con Main
	emit_signal("salud_actualizada", current, max_health)


func _on_piso_avanzado(floor_num: int) -> void:
	if not _is_active:
		return
	print("[CombatSession] Piso avanzado a %d" % floor_num)


func _on_reliquia_activada(relic_id: String, nombre: String) -> void:
	if not _is_active:
		return
	print("[CombatSession] Reliquia activada: %s (%s)" % [nombre, relic_id])


# Metodos de utilidad
func _get_run_manager() -> Node:
	if Engine.has_singleton("RunManager"):
		return Engine.get_singleton("RunManager")
	return null


func debug_print_state() -> void:
	var rm = _get_run_manager()
	if rm:
		var state = rm.get_current_run_state()
		print("""
[CombatSession Debug]
  Activo: %s
  Enemigo: %s
  Turno: %d
  Mano: %d cartas
  Mazo: %d cartas
  Descarte: %d cartas
  Salud: %d/%d
  Reliquias: %s
""" % [
			str(_is_active),
			_current_enemy,
			_turn_count,
			state.hand.size(),
			state.deck.size(),
			state.discard.size(),
			state.current_health,
			state.max_health,
			str(state.relics)
		])
