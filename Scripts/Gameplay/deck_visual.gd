@tool
class_name DeckVisual
extends Node2D

@onready var sprite = $Sprite2D
@onready var label = $Label
@onready var posicion_salida_carta: Marker2D = $PosicionSalidaCarta

# Posición fija de diseño
@export var posicion_diseño: Vector2 = Vector2(100, 500)


func _ready():
	position = posicion_diseño
	
	# Conectar a RunManager para actualizar contador
	if Engine.has_singleton("RunManager"):
		var rm = Engine.get_singleton("RunManager")
		if not rm.mazo_actualizado.is_connected(_on_mazo_actualizado):
			rm.mazo_actualizado.connect(_on_mazo_actualizado)
	
	# Actualizar contador inicial
	_actualizar_contador()


func _on_mazo_actualizado(_deck_size: int, _discard_size: int, _hand_size: int) -> void:
	_actualizar_contador()


func _actualizar_contador() -> void:
	if Engine.has_singleton("RunManager"):
		var rm = Engine.get_singleton("RunManager")
		var run_state = rm.get_current_run_state()
		label.text = str(run_state.deck.size())


func get_posicion_salida() -> Vector2:
	return posicion_salida_carta.global_position
