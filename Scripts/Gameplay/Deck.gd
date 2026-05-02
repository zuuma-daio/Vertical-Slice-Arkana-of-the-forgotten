class_name Deck
extends Node2D

@export var nodo_mano: NodePath

@onready var deck_visual: DeckVisual = $"../DeckVisual"
@onready var descarte_visual: DescarteVisual = $"../DescarteVisual"
@onready var mano: Mano = get_node_or_null(nodo_mano) if nodo_mano else null

# Pilas visuales
var pila_mazo: Array[Carta] = []
var pila_descartes: Array[Carta] = []

signal mazo_cambiado()

func _ready():
	if Engine.is_editor_hint():
		return
	
	# Validar mano
	if not mano:
		push_warning("[Deck] mano es null - verificando nodo_mano: %s" % str(nodo_mano))
		if nodo_mano and has_node(nodo_mano):
			mano = get_node(nodo_mano)
			print("[Deck] mano recuperada: %s" % str(mano))
	
	# Validar deck_visual
	if not deck_visual:
		push_warning("[Deck] deck_visual es null")
	
	# Validar descarte_visual
	if not descarte_visual:
		push_warning("[Deck] descarte_visual es null")
	
	print("[Deck] Inicializado - mano: %s" % ("OK" if mano else "NULL"))


# Robar carta - Visual
func robar_carta_animada() -> void:
	# Obtener datos de RunManager (fuente de verdad)
	var rm = Engine.get_singleton("RunManager")
	
	var card_data = {}
	if rm:
		card_data = rm.draw_card()
	
	# Si draw_card() retorna vacío, no hay carta para mostrar
	if card_data.is_empty() or not card_data.has("escena_path") or card_data.escena_path == "":
		# Solo mostrar warning si no es por mano llena
		if rm and rm.get_hand_size() < rm.get_max_hand_size():
			push_warning("[Deck] No hay carta para robar (mazo vacío)")
			mostrar_mensaje("Mazo vacío")
		return
	
	# Validar mano visual
	if not mano:
		if nodo_mano and has_node(nodo_mano):
			mano = get_node(nodo_mano)
	
	if not mano:
		push_error("[Deck] mano es null")
		return
	
	# Verificar límite visual como respaldo
	var max_hand = rm.get_max_hand_size() if rm else 7
	if mano.cartas_en_mano.size() >= max_hand:
		push_warning("[Deck] Mano visual llena (%d/%d)" % [
			mano.cartas_en_mano.size(), max_hand
		])
		return
	
	# Crear carta visual
	var pos_salida = deck_visual.get_posicion_salida() if deck_visual else Vector2(100, 500)
	var main = get_node_or_null("/root/Main")
	var carta: Carta = null

	if main and main.has_method("_crear_instancia_carta_visual"):
		carta = main._crear_instancia_carta_visual(card_data)
	else:
		# Fallback legacy si Main no está disponible
		var scene = load(card_data.escena_path)
		if scene:
			carta = scene.instantiate() as Carta
			if carta:
				carta.set_datos(card_data.nombre, card_data.danno, card_data.faccion, card_data.efecto)
				carta.escena_path = card_data.escena_path

	if carta:
		var tween = mano.Agregar_carta_animada(carta, pos_salida)
		if tween:
			await tween.finished
	
	mazo_cambiado.emit()
	print("[Deck] Carta robada: %s" % card_data.nombre)


func robar_cartas_animadas(cantidad: int):
	for i in range(cantidad):
		robar_carta_animada()
	mazo_cambiado.emit()


# Devuelve carta a la pila de descartes
func descartar_carta_animada(carta: Carta):
	if not carta: 
		return
	
	var card_id = ""
	
	var rm = Engine.get_singleton("RunManager")
	if rm:
		# Acceder directamente a la propiedad.
		if "id_carta" in carta: 
			card_id = carta.id_carta
		
		# Fallback si id_carta está vacío
		if card_id == "":
			card_id = carta.NombreCarta.to_lower().replace(" ", "_").replace("'", "")
		
		var card_data = {
			"id": card_id,
			"nombre": carta.NombreCarta,
			"danno": carta.DannoCarta,
			"faccion": carta.FaccionCarta,
			"efecto": carta.EfectoCarta,
			"escena_path": carta.escena_path
		}
		
		rm.discard_card(card_data)
	
	# Actualizar estado visual
	if carta.fuego_animado:
		carta.iniciar_quemado()
		await get_tree().create_timer(1.0).timeout
		carta.detener_quemado()
	
	# Remover de mano y añadir a descarte visual
	if carta.get_parent():
		carta.get_parent().remove_child(carta)
	
	pila_descartes.append(carta)
	mazo_cambiado.emit()
	
	if mano:
		mano.Reposicionar_Carta()
	
	print("[Deck] Carta descartada: %s (ID: %s)" % [carta.NombreCarta, card_id])


# Mezcla los descartes en el mazo - Visual
func recuperar_del_descarte_visual(cantidad: int) -> int:
	var recuperadas = 0
	var cantidad_real = min(cantidad, pila_descartes.size())
	
	print("[Deck] Recuperando %d cartas del descarte (disponibles: %d)" % [
		cantidad, 
		pila_descartes.size()
	])
	
	for i in range(cantidad_real):
		var carta = pila_descartes.pop_back()
		if carta:
			carta.visible = true
			carta.modulate = Color(1, 1, 1, 1)
			pila_mazo.append(carta)
			recuperadas += 1
			print("[Deck] Carta recuperada: %s" % carta.NombreCarta)
	
	if recuperadas > 0:
		barajar()
		mazo_cambiado.emit()
		print("[Deck] Total recuperadas: %d | Mazo: %d | Descarte: %d" % [
			recuperadas,
			pila_mazo.size(),
			pila_descartes.size()
		])
	
	return recuperadas


 # Sincronizar con RunManager
func sincronizar_pilas_con_runmanager() -> void:
	var rm = Engine.get_singleton("RunManager")
	if not rm:
		push_error("[Deck] RunManager no disponible")
		return
	
	var run_state = rm.get_current_run_state()
	
	# Limpiar pilas visuales
	pila_mazo.clear()
	pila_descartes.clear()
	
	# Reconstruir mazo visual desde RunManager
	for card_data in run_state.deck:
		if card_data.has("escena_path") and card_data.escena_path != "":
			var scene = load(card_data.escena_path)
			if scene:
				var carta = scene.instantiate() as Carta
				if carta:
					carta.set_datos(
						card_data.get("nombre", "Carta"),
						card_data.get("danno", 1),
						card_data.get("faccion", "Pueblo"),
						card_data.get("efecto", "Sin efecto")
					)
					carta.escena_path = card_data.escena_path
					pila_mazo.append(carta)
	
	# Reconstruir descarte visual desde RunManager
	for card_data in run_state.discard:
		if card_data.has("escena_path") and card_data.escena_path != "":
			var scene = load(card_data.escena_path)
			if scene:
				var carta = scene.instantiate() as Carta
				if carta:
					carta.set_datos(
						card_data.get("nombre", "Carta"),
						card_data.get("danno", 1),
						card_data.get("faccion", "Pueblo"),
						card_data.get("efecto", "Sin efecto")
					)
					carta.escena_path = card_data.escena_path
					pila_descartes.append(carta)
	
	mazo_cambiado.emit()
	print("[Deck] Pilas sincronizadas: %d mazo, %d descarte" % [
		pila_mazo.size(), 
		pila_descartes.size()
	])


# Funciones de Utilidad
func barajar():
	pila_mazo.shuffle()


func mezclar_descartes():
	if pila_descartes.is_empty():
		return
	
	var nuevas_cartas: Array[Carta] = []
	
	for vieja_carta in pila_descartes:
		var escena := ResourceLoader.load(vieja_carta.escena_path)
		if not escena:
			push_warning("[Deck] No se pudo cargar escena: %s" % vieja_carta.escena_path)
			continue
		
		var nueva_carta = escena.instantiate() as Carta
		if nueva_carta:
			nueva_carta.set_datos(
				vieja_carta.NombreCarta,
				vieja_carta.DannoCarta,
				vieja_carta.FaccionCarta,
				vieja_carta.EfectoCarta
			)
			nueva_carta.seleccionada = false
			nueva_carta.Eliminar_brillo()
			nueva_carta.escena_path = vieja_carta.escena_path
			nuevas_cartas.append(nueva_carta)
	
	pila_mazo += nuevas_cartas
	pila_descartes.clear()
	barajar()
	print("[Deck] Descartes mezclados de vuelta al mazo")
	mazo_cambiado.emit()


func contar_cartas_disponibles() -> int:
	return pila_mazo.size()


func mostrar_mensaje(texto: String):
	var main = get_node_or_null("/root/Main")
	if main and main.has_method("mostrar_mensaje"):
		main.mostrar_mensaje(texto)
