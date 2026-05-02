@tool
class_name DescarteVisual
extends Node2D

@onready var sprite = $Sprite2D
@onready var label = $Label
@onready var posicion_entrada_carta: Marker2D = $PosicionEntradaCarta

# Posición fija de diseño
@export var posicion_diseño: Vector2 = Vector2(120, 850)

@warning_ignore("unused_signal")
signal descarte_clickado


func _ready():
	position = posicion_diseño
	
	# Conectar a RunManager para actualizar contador
	if Engine.has_singleton("RunManager"):
		var rm = Engine.get_singleton("RunManager")
		if not rm.mazo_actualizado.is_connected(_on_mazo_actualizado):
			rm.mazo_actualizado.connect(_on_mazo_actualizado)
	
	# Actualizar contador inicial
	_actualizar_contador()
	
	# Mantener conexión existente para clics
	if $Area2D:
		$Area2D.input_event.connect(_on_area_input)


func _on_mazo_actualizado(_deck_size: int, _discard_size: int, _hand_size: int) -> void:
	_actualizar_contador()


func _actualizar_contador() -> void:
	if Engine.has_singleton("RunManager"):
		var rm = Engine.get_singleton("RunManager")
		var run_state = rm.get_current_run_state()
		label.text = str(run_state.discard.size())


func get_posicion_entrada() -> Vector2:
	return posicion_entrada_carta.global_position


func _on_area_input(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("descarte_clickado")
