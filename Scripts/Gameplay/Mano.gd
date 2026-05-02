@tool
class_name Mano
extends Node2D

@export var Radio_inclinacion: int = 1000
@export var Angulo_carta: float = 90
@export var Angulo_Limite: float = 25
@export var Maximo_dispersion_angulo: float = 3
@export var separacion_hover_grados: float = 8
@export var elevacion_hover_px: float = 35.0
@export var escala_hover: float = 2


@onready var TesteoCarta = $DebugCarta
@onready var collision_shape: CollisionShape2D = $DebugPosicionMano

var cartas_en_mano: Array[Carta] = []
var tocadas: Array[Carta] = []
var current_selected_card_index: int = -1
var indice_carta_hover: int = -1

signal carta_seleccionada(carta: Carta)
signal carta_deseleccionada(carta: Carta)
signal carta_clickada(carta: Carta)


func _ready() -> void:
	pass


# Agregar cartas a la mano
func Agregar_carta(carta: Carta, _animado: bool = false, _posicion_inicial: Vector2 = Vector2.ZERO):
	cartas_en_mano.push_back(carta)
	add_child(carta)
	
	carta.mouse_entered.connect(_tocar_carta_mano)
	carta.mouse_exited.connect(_notocar_carta_mano)
	carta.seleccion_cambiada.connect(_on_carta_seleccion_cambiada)
	Reposicionar_Carta()


# Agregar carta pero con animación de movimiento
func Agregar_carta_animada(carta: Carta, posicion_inicial: Vector2) -> Tween:
	if carta.get_parent():
		carta.get_parent().remove_child(carta)
	
	cartas_en_mano.push_back(carta)
	add_child(carta)
	
	carta.mouse_entered.connect(_tocar_carta_mano)
	carta.mouse_exited.connect(_notocar_carta_mano)
	carta.seleccion_cambiada.connect(_on_carta_seleccion_cambiada)
	
	carta.position = to_local(posicion_inicial)
	carta.modulate = Color(1, 1, 1, 1)
	carta.rotation = deg_to_rad(0)
	
	var idx = cartas_en_mano.size() - 1
	var dispersion = min(Angulo_Limite / max(cartas_en_mano.size() - 1, 1), Maximo_dispersion_angulo)
	var angulo_base = -(dispersion * (cartas_en_mano.size() - 1)) / 2 - 90
	var angulo_final = angulo_base + dispersion * idx
	var posicion_final = posicion_toma_carta(angulo_final)
	
	var tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(carta, "position", posicion_final, 0.3)
	tween.tween_property(carta, "rotation", deg_to_rad(angulo_final + 90), 0.0)
	tween.finished.connect(func():
		Reposicionar_Carta())
	
	return tween


# Reposicionar todas las cartas en la mano
func Reposicionar_Carta(indice_hover: int = -1):
	if cartas_en_mano.is_empty():
		return
	
	var dispersion = min(Angulo_Limite / max(cartas_en_mano.size() - 1, 1), Maximo_dispersion_angulo)
	var angulo = -(dispersion * (cartas_en_mano.size() - 1)) / 2.0 - 90.0
	
	for i in range(cartas_en_mano.size()):
		var carta = cartas_en_mano[i]
		var offset_angulo: float = 0.0
		
		# Desplaza a todas las cartas
		if indice_hover != -1:
			if i < indice_hover:
				offset_angulo = -separacion_hover_grados
			elif i > indice_hover:
				offset_angulo = separacion_hover_grados
				
		var angulo_final = angulo + offset_angulo
		var pos_final = posicion_toma_carta(angulo_final)
		
		# Desplazamiento radial Hover para la carta activa
		if i == indice_carta_hover:
			var dir_radial = Vector2(0, -elevacion_hover_px).rotated(deg_to_rad(angulo_final + 90.0))
			pos_final += dir_radial
			carta.aplicar_zoom(escala_hover)
		else:
			carta.restaurar_zoom()
			
		carta.position = pos_final
		carta.rotation_degrees = angulo_final + 90.0
		angulo += dispersion

#remover cartas
func Remover_carta(index: int) -> Carta:
	var carta = cartas_en_mano[index]
	cartas_en_mano.remove_at(index)
	if carta.get_parent() == self:
		remove_child(carta)
	
	var idx_tocada = tocadas.find(carta)
	if idx_tocada != -1:
		tocadas.remove_at(idx_tocada)
	
	if carta.seleccionada:
		carta.Deseleccionar()
	
	if current_selected_card_index == index:
		current_selected_card_index = -1
	elif current_selected_card_index > index:
		current_selected_card_index -= 1
	
	if indice_carta_hover == index:
		indice_carta_hover = -1
	elif indice_carta_hover > index:
		indice_carta_hover -= 1
	
	carta.mouse_entered.disconnect(_tocar_carta_mano)
	carta.mouse_exited.disconnect(_notocar_carta_mano)
	carta.seleccion_cambiada.disconnect(_on_carta_seleccion_cambiada)
	
	return carta


func _on_carta_seleccion_cambiada(_estado: bool):
	pass


# Obtener posición circular según ángulo
func posicion_toma_carta(angulo_decre: float) -> Vector2:
	var x: float = Radio_inclinacion * cos(deg_to_rad(angulo_decre))
	var y: float = Radio_inclinacion * sin(deg_to_rad(angulo_decre))
	return Vector2(int(x), int(y))


#carta tocada en mano
func _tocar_carta_mano(carta: Carta):
	if !tocadas.has(carta):
		tocadas.push_back(carta)
		_actualizar_hover_prioritario()


#carta no tocada en mano
func _notocar_carta_mano(carta: Carta):
	var index = tocadas.find(carta)
	if index != -1:
		tocadas.remove_at(index)
		_actualizar_hover_prioritario()


func _actualizar_hover_prioritario():
	var carta_superior: Carta = null
	var max_index = -1
	for c in tocadas:
		var idx = cartas_en_mano.find(c)
		if idx > max_index:
			max_index = idx
			carta_superior = c
			
	var nuevo_hover_index = -1
	if carta_superior != null:
		nuevo_hover_index = cartas_en_mano.find(carta_superior)
		
	if nuevo_hover_index != indice_carta_hover:
		indice_carta_hover = nuevo_hover_index
		Reposicionar_Carta(indice_carta_hover)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if tocadas.is_empty():
			return
			
		# Encontrar la carta más arriba (mayor índice visual)
		var carta_superior: Carta = null
		var max_index = -1
		for c in tocadas:
			var idx = cartas_en_mano.find(c)
			if idx > max_index:
				max_index = idx
				carta_superior = c
		
		if carta_superior == null:
			return
		
		# Aplicar selección
		if carta_superior.seleccionada:
			carta_superior.Deseleccionar()
			carta_deseleccionada.emit(carta_superior)
		else:
			carta_superior.Seleccionar()
			carta_seleccionada.emit(carta_superior)
		
		carta_clickada.emit(carta_superior)


# Mostrar ángulo y radio en tiempo real
func _process(_delta):
	for carta in cartas_en_mano:
		if not carta.seleccionada:
			carta.Eliminar_brillo()
	
	current_selected_card_index = -1
	var carta_superior: Carta = null
	var max_index = -1
	
	for carta_tocada in tocadas:
		var idx = cartas_en_mano.find(carta_tocada)
		if idx > max_index:
			max_index = idx
			carta_superior = carta_tocada
	
	if max_index != -1:
		current_selected_card_index = max_index
		if not carta_superior.seleccionada:
			carta_superior.Animar_brillo()
	
	if (collision_shape.shape as CircleShape2D).radius != Radio_inclinacion:
		(collision_shape.shape as CircleShape2D).set_radius(Radio_inclinacion)
	
	TesteoCarta.set_position(posicion_toma_carta(Angulo_carta))
	TesteoCarta.set_rotation(deg_to_rad(Angulo_carta + 90))
	
	var viewport_size = get_viewport().get_visible_rect().size
	position = Vector2(viewport_size.x / 1.8, viewport_size.y + 750)
