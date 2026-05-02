extends Node2D

@onready var mano = $Mano
@onready var deck = $Deck
@onready var boton_jugar = $BotonJugar

signal carta_jugada(carta: Carta, efectos: Dictionary)
signal defensa_completada
signal ataque_saltado()
signal modo_defensa_cambiado(activado: bool)

var modo_defensa: bool = false

func _ready() -> void:
	await get_tree().process_frame
	
	# Conectar señales de Mano
	if mano:
		mano.carta_seleccionada.connect(_on_carta_seleccionada)
		mano.carta_deseleccionada.connect(_on_carta_deseleccionada)
	
	boton_jugar.pressed.connect(_on_boton_jugar_pressed)
	actualizar_boton_segun_seleccion()


func _on_boton_jugar_pressed() -> void:
	if modo_defensa:
		_procesar_defensa()
	else:
		_jugar_carta()


func _jugar_carta() -> void:
	var cartas_seleccionadas = _obtener_cartas_seleccionadas()
	
	if cartas_seleccionadas.is_empty():
		ataque_saltado.emit()
		return
	
	# Forzar 1 carta máxima
	if cartas_seleccionadas.size() > 1:
		for i in range(1, cartas_seleccionadas.size()):
			cartas_seleccionadas[i].Deseleccionar()
		cartas_seleccionadas.resize(1)
	
	var carta = cartas_seleccionadas[0]
	
	# Calcular efectos básicos
	var index = mano.cartas_en_mano.find(carta)
	var carta_removida = null
	if index != -1:
		carta_removida = mano.Remover_carta(index)
	
	# Calcular efectos básicos
	var efectos = _calcular_efectos_basicos(carta)
	
	# Emitir señal con carta
	carta_jugada.emit(carta, efectos)
	
	# Descartar visualmente
	if carta_removida:
		deck.descartar_carta_animada(carta_removida)



func _calcular_efectos_basicos(carta: Carta) -> Dictionary:
	# Intentar obtener definición Resource primero
	var main = get_node("/root/Main")
	if main and main.has_method("_obtener_definicion_carta"):
		var card_def = main._obtener_definicion_carta(carta.NombreCarta)
		if card_def:
			# Retornar efectos mínimos para compatibilidad
			return {
				"danno_base": carta.DannoCarta,
				"usar_nuevo_sistema": true
			}
	
	# Fallback al sistema antiguo (para testing)
	var efectos = {
		"danno_base": carta.DannoCarta,
		"robar": 0,
		"escudo": 0,
		"quemadura": 0,
		"recuperar_a_mazo": 0,
		"recuperar_a_mano": 0 
	}
	
	match carta.FaccionCarta:
		"Mapuche":
			efectos.robar = carta.DannoCarta
		"Sumeria":
			efectos.escudo = carta.DannoCarta
		"Nok":
			if randf() < 0.5:
				efectos.quemadura = 1
		"Jomon":
			efectos.recuperar_a_mazo = carta.DannoCarta
	
	return efectos


func _procesar_defensa() -> void:
	var cartas_seleccionadas = _obtener_cartas_seleccionadas()
	
	var cartas_usadas = []
	for carta in cartas_seleccionadas:
		cartas_usadas.append(carta)
	
	# Eliminar visualmente
	var indices = []
	for i in range(mano.cartas_en_mano.size()):
		if mano.cartas_en_mano[i].seleccionada:
			indices.append(i)
	indices.sort()
	indices.reverse()
	
	for index in indices:
		var carta = mano.Remover_carta(index)
		deck.descartar_carta_animada(carta)  # Por medio de RunManager
	
	defensa_completada.emit(cartas_usadas)


func _obtener_cartas_seleccionadas() -> Array:
	var seleccionadas = []
	for carta in mano.cartas_en_mano:
		if carta.seleccionada:
			seleccionadas.append(carta)
	return seleccionadas


func actualizar_boton_segun_seleccion():
	if not boton_jugar:
		return
	
	if modo_defensa:
		boton_jugar.text = "Bloquear"
	else:
		if _obtener_cartas_seleccionadas().is_empty():
			boton_jugar.text = "Saltar Ataque"
		else:
			boton_jugar.text = "Jugar Carta"


func set_modo_defensa(activado: bool):
	modo_defensa = activado
	actualizar_boton_segun_seleccion()
	modo_defensa_cambiado.emit(activado)

func _on_carta_seleccionada(_carta: Carta):
	actualizar_boton_segun_seleccion()

func _on_carta_deseleccionada(_carta: Carta):
	actualizar_boton_segun_seleccion()

func _process(_delta: float) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	boton_jugar.position = Vector2(viewport_size.x / 1.2, viewport_size.y - 120)
