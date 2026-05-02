extends Node

# Configuración de Pisos y Capitulos
var chapter_config: Dictionary = {
	0: {  # Capítulo 0: "El Susurro Ancestral"
		0: {
			"name": "Espíritu del Cóndor",
			"damage": 12,
			"health": 20,
			"immunities": [],
			"effects": ["quemadura_aleatoria"],
			"sprite_path": "res://sprites/enemigos/espiritu_condor.png",
			"narrative_id": "espiritu_condor"
		},
		1: {
			"name": "Guardián de Piedra",
			"damage": 14,
			"health": 20,
			"immunities": [],
			"effects": ["proteccion_temporal"],
			"sprite_path": "res://sprites/enemigos/guardian_piedra.png",
			"narrative_id": "guardian_piedra"
		},
		2: {
			"name": "Sombra Ancestral",
			"damage": 16,
			"health": 10,
			"immunities": ["Nok"],
			"effects": ["robo_vida"],
			"sprite_path": "res://sprites/enemigos/sombra_ancestral.png",
			"narrative_id": "sombra_ancestral"
		},
		3: {
			"name": "Espíritu del Bosque",
			"damage": 18,
			"health": 10,
			"immunities": ["Jomon"],
			"effects": ["curacion_enemigo"],
			"sprite_path": "res://sprites/enemigos/espiritu_bosque.png",
			"narrative_id": "espiritu_bosque"
		},
		4: {
			"name": "Corrupción del Olvido",
			"damage": 20,
			"health": 10,
			"immunities": ["Mapuche", "Sumeria"],
			"effects": ["quemadura_permanente", "inmunidad_cambiante"],
			"is_boss": true,
			"sprite_path": "res://sprites/enemigos/corrupcion_olvido.png",
			"narrative_id": "corrupcion_olvido",
			"boss_music": "res://audio/music/boss_theme.ogg"
		}
	}
	# ← Capítulos 1 y 2 se añadirán en Fase 4 (expansión)
}

# API publica
func get_enemy_config(chapter_num: int, floor_num: int) -> Dictionary:
	if chapter_config.has(chapter_num):
		var chapter = chapter_config[chapter_num]
		if chapter.has(floor_num):
			return chapter[floor_num]
	
	# Enemigo genérico por defecto
	return {
		"name": "Enemigo Genérico",
		"damage": 15,
		"health": 10,
		"immunities": [],
		"effects": [],
		"sprite_path": "res://sprites/enemigos/generico.png",
		"narrative_id": "enemigo_generico"
	}


func get_current_floor_data(run_manager: Node) -> Dictionary:
	var chapter = run_manager.get_current_chapter() if run_manager else 0
	var floor_num = run_manager.get_current_floor() if run_manager else 0
	return get_enemy_config(chapter, floor_num)


func is_boss_floor(chapter_num: int, floor_num: int) -> bool:
	var config = get_enemy_config(chapter_num, floor_num)
	return config.get("is_boss", false)


func get_total_floors_in_chapter(chapter_num: int) -> int:
	if chapter_config.has(chapter_num):
		return chapter_config[chapter_num].keys().size()
	return 5  # Default: 5 pisos


func get_chapter_name(chapter_num: int) -> String:
	match chapter_num:
		0: return "El Susurro Ancestral"
		1: return "La Memoria Perdida"  # ← Para Fase 4
		2: return "El Olvido Eterno"    # ← Para Fase 4
		_: return "Capítulo Desconocido"


# Metodos de utilidad y debug
func debug_print_chapter(chapter_num: int) -> void:
	if not chapter_config.has(chapter_num):
		print("Capítulo %d no existe" % chapter_num)
		return
	
	var chapter = chapter_config[chapter_num]
	print("\n=== CAPÍTULO %d: %s ===" % [chapter_num, get_chapter_name(chapter_num)])
	for floor_num in chapter.keys():
		var enemy = chapter[floor_num]
		print("  Piso %d: %s (vida: %d, daño: %d)" % [
			floor_num, 
			enemy.name, 
			enemy.get("health", 100), 
			enemy.damage
		])
