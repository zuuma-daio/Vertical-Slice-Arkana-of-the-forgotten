class_name CardData

var id: String = ""
var name: String = ""
var damage: int = 0
var faction: String = ""
var effect: String = ""
var scene_path: String = ""

func _init(p_id: String = "", p_name: String = "", p_damage: int = 0, \
		p_faction: String = "", p_effect: String = "", p_scene_path: String = ""):
	id = p_id
	name = p_name
	damage = p_damage
	faction = p_faction
	effect = p_effect
	scene_path = p_scene_path

func clone() -> CardData:
	return CardData.new(id, name, damage, faction, effect, scene_path)

func debug_string() -> String:
	return "CardData(%s, %s, %d, %s)" % [id, name, damage, faction]
