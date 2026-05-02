class RunState:
	# Mazo persistente
	var deck: Array[Dictionary] = []
	var hand: Array[Dictionary] = []
	var discard: Array[Dictionary] = []
	var exhaust: Array[Dictionary] = []
	
	# Estado de jugador
	var relics: Array[String] = []
	var max_hand_size: int = 7
	var current_health: int = 2
	var max_health: int = 2
	var current_floor: int = 0
	
	# Estado de combate temporal
	var current_shield: int = 0
	var has_persistent_shield: bool = false
	var draw_on_damage: bool = false
	var quemadura_acumulada: int = 0
	
	# Clonación profunda
	func clone() -> RunState:
		var copy = RunState.new()
		copy.deck = _clone_array(deck)
		copy.hand = _clone_array(hand)
		copy.discard = _clone_array(discard)
		copy.exhaust = _clone_array(exhaust)
		copy.relics = relics.duplicate()
		copy.max_hand_size = max_hand_size
		copy.current_health = current_health
		copy.max_health = max_health
		copy.current_floor = current_floor
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


	# Acceso seguro
	func get_deck_size() -> int:
		return deck.size()


	func get_hand_size() -> int:
		return hand.size()


	func get_discard_size() -> int:
		return discard.size()


	func get_exhaust_size() -> int:
		return exhaust.size()


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
	  Health: %d/%d
	  Hand: %d cards
	  Deck: %d cards
	  Discard: %d cards
	  Exhaust: %d cards
	  Relics: %s
	  Shield: %d (persistent: %s)
	  Quemadura: %d
	""" % [
			current_floor,
			current_health,
			max_health,
			hand.size(),
			deck.size(),
			discard.size(),
			exhaust.size(),
			str(relics),
			current_shield,
			str(has_persistent_shield),
			quemadura_acumulada
		]
