extends RichTextLabel

@export var max_size: int = 32
@export var min_size: int = 14
var last_text := ""

func _ready():
	# Ajusta cuando cargue la escena
	ajustar_fuente()

func _notification(what):
	# Ajusta cuando el label cambie de tamaño
	if what == NOTIFICATION_RESIZED:
		ajustar_fuente()

func ajustar_fuente():
	var font_size := max_size

	while font_size >= min_size:
		add_theme_font_size_override("normal_font_size", font_size)
		await get_tree().process_frame

		if get_content_height() <= self.size.y:
			return

		font_size -= 1


func set_text_and_fit(new_text: String):
	if new_text == last_text:
		return
	last_text = new_text
	text = new_text
	ajustar_fuente()
