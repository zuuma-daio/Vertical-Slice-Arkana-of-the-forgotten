extends Control

signal recompensa_elegida(recompensa: Dictionary)
@warning_ignore("unused_signal")
signal transicion_completada()

@onready var botones_opcion = [
	$BotonOpcion1,
	$BotonOpcion2,
	$BotonOpcion3
]
@onready var boton_continuar = $BotonContinuar

var opciones_activas: Array[Dictionary] = []

func _ready() -> void:
	# Ocultar botones al inicio (seguro incluso si no están en escena)
	for boton in botones_opcion:
		if boton:
			boton.visible = false
			boton.pressed.connect(_on_boton_opcion_pressed.bind(botones_opcion.find(boton)))
	boton_continuar.visible = false
	boton_continuar.pressed.connect(_on_boton_continuar_pressed)
	visible = false  # Iniciar oculto

func mostrar(opciones: Array[Dictionary]) -> void:
	if not is_inside_tree():
		await ready  # Esperar a que el árbol esté listo
	
	opciones_activas = opciones
	
	# Configurar botones visibles
	for i in range(botones_opcion.size()):
		var boton = botones_opcion[i]
		if not boton:
			push_error("[RewardScreen] Botón %d no encontrado en escena" % (i+1))
			continue
		
		if i < opciones.size():
			var opt = opciones[i]
			# Manejo seguro de claves (algunas usan "name", otras "nombre")
			var nombre = opt.get("name", opt.get("nombre", "Recompensa"))
			var desc = opt.get("descripcion", opt.get("effect", "Sin descripción"))
			boton.text = "%s\n%s" % [nombre, desc]
			boton.disabled = false
			boton.visible = true
		else:
			boton.visible = false
	
	boton_continuar.visible = false
	visible = true

# Conexión dinámica (evita errores de nombre de función)
func _on_boton_opcion_pressed(index: int) -> void:
	if index >= opciones_activas.size() or index < 0:
		return
	
	# Deshabilitar TODOS los botones de opción
	for boton in botones_opcion:
		if boton:
			boton.disabled = true
	
	var recompensa = opciones_activas[index]
	recompensa_elegida.emit(recompensa)
	boton_continuar.visible = true

func _on_boton_continuar_pressed() -> void:
	visible = false
	emit_signal("transicion_completada")
