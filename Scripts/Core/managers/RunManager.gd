extends Node

# Clase interna
class RunState:
	# Mazo persistente
	var deck: Array[Dictionary] = []
	var hand: Array[Dictionary] = []
	var discard: Array[Dictionary] = []
	var exhaust: Array[Dictionary] = []
	
	# Estado de jugador durante run
	var relics: Array[String] = []
	var max_hand_size: int = 7
	var current_health: int = 2
	var max_health: int = 2
	var modified_cards: Array[Dictionary] = [] 
	
	# Avance de pisos y capitulos
	var current_floor: int = 0
	var current_chapter: int = 0
	
	# Estado de combate temporal
	var current_shield: int = 0
	var has_persistent_shield: bool = false
	var draw_on_damage: bool = false
	var quemadura_acumulada: int = 0
	
	# Clonación profunda
	func clone() -> RunState:
		var copy = RunState.new()
		copy.deck = deck.duplicate(true)
		copy.hand = hand.duplicate(true)
		copy.discard = discard.duplicate(true)
		copy.exhaust = exhaust.duplicate(true)
		copy.relics = relics.duplicate()
		copy.max_hand_size = max_hand_size
		copy.current_health = current_health
		copy.max_health = max_health
		copy.modified_cards = modified_cards 
		copy.current_floor = current_floor
		copy.current_chapter = current_chapter
		copy.current_shield = current_shield
		copy.has_persistent_shield = has_persistent_shield
		copy.draw_on_damage = draw_on_damage
		copy.quemadura_acumulada = quemadura_acumulada
		return copy
	
	func _clone_array(source: Array) -> Array:
		var result = []
		for item in source:
			if typeof(item) == TYPE_DICTIONARY:
				result.append(_clone_dict(item))
			else:
				result.append(item)
		return result
	
	func _clone_dict(source: Dictionary) -> Dictionary:
		var result = {}
		for key in source.keys():
			var value = source[key]
			if typeof(value) == TYPE_DICTIONARY:
				result[key] = _clone_dict(value)
			elif typeof(value) == TYPE_ARRAY:
				result[key] = _clone_array(value)
			else:
				result[key] = value
		return result
	
	# Métodos de acceso
	func get_deck_size() -> int:
		return deck.size()
	
	func get_hand_size() -> int:
		return hand.size()
	
	func get_discard_size() -> int:
		return discard.size()
	
	# Verificar si se puede robar (utilidad para UI)
	func can_draw_card() -> bool:
		if hand.size() >= max_hand_size:
			return false
		if deck.is_empty() and discard.is_empty():
			return false
		return true
	
	func has_relic(relic_id: String) -> bool:
		return relics.has(relic_id)
	
	func is_alive() -> bool:
		return current_health > 0
	
	func is_boss_floor() -> bool:
		return current_floor == 5
	
	# Debug
	func debug_string() -> String:
		return """
	RunState:
	  Floor: %d
	  Chapter: %d
	  Health: %d/%d
	  Hand: %d cards
	  Deck: %d cards
	  Discard: %d cards
	  Exhaust: %d cards
	  Relics: %s
	  Modified Cards: %d
	  Shield: %d (persistent: %s)
	  Quemadura: %d
	""" % [
			current_floor,
			current_chapter,
			current_health,
			max_health,
			hand.size(),
			deck.size(),
			discard.size(),
			exhaust.size(),
			str(relics),
			modified_cards.size(),
			current_shield,
			str(has_persistent_shield),
			quemadura_acumulada
		]

func get_debug_hand_size() -> int:
	return _current_run.hand.size()


func get_debug_deck_size() -> int:
	return _current_run.deck.size()


# Estado interno
var _current_run: RunState = RunState.new()


# Señales
@warning_ignore("unused_signal")
signal run_iniciada(floor: int, health: int, max_health: int)
@warning_ignore("unused_signal")
signal mazo_actualizado(deck_size: int, discard_size: int, hand_size: int)
@warning_ignore("unused_signal")
signal salud_actualizada(current: int, max: int)
@warning_ignore("unused_signal")
signal reliquia_activada(relic_id: String, nombre: String)
@warning_ignore("unused_signal")
signal piso_avanzado(floor: int)
@warning_ignore("unused_signal")
signal combate_iniciado(enemy_name: String)
@warning_ignore("unused_signal")
signal combate_finalizado(victoria: bool)


func _ready() -> void:
	# Registrar como singleton si no existe
	if not Engine.has_singleton("RunManager"):
		Engine.register_singleton("RunManager", self)


func start_new_run() -> void:
	_current_run = RunState.new()
	_generar_mazo_inicial()
	
	emit_signal("run_iniciada", 
		_current_run.current_floor, 
		_current_run.current_health, 
		_current_run.max_health
	)
	
	print("[RunManager] Nueva run iniciada")
	print(_current_run.debug_string())


# Reset de estados temporales del combate
func reset_temporary_combat_state() -> void:
	_current_run.current_shield = 0
	_current_run.quemadura_acumulada = 0
	print("[RunManager] Estados temporales de combate reseteados")
	

# Reset entre capitulos
func reset_chapter_state() -> void:
	# Conservar reliquias y mejoras
	var relics_copy = _current_run.relics.duplicate()
	var modified_cards_copy = _current_run.modified_cards.duplicate()
	var health_copy = _current_run.current_health
	
	# Resetear mazo/descarte/mano
	_current_run.deck.clear()
	_current_run.hand.clear()
	_current_run.discard.clear()
	_current_run.exhaust.clear()
	
	# Regenerar mazo base
	_generar_mazo_inicial()
	
	# Restaurar reliquias y mejoras
	_current_run.relics = relics_copy
	_current_run.modified_cards = modified_cards_copy
	_current_run.current_health = health_copy
	
	# Resetear estados temporales
	_current_run.current_shield = 0
	_current_run.quemadura_acumulada = 0
	
	print("[RunManager] Capítulo reseteado. Reliquias conservadas: %d" % relics_copy.size())


# API Mazo
func draw_card() -> Dictionary:
	if _current_run.hand.size() >= _current_run.max_hand_size:
		return {}
	
	if _current_run.deck.is_empty():
		_refill_deck_from_discard()
	
	if _current_run.deck.is_empty():
		push_warning("[RunManager] Mazo y descarte vacíos - no se puede robar")
		return {}
	
	var card = _current_run.deck.pop_back()
	_current_run.hand.append(card)
	
	_emitir_actualizacion_mazo()
	return card


func discard_card_from_hand(card_index: int) -> Dictionary:
	if card_index < 0 or card_index >= _current_run.hand.size():
		push_error("[RunManager] Índice inválido para descartar: %d" % card_index)
		return {}
	
	var card = _current_run.hand[card_index]
	_current_run.hand.remove_at(card_index)
	_current_run.discard.append(card)
	
	_emitir_actualizacion_mazo()
	return card


func discard_card(card_data: Dictionary) -> void:
	var found_index = -1
	var card_id = card_data.get("id", "")
	
	#  Buscar por ID
	if card_id != "":
		for i in range(_current_run.hand.size()):
			if _current_run.hand[i].get("id") == card_id:
				found_index = i
				break
	
	# Si no se encontró por ID, buscar por nombre + facción
	if found_index == -1:
		var card_name = card_data.get("nombre", "")
		var card_faction = card_data.get("faccion", "")
		
		for i in range(_current_run.hand.size()):
			if _current_run.hand[i].get("nombre") == card_name and _current_run.hand[i].get("faccion") == card_faction:
				found_index = i
				print("[RunManager] Fallback: Encontrada carta '%s' por nombre/facción en índice %d" % [card_name, i])
				break
	
	# EJECUTAR ELIMINACIÓN
	if found_index != -1:
		_current_run.hand.remove_at(found_index)
		print("[RunManager] Carta removida de hand. Tamaño: %d → %d" % [_current_run.hand.size() + 1, _current_run.hand.size()])
	else:
		push_error("[RunManager] CRÍTICO: No se encontró la carta '%s' (ID: %s) en la mano lógica para descartar." % [
			card_data.get("nombre", "desconocida"), 
			card_id
		])
	
	# Añadir al descarte
	_current_run.discard.append(_clonar_carta(card_data))
	
	_emitir_actualizacion_mazo()


func recover_card_from_discard() -> Dictionary:
	if _current_run.discard.is_empty():
		return {}
	var carta = _current_run.discard.pop_back() # Modifica estado real
	_emitir_actualizacion_mazo()
	print("[RunManager] Carta recuperada del descarte: %s" % carta.get("nombre", "desconocida"))
	return carta



func discard_all_hand() -> Array[Dictionary]:
	var discarded = _current_run.hand.duplicate(true)
	_current_run.discard += discarded
	_current_run.hand.clear()
	
	_emitir_actualizacion_mazo()
	return discarded


func add_card_to_deck(card_data: Dictionary) -> void:
	_current_run.deck.append(_clonar_carta(card_data))
	_shuffle_array(_current_run.deck)
	
	_emitir_actualizacion_mazo()
	print("[RunManager] Carta añadida al mazo: %s" % card_data.get("nombre", "desconocida"))


func add_card_to_hand(card_data: Dictionary) -> bool:
	if _current_run.hand.size() >= _current_run.max_hand_size:
		return false
	
	_current_run.hand.append(_clonar_carta(card_data))
	_emitir_actualizacion_mazo()
	return true


# API Reliquias
const RELIQUIAS_DATOS = {
	"mano_plus": { "nombre": "Mano del Tarot", "descripcion": "Tu mano puede contener hasta 8 cartas." },
	"escudo_leal": { "nombre": "Fortaleza Aconcagua", "descripcion": "Al usar proteccion en defensa, el 50% se mantiene para el próximo turno." },
	"resiliencia": { "nombre": "Salvación de la Machi", "descripcion": "Tras recibir daño, robas cartas hasta completar tu mano." }
}

func add_relic(relic_id: String) -> bool:
	if not RELIQUIAS_DATOS.has(relic_id):
		push_error("[RunManager] Reliquia desconocida: %s" % relic_id)
		return false
	
	if _current_run.has_relic(relic_id):
		return false
	
	_current_run.relics.append(relic_id)
	
	match relic_id:
		"mano_plus":
			_current_run.max_hand_size = 8
		"escudo_leal":
			_current_run.has_persistent_shield = true
		"resiliencia":
			_current_run.draw_on_damage = true
	
	emit_signal("reliquia_activada", relic_id, RELIQUIAS_DATOS[relic_id].nombre)
	print("[RunManager] Reliquia activada: %s" % RELIQUIAS_DATOS[relic_id].nombre)
	return true


func get_relic_data(relic_id: String) -> Dictionary:
	return RELIQUIAS_DATOS.get(relic_id, {})


# API Combate
func take_damage(amount: int) -> bool:
	_current_run.current_health -= amount
	
	emit_signal("salud_actualizada", _current_run.current_health, _current_run.max_health)
	
	# Trigger: resiliencia
	if _current_run.draw_on_damage and _current_run.current_health > 0:
		var cartas_a_robar = _current_run.max_hand_size - _current_run.hand.size()
		for i in range(cartas_a_robar):
			draw_card()
	
	return _current_run.current_health <= 0


func heal(amount: int) -> void:
	_current_run.current_health = min(_current_run.current_health + amount, _current_run.max_health)
	emit_signal("salud_actualizada", _current_run.current_health, _current_run.max_health)


func apply_shield(amount: int) -> void:
	_current_run.current_shield += amount


func get_current_shield() -> int:
	return _current_run.current_shield


func reset_turn_shield() -> void:
	if _current_run.has_persistent_shield and _current_run.current_shield > 0:
		_current_run.current_shield = int(_current_run.current_shield * 0.5)
	else:
		_current_run.current_shield = 0


func has_persistent_shield() -> bool:
	return _current_run.has_persistent_shield


func has_draw_on_damage() -> bool:
	return _current_run.draw_on_damage


# API Capitulos y pisos
func advance_floor() -> bool:
	_current_run.current_floor += 1
	
	emit_signal("piso_avanzado", _current_run.current_floor)
	print("[RunManager] Avanzando a piso %d" % _current_run.current_floor)
	
	return _current_run.current_floor <= 5


func advance_chapter() -> bool:
	_current_run.current_chapter += 1
	_current_run.current_floor = 0  # Resetear piso al nuevo capítulo
	
	emit_signal("piso_avanzado", _current_run.current_floor)
	print("[RunManager] Avanzando al Capítulo %d" % _current_run.current_chapter)
	
	return _current_run.current_chapter < 3  # Máximo 3 capítulos


# API acceso

func get_current_chapter() -> int:
	return _current_run.current_chapter


func get_max_chapters() -> int:
	return 3  # Total de capítulos en la run


func get_current_floor() -> int:
	return _current_run.current_floor


func get_current_run_state() -> RunState:
	return _current_run.clone()


func get_max_hand_size() -> int:
	return _current_run.max_hand_size


func get_current_health() -> int:
	return _current_run.current_health


func get_max_health() -> int:
	return _current_run.max_health


func has_relic(relic_id: String) -> bool:
	return _current_run.has_relic(relic_id)


func is_alive() -> bool:
	return _current_run.is_alive()


# Metodos internos
func _generar_mazo_inicial(palos_permitidos: Array[String] = []) -> void:
	_current_run.deck.clear()
	
	var dir_path = "res://Recursos/DefinicionCartas/"
	var dir = DirAccess.open(dir_path)
	
	if not dir:
		push_error("Error: No se encontró la carpeta de cartas.")
		return

	# Si no se pasa lista, cargar TODOS los palos encontrados (Comportamiento por defecto)
	var usar_filtro = not palos_permitidos.is_empty()
	
	dir.list_dir_begin()
	var folder_name = dir.get_next()
	
	while folder_name != "":
		if dir.current_is_dir() and folder_name != "." and folder_name != "..":
			
			# Si hay lista permitida, verificar si este palo está incluido
			if usar_filtro and not palos_permitidos.has(folder_name):
				folder_name = dir.get_next()
				continue # Saltar este palo
			
			# Cargar cartas de este palo
			var sub_dir = DirAccess.open(dir_path + folder_name + "/")
			if sub_dir:
				sub_dir.list_dir_begin()
				var file_name = sub_dir.get_next()
				
				while file_name != "":
					if file_name.ends_with(".tres"):
						var full_path = dir_path + folder_name + "/" + file_name
						var recurso = load(full_path) as DefinicionCarta
						
						if recurso:
							_current_run.deck.append({
								"id": recurso.id_carta,
								"nombre": recurso.nombre_carta,
								"danno": recurso.dano,
								"faccion": recurso.faccion,
								"efecto": recurso.descripcion_personalizada if recurso.descripcion_personalizada != "" else recurso.efecto_descripcion,
								
								# Rutas visuales
								"escena_path": recurso.ruta_escena,
								"sprite_base": recurso.ruta_sprite_base,
								"sprite_calma": recurso.ruta_sprite_calma,
								"sprite_agresiva": recurso.ruta_sprite_agresiva,
								"ruta_icono": recurso.ruta_icono,
								
								# Bonus numéricos
								"bonus_calma": recurso.bonus_dano_calma,
								"bonus_agresiva": recurso.bonus_dano_agresiva,
								
								# Arrays
								"efectos_base": recurso.efectos,
								"efectos_calma": recurso.efectos_calma,
								"efectos_agresiva": recurso.efectos_agresiva,
								
								# Flags
								"mejora_sobrescribe_efectos": recurso.mejora_sobrescribe_efectos,
								
								# Metadatos
								"rareza": recurso.rareza,
								"tags": recurso.tags,
								"descripcion_personalizada": recurso.descripcion_personalizada,
								
								# Estado de mejora
								"estado_mejora": "base"
							})
					file_name = sub_dir.get_next()
				sub_dir.list_dir_end()
		
		folder_name = dir.get_next()
	
	dir.list_dir_end()
	_shuffle_array(_current_run.deck)
	print("[RunManager] Mazo generado: %d cartas." % _current_run.deck.size())


# Fallback legacy (por seguridad)
func _generar_mazo_inicial_legacy() -> void:
	var factions = ["Mapuche", "Nok", "Jomon", "Sumeria"]
	var base_names = {
		"Mapuche": "Acecho del Cóndor",
		"Nok": "Estruendo Pudú",
		"Jomon": "Nguillatún Machi",
		"Sumeria": "Camahueto impío"
	}
	var base_effects = {
		"Mapuche": "Roba cartas igual a su daño",
		"Nok": "50% de quemadura al enemigo",
		"Jomon": "Roba 1 carta y no se descarta",
		"Sumeria": "Aplica proteccion igual a su daño"
	}
	var scene_paths = {
		"Mapuche": "res://Scenes/Cards/culturas/CartaMapuche.tscn",
		"Nok": "res://Scenes/Cards/culturas/CartaNok.tscn",
		"Jomon": "res://Scenes/Cards/culturas/CartaJomon.tscn",
		"Sumeria": "res://Scenes/Cards/culturas/CartaSumeria.tscn"
	}
	
	for faction in factions:
		for damage in range(1, 11):
			_current_run.deck.append({
				"id": "starter_%s_%02d" % [faction.to_lower(), damage],
				"nombre": "%s %d" % [base_names[faction], damage],
				"danno": damage,
				"faccion": faction,
				"efecto": base_effects[faction],
				"escena_path": scene_paths[faction]
			})


# Aplicar efecto de robo
func aplicar_efecto_robo(cantidad: int) -> Array[Dictionary]:
	var cartas_robadas: Array[Dictionary] = []
	
	for i in range(cantidad):
		var carta = draw_card()
		if not carta.is_empty():
			cartas_robadas.append(carta)
		else:
			# Detener bubles
			break
	
	return cartas_robadas


func _refill_deck_from_discard() -> void:
	if _current_run.discard.is_empty():
		return
	
	_current_run.deck.clear()
	for card in _current_run.discard:
		_current_run.deck.append(_clonar_carta(card))
	
	_current_run.discard.clear()
	_shuffle_array(_current_run.deck)
	
	print("[RunManager] Mazo rellenado desde descarte (%d cartas)" % _current_run.deck.size())
	_emitir_actualizacion_mazo()


func _shuffle_array(array: Array) -> void:
	for i in range(array.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var temp = array[i]
		array[i] = array[j]
		array[j] = temp


func _clonar_carta(card: Dictionary) -> Dictionary:
	var clone = {}
	for key in card.keys():
		var value = card[key]
		if typeof(value) == TYPE_DICTIONARY:
			clone[key] = _clonar_carta(value)
		elif typeof(value) == TYPE_ARRAY:
			clone[key] = value.duplicate(true)
		else:
			clone[key] = value
	return clone


func _emitir_actualizacion_mazo() -> void:
	emit_signal("mazo_actualizado", 
		_current_run.deck.size(),
		_current_run.discard.size(),
		_current_run.hand.size()
	)


# Finalizar combate
func end_combat() -> void:
	emit_signal("combate_finalizado", true)


# Función pública para iniciar turno del jugador
func iniciar_turno_jugador(deck_visual: Node) -> void:
	print("[RunManager] Inicio turno jugador - mano: %d/%d" % [
		_current_run.hand.size(), 
		_current_run.max_hand_size
	])
	
	# Resetear escudo de turno
	reset_turn_shield()
	
	# Calcular cuántas cartas robar para llenar mano
	var cartas_a_robar = 1
	
	# Verificación de seguridad
	if _current_run.hand.size() >= _current_run.max_hand_size:
		print("[RunManager] Mano llena, no se roba carta de turno.")
		return
	
	# Ejecutar robo visual
	if deck_visual and deck_visual.has_method("robar_cartas_animadas"):
		deck_visual.robar_cartas_animadas(cartas_a_robar)
		print("[RunManager] Robada %d carta de inicio de turno." % cartas_a_robar)
	else:
		push_error("[RunManager] deck_visual no tiene método robar_cartas_animadas")


# Función pública para aplicar robo por efecto de carta
func aplicar_robo_por_efecto(cantidad: int, deck_visual: Node) -> int:
	var cartas_robadas = 0
	
	for i in range(cantidad):
		# Verificar si aún hay espacio en mano
		if _current_run.hand.size() >= _current_run.max_hand_size:
			break
		
		# Usar deck.robar_carta_animada() para sincronizar
		if deck_visual and deck_visual.has_method("robar_carta_animada"):
			deck_visual.robar_carta_animada()
			cartas_robadas += 1
	
	return cartas_robadas


func get_hand_size() -> int:
	return _current_run.hand.size()

func get_deck_size() -> int:
	return _current_run.deck.size()

func get_discard_size() -> int:
	return _current_run.discard.size()

func can_draw_card() -> bool:
	if _current_run.hand.size() >= _current_run.max_hand_size:
		return false
	if _current_run.deck.is_empty() and _current_run.discard.is_empty():
		return false
	return true
