class_name Personaje extends Node2D

@onready var Almavida1: TextureRect = $Vida/Almavida
@onready var Almavida2: TextureRect = $Vida/Almavida2
var almavidas: int = 2
var max_almavidas: int = 2
var main_ref: Node2D = null

signal game_over()
signal alma_perdida()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Buscar Main de forma más robusta:
	if has_node("/root/Main"):
		main_ref = get_node("/root/Main")
	else:
		# buscar por grupo "main_root" si asignaste Main a ese grupo
		var nodes := get_tree().get_nodes_in_group("main_root")
		if nodes.size() > 0:
			main_ref = nodes[0]
		else:
			main_ref = null
			push_error("No se encontró nodo Main. Asegúrate que exista /root/Main o que Main esté en grupo 'main_root'.")
	call_deferred("_actualizar_almavida")


func perder_vida():
	if almavidas <= 0:
		return
	var alma_anterior = almavidas
	almavidas -= 1
	_actualizar_almavida()
	
	if alma_anterior == 2 and almavidas == 1:
		alma_perdida.emit()
		
	if almavidas <= 0:
		game_over.emit()
	else:
		# Reliquia: Salvación de la Machi (draw_on_damage)
		if Engine.has_singleton("RunManager"):
			var rm = Engine.get_singleton("RunManager")
			if rm and rm.has_draw_on_damage():
				var max_hand = rm.get_max_hand_size()
				var cartas_en_mano = 0
				
				# Validar que main_ref y deck existen
				if main_ref and main_ref.deck and main_ref.deck.mano:
					cartas_en_mano = main_ref.deck.mano.cartas_en_mano.size()
				
				var cartas_faltantes = max_hand - cartas_en_mano
				
				if cartas_faltantes > 0:
					for i in range(cartas_faltantes):
						# Pequeño delay para animaciones
						if i == 0:
							await get_tree().create_timer(1.0).timeout
						else:
							await get_tree().create_timer(0.15).timeout
						
						# Usar robar_carta_animada() en lugar de robar_carta()
						if main_ref and main_ref.deck:
							main_ref.deck.robar_carta_animada()
					
					if main_ref:
						main_ref.mostrar_mensaje("Roba por resiliencia")


func _actualizar_almavida():
	var almas = [Almavida1, Almavida2]
	for i in range(max_almavidas):
		if i < almavidas:
			if i == 0:
				almas[i].modulate = Color(1, 1, 1, 1)  # Cian para primera alma
			else:
				almas[i].modulate = Color(0, 1, 1, 1)  # Amarillo para segunda alma
		else:
			almas[i].modulate = Color(0, 0.298, 0.384)
