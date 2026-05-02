extends Node

# Rareza y probabilidad de ovtención
const RARITY_WEIGHTS = {
	"comun": 60,      # 60% de las recompensas
	"poco_comun": 30, # 30%
	"raro": 8,        # 8%
	"epico": 2        # 2%
}

# Cartas por facción (IDs para generar recompensas)
const CARTAS_POR_FACCION = {
	"Mapuche": ["mapuche_1", "mapuche_2", "mapuche_3", "mapuche_4", "mapuche_5", "mapuche_6", "mapuche_7", "mapuche_8", "mapuche_9", "mapuche_10"],
	"Nok": ["nok_1", "nok_2", "nok_3", "nok_4", "nok_5", "nok_6", "nok_7", "nok_8", "nok_9", "nok_10"],
	"Jomon": ["jomon_1", "jomon_2", "jomon_3", "jomon_4", "jomon_5", "jomon_6", "jomon_7", "jomon_8", "jomon_9", "jomon_10"],
	"Sumeria": ["sumeria_1", "sumeria_2", "sumeria_3", "sumeria_4", "sumeria_5", "sumeria_6", "sumeria_7", "sumeria_8", "sumeria_9", "sumeria_10"]
}

# Reliquias disponibles (excluye las ya activas)
const RELIQUIAS_DISPONIBLES = ["mano_plus", "escudo_leal", "resiliencia"]


# API Publica 
func generate_card_reward(floor_num: int, preferred_faction: String = "", rarity_override: String = "") -> Dictionary:
	var rarity = rarity_override if rarity_override else _determine_rarity_by_floor(floor_num)
	var faction = preferred_faction if preferred_faction else _select_random_faction()
	var card_id = _select_random_card_id(faction, rarity)
	
	return _build_card_data(card_id, faction, rarity)


func generate_relic_reward(excluded_relics: Array[String] = []) -> Dictionary:
	var available = RELIQUIAS_DISPONIBLES.duplicate()
	for relic in excluded_relics:
		available.erase(relic)
	
	if available.is_empty():
		return {
			"id": "carta_fallback",
			"name": "Carta de Reserva",
			"descripcion": "Una carta común para continuar tu camino",
			"type": "carta",
			"nombre": "Carta Genérica",
			"danno": 3,
			"faccion": "Mapuche",
			"efecto": "Roba 1 carta",
			"escena_path": "res://scriptcarta/culturas/CartaMapuche.tscn",
			"rareza": "comun"
		}  # No hay reliquias disponibles
	
	var relic_id = available[randi() % available.size()]
	return _build_relic_data(relic_id)


func generate_event_reward(floor_num: int) -> Dictionary:
	var events = [
		{ "id": "curacion", "name": "Rituales Ancestrales", "effect": "heal", "value": 1 },
		{ "id": "maldicion", "name": "Corrupción del Olvido", "effect": "curse", "value": -1 },
		{ "id": "robo_extra", "name": "Visión del Chamán", "effect": "draw", "value": 2 },
		{ "id": "escudo_temporal", "name": "Protección Espiritual", "effect": "shield", "value": 5 }
	]
	
	# Aumentar probabilidad de eventos positivos en pisos bajos
	var weights = []
	for i in range(events.size()):
		var base_weight = 10
		if events[i].effect == "heal" or events[i].effect == "draw":
			base_weight += max(0, 5 - floor_num) * 2  # Más curación en pisos tempranos
		weights.append(base_weight)
	
	var event = _weighted_random_choice(events, weights)
	return event


func generate_reward_options(floor_num: int, num_options: int = 3) -> Array[Dictionary]:
	var options: Array[Dictionary] = [] 
	
	# Tipo de recompensas disponibles en este piso
	var reward_types = _get_available_reward_types(floor_num)
	
	for i in range(num_options):
		var reward_type = reward_types[randi() % reward_types.size()]
		
		match reward_type:
			"carta":
				options.append(generate_card_reward(floor_num))
			"carta_rara":
				options.append(generate_card_reward(floor_num, "", "raro"))
			"reliquia":
				var relic = generate_relic_reward()
				if not relic.is_empty():
					options.append(relic)
				else:
					options.append(generate_card_reward(floor_num))  # Fallback seguro
			"evento":
				options.append({
						"id": "curacion",
						"name": "Recuperar Alma",
						"effect": "heal",
						"value": 1,
						"type": "curacion"  # para _aplicar_recompensa
					})
	
	return options


# Metodos privados
func _determine_rarity_by_floor(floor_num: int) -> String:
	var roll = randf()
	
	# Piso 5 (jefe) = siempre raro/épico
	if floor_num >= 5:
		return "raro" if roll < 0.75 else "epico"
	
	# Pisos 3-4 = mayor probabilidad de poco común/raro
	if floor_num >= 3:
		if roll < 0.4:
			return "comun"
		elif roll < 0.75:
			return "poco_comun"
		else:
			return "raro"
	
	# Pisos 1-2 = principalmente común/poco común
	if roll < 0.6:
		return "comun"
	else:
		return "poco_comun"


func _select_random_faction() -> String:
	var factions = ["Mapuche", "Nok", "Jomon", "Sumeria"]
	return factions[randi() % factions.size()]


func _select_random_card_id(faction: String, rarity: String) -> String:
	var _cards = CARTAS_POR_FACCION.get(faction, [])
	
	# Rareza afecta el rango de valores disponibles
	var min_value = 1
	var max_value = 10
	
	match rarity:
		"comun":
			max_value = 5  # Cartas débiles (1-5)
		"poco_comun":
			min_value = 4
			max_value = 7  # Cartas medias (4-7)
		"raro":
			min_value = 6
			max_value = 9  # Cartas fuertes (6-9)
		"epico":
			min_value = 8
			max_value = 10  # Cartas épicas (8-10)
	
	# Seleccionar valor dentro del rango
	var value = randi() % (max_value - min_value + 1) + min_value
	return "%s_%d" % [faction.to_lower(), value]


func _build_card_data(card_id: String, faction: String, rarity: String) -> Dictionary:
	var parts = card_id.split("_")
	var value = parts[1].to_int() if parts.size() > 1 else 1
	
	var names = {
		"Mapuche": "Acecho del Cóndor",
		"Nok": "Estruendo Pudú",
		"Jomon": "Nguillatún Machi",
		"Sumeria": "Camahueto impío"
	}
	
	var effects = {
		"Mapuche": "Roba %d carta(s)" % value,
		"Nok": "50% de quemadura al enemigo",
		"Jomon": "Recupera carta del descarte",
		"Sumeria": "Aplica %d de escudo" % value
	}
	
	var scene_paths = {
		"Mapuche": "res://Scenes/Cards/culturas/CartaMapuche.tscn",
		"Nok": "res://Scenes/Cards/culturas/CartaNok.tscn",
		"Jomon": "res://Scenes/Cards/culturas/CartaJomon.tscn",
		"Sumeria": "res://Scenes/Cards/culturas/CartaSumeria.tscn"
	}
	
	return {
		"id": card_id,
		"nombre": "%s %d" % [names.get(faction, faction), value],
		"danno": value,
		"faccion": faction,
		"efecto": effects.get(faction, "Efecto desconocido"),
		"escena_path": scene_paths.get(faction, ""),
		"rareza": rarity,
		"type": "carta"
	}

func _build_relic_data(relic_id: String) -> Dictionary:
	var RunManager = Engine.get_singleton("RunManager")
	if not RunManager:
		return {}
	
	var data = RunManager.get_relic_data(relic_id)
	return {
		"id": relic_id,
		"nombre": data.get("nombre", "Reliquia desconocida"),
		"descripcion": data.get("descripcion", "Sin descripción"),
		"type": "reliquia"
	}


func _get_available_reward_types(floor_num: int) -> Array[String]:
	if floor_num == 0:
		return ["reliquia"]  # Solo reliquias al inicio
	
	if floor_num == 5:
		return ["carta_rara", "reliquia", "evento"]  # Jefe = mejores recompensas
	
	# Pisos 1-4: mezcla balanceada
	return ["carta", "carta_rara", "reliquia", "evento", "curacion"]


func _weighted_random_choice(items: Array, weights: Array) -> Variant:
	var total_weight = 0
	for w in weights:
		total_weight += w
	
	var roll = randf() * total_weight
	var accumulated = 0.0
	
	for i in range(items.size()):
		accumulated += weights[i]
		if roll <= accumulated:
			return items[i]
	
	return items[-1]  # Fallback


# Debug
func debug_test_generation() -> void:
	print("\n=== PRUEBA DE GENERACIÓN DE RECOMPENSAS ===")
	for floor_num in range(6):
		print("\nPiso %d:" % floor_num)
		var options = generate_reward_options(floor_num, 3)
		for opt in options:
			print("  → %s (%s)" % [opt.get("nombre", opt.get("id", "?")), opt.get("type", "?")])
	print("==========================================\n")
