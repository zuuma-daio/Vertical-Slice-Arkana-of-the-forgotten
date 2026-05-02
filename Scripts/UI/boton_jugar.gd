extends Button


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anchor_left = 0.5
	anchor_right = 0.5
	anchor_top = 1.0
	anchor_bottom = 1.0
	pivot_offset = Vector2(size.x / 2, size.y / 2)
	position = Vector2(1110, 510)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
