extends Node2D

#ESCENAS
@onready var mazo_y_mano = $Gameplay/MazoYMano
@onready var descarte_visual = $Gameplay/MazoYMano/DescarteVisual
@onready var deck_visual = $Gameplay/MazoYMano/DeckVisual
@onready var enemigo = $Gameplay/Enemigo
@onready var personaje = $Gameplay/Personaje

#MENSAJES
@onready var label_mensajes = $UIManager/UI/PanelContainer/Mensajes
@onready var panel_mensajes = $UIManager/UI/PanelContainer

#LABELS ICONOS
@onready var label_quemadura = $UIManager/UI/LabelQuemadura
@onready var icono_quemadura = $UIManager/UI/IconoQuemadura
@onready var label_escudo = $UIManager/UI/LabelEscudo
@onready var icono_escudo = $UIManager/UI/IconoEscudo
@onready var label_daño_enemigo = $UIManager/UI/LabelDañoEnemigo

#PANTALLAS EXTRA
@onready var Reiniciar = $UIManager/FinCombate/BotonReset
@onready var panel_reliquias = $UIManager/PantallaReliquias
@onready var label_flotante = $UIManager/LabelFlotante

#PANEL NARRATIVO Y EFECTOS DE COMBATE
@onready var narrative_manager = $Manager/NarrativeManager
@onready var ui_manager = $UIManager
@onready var reward_screen = $UIManager/RewardScreen

#CONSTANTES
const RewardGeneratorScript = preload("res://Scripts/Core/managers/RewardGenerator.gd")

#ESTADO DE COMBATE
var combat_context: CombatContext = null
var deck: Deck = null
var turno_jugador: bool = true
var modo_defensa: bool = false
var danno_enemigo_actual: int = 0
var estado_combate: Dictionary = {
	"proteccion_actual": 0,
	"cartas_defensa": [],
	"modo_defensa": false
}

#posicion de animaciones robos
var posicion_mazo = Vector2(100, 500)


# Elementos narrativos
var ultima_narrativa: String = ""
var ultima_decision: Dictionary = {}
var efectos_activos: Dictionary = {
	"fondo_actual": Color(0.1, 0.1, 0.2),
	"intensidad": 0.0,
	"particula_actual": null
}

# Llamada al iniciar
func _ready():
	# Configurar iconos
	icono_escudo.texture = preload("res://sprites/oficiales/iconos/defensa.png")
	icono_quemadura.texture = preload("res://sprites/oficiales/iconos/quemadura.png")
	icono_escudo.visible = false
	icono_quemadura.visible = false
	
	randomize()
	
	if not mazo_y_mano:
		push_error("mazo_y_mano no encontrado")
		return
	
	# Obtener deck con validación
	deck = mazo_y_mano.deck
	
	if not deck:
		push_error("deck es null - verificando MazoYMano")
		# Intentar obtener deck de otra forma
		deck = mazo_y_mano.get_node_or_null("Deck")
		if not deck:
			push_error("No se pudo obtener deck de MazoYMano")
			return
	
	print("[Main] deck obtenido: %s" % str(deck))
	
	# Conectar señales de UI
	$UIManager/VentanaDescartes/BotonCerrar.pressed.connect(func():
		$UIManager/VentanaDescartes.visible = false
	)
	$UIManager/FinCombate/BotonReset.pressed.connect(_reiniciar_run_completa)
	
	# Conectar señales de instrucciones
	$UIManager/Instrucciones/BotonInstrucciones.pressed.connect(func():
		$UIManager/Instrucciones/VentanaInstrucciones.visible = true
		$UIManager/Instrucciones/BotonInstrucciones.visible = false
	)
	$UIManager/Instrucciones/VentanaInstrucciones/Titulo/BotonCerrar.pressed.connect(func():
		$UIManager/Instrucciones/VentanaInstrucciones.visible = false
		$UIManager/Instrucciones/BotonInstrucciones.visible = true
	)
	$UIManager/Instrucciones/VentanaInstrucciones.visible = false
	
	# Conectar señales de combate
	enemigo.enemigo_ataca.connect(enemigo_ataca)
	enemigo.derrotado.connect(_on_enemigo_derrotado)
	personaje.game_over.connect(_on_game_over)
	
	# Conectar señales de cartas
	mazo_y_mano.carta_jugada.connect(_on_carta_jugada)
	mazo_y_mano.ataque_saltado.connect(_on_ataque_saltado)
	mazo_y_mano.defensa_completada.connect(_on_defensa_completada)
	mazo_y_mano.modo_defensa_cambiado.connect(_on_modo_defensa_cambiado)
	
	# Inicializar Autoloads
	RunManager.start_new_run()
	print("Mazo inicial: %d cartas" % RunManager.get_current_run_state().deck.size())
	
	CardDatabase.inicializar("res://Recursos/DefinicionCartas/")
	EffectResolver.resetear_contexto_combate()
	
	print("[Main] Todos los Autoloads inicializados")
	
	# Configurar pantalla de reliquias
	if reward_screen:
		reward_screen.recompensa_elegida.connect(_aplicar_recompensa)
		reward_screen.transicion_completada.connect(_on_transicion_completada)
	
	panel_reliquias.visible = true
	_configurar_botones_reliquias()



func _configurar_botones_reliquias():
	var botones = [
		$UIManager/PantallaReliquias/Reliquia1,
		$UIManager/PantallaReliquias/Reliquia2,
		$UIManager/PantallaReliquias/Reliquia3
	]
	
	var ids = ["mano_plus", "escudo_leal", "resiliencia"]
	ids.shuffle()
	
	for i in range(min(botones.size(), ids.size())):
		var id = ids[i]
		var datos = RunManager.get_relic_data(id)
		
		botones[i].text = datos.nombre
		
		var connected_callable = _elegir_reliquia.bind(id)
		if botones[i].pressed.is_connected(connected_callable):
			botones[i].pressed.disconnect(connected_callable)
		botones[i].pressed.connect(connected_callable)
		
		# Para mouse_entered (solo 1 conexión posible)
		if botones[i].mouse_entered.is_connected(_on_mouse_entered_reliquia):
			botones[i].mouse_entered.disconnect(_on_mouse_entered_reliquia)
		botones[i].mouse_entered.connect(_on_mouse_entered_reliquia.bind(datos.descripcion))


#  método helper (evita closures anónimas que no se pueden desconectar)
func _on_mouse_entered_reliquia(descripcion: String):
	$UIManager/PantallaReliquias/Descripcion.text = descripcion


func _elegir_reliquia(reliquia: String):
	RunManager.add_relic(reliquia)
	panel_reliquias.visible = false
	_iniciar_combate()


func _iniciar_combate():
	print("Combate iniciado - Capítulo %d, Piso %d" % [
		RunManager.get_current_chapter(), 
		RunManager.get_current_floor()
	])
	turno_jugador = true
	modo_defensa = false
	estado_combate.proteccion_actual = 0
	
	# Reset desde Enemigo.gd
	enemigo.resetear_combate()
	
	# Solo resetear estados temporales (proteccion/quemaduras)
	RunManager.reset_temporary_combat_state()
	
	# Configurar enemigo según piso
	var config_enemigo = FloorManager.get_enemy_config(
		RunManager.get_current_chapter(), 
		RunManager.get_current_floor()
	)
	enemigo.configurar_desde_datos(config_enemigo)
	
	# Sincronizar mazo visual
	_sincronizar_mazo_visual_con_runmanager()
	
	# Preparar primer ataque enemigo
	var primer_danno = enemigo.preparar_proximo_ataque()
	danno_enemigo_actual = primer_danno
	label_daño_enemigo.text = "Ataque enemigo: %d" % primer_danno
	
	# Actualizar turno
	actualizar_interfaz()
	mostrar_mensaje_flotante("⚔ Turno de ataque", Color(0, 1, 0))
	
	# Robo inicial - Primer Combate
	if RunManager.get_current_floor() == 0:
		var max_hand = RunManager.get_max_hand_size()
		for i in range(max_hand):
			deck.robar_carta_animada()
			await get_tree().create_timer(0.15).timeout
	else:
		# Robar 1 despues del primer combate
		deck.robar_carta_animada()
		mostrar_mensaje("Mano conservada (sistema KEEP)")
	
	## Narrativa contextual por piso
	#narrative_manager.generar_narrativa("inicio_turno", {
		#"enemigo": enemigo.name,
		#"personaje": "Arca",
		#"carta_jugada": "ninguna",
		#"vida_jugador": personaje.almavidas * 2,
		#"vida_enemigo": enemigo.vida_actual,
	#})


func _sincronizar_mazo_visual_con_runmanager() -> void:
	if not deck:
		push_error("[Main] deck es null")
		return
	
	# Limpiar mazo visual actual
	deck.pila_mazo.clear()
	
	var run_state = RunManager.get_current_run_state()
	
	for card_data in run_state.deck:
		var carta = _crear_instancia_carta_visual(card_data)
		if carta:
			deck.pila_mazo.append(carta)
	
	deck.barajar()
	print("[Main] Mazo visual sincronizado: %d cartas" % deck.pila_mazo.size())


# Solo orquestación (sin lógica de efectos)
func _on_carta_jugada(carta: Carta, _efectos: Dictionary):
	# Obtener definición de carta desde CardDatabase (Autoload)
	var card_def = _obtener_definicion_carta(carta.NombreCarta)
	
	if not card_def:
		push_error("[Main] Carta sin definición Resource: %s" % carta.NombreCarta)
		deck.descartar_carta_animada(carta)
		if not modo_defensa:
			turno_enemigo()
		return
	
	var resolver = EffectResolver
	
	# Actualizar contexto de combate
	_actualizar_contexto_combate(carta)
	
	# Crear efectos desde la definición (nuevo sistema)
	var efectos_creados: Array[EffectComponent] = card_def.crear_efectos()
	
	# Resolver efectos
	var resultados = resolver.resolver_efectos(carta, efectos_creados)
	_aplicar_resultados_combate(resultados, carta)
	
	resolver.notificar_evento("al_jugar_carta", { "carta": carta.NombreCarta })
	
	
	var index = deck.mano.cartas_en_mano.find(carta)
	if index != -1:
		var carta_removida = deck.mano.Remover_carta(index)
		
		var debug_id = ""
		if "id_carta" in carta:
			debug_id = carta.id_carta
		else:
			debug_id = "SIN_ID_PROP"
		
		print("[Main] DEBUG DESCARTE: Enviando ID='%s', Nombre='%s'" % [debug_id, carta.NombreCarta])
		
		deck.descartar_carta_animada(carta_removida)
	
	# En defensa, el turno pasa en _on_defensa_completada()
	if not modo_defensa:
		turno_enemigo()
	
	
	## Narrativa del ataque
	#narrative_manager.generar_narrativa("ataque", {
		#"fase": "ataque",
		#"enemigo": enemigo.name,
		#"personaje": "Arca",
		#"carta_jugada": carta.NombreCarta,
		#"vida_jugador": personaje.almavidas * 2,
		#"vida_enemigo": enemigo.vida_actual
	#})
	
	
	# Mostrar mensaje visual


func _on_ataque_saltado():
	turno_enemigo()


# Función helper - Efectos de cartas
func _obtener_definicion_carta(nombre_carta: String) -> DefinicionCarta:
	# Usar CardDatabase (Autoload)
	var carta = CardDatabase.get_carta_por_nombre(nombre_carta)
	if carta:
		print("[Main] Definición encontrada: %s" % carta.nombre_carta)
		return carta
	
	# Buscar por nombre base (sin número)
	var partes = nombre_carta.split(" ")
	if partes.size() >= 2 and partes[-1].is_valid_int():
		partes.remove_at(partes.size() - 1)
		var nombre_base = " ".join(partes)
		carta = CardDatabase.get_carta_por_nombre(nombre_base)
		if carta:
			print("[Main] Definición encontrada (base): %s" % carta.nombre_carta)
			return carta
	
	push_warning("[Main] Carta sin definición: %s" % nombre_carta)
	return null


func _on_defensa_completada(cartas_usadas):
	var cartas_tipeadas: Array[Carta] = []
	for item in cartas_usadas:
		if item is Carta:
			cartas_tipeadas.append(item)
	
	var defensa_total = 0
	
	# Aplicar proteccion base
	defensa_total += estado_combate.proteccion_actual
	
	# Obtener bonus de aura de bloqueo permanente (Sumerio)
	if EffectResolver.contexto and EffectResolver.contexto.tiene_buff("aura_bloqueo_permanente"):
		var bonus = EffectResolver.contexto.obtener_valor_buff("aura_bloqueo_permanente")
		defensa_total += bonus * cartas_tipeadas.size()
		print("[Main] Aura bloqueo permanente: +%d (%d cartas)" % [bonus, cartas_tipeadas.size()])
	
	# Aura de protección por turnos (Sumeria 7, 10)
	if EffectResolver.contexto and EffectResolver.contexto.tiene_buff("aura_defensa_jugador"):
		var aura = EffectResolver.contexto.obtener_valor_buff("aura_defensa_jugador")
		defensa_total += aura
		print("[Main] Aura protección turnos: +%d" % aura)
	
	# Sumar defensa de cartas
	for carta in cartas_tipeadas:
		defensa_total += carta.DannoCarta
	
	print("[Main] Defensa total: %d (proteccion: %d + cartas: %d)" % [
		defensa_total,
		estado_combate.proteccion_actual,
		cartas_tipeadas.reduce(func(acc, c): return acc + c.DannoCarta, 0)
	])
	
	if defensa_total >= danno_enemigo_actual:
		mostrar_mensaje("Ataque bloqueado")
		if enemigo.quemadura_acumulada > 0:
			enemigo.vida_actual = max(0, enemigo.vida_actual - enemigo.quemadura_acumulada)
			enemigo.BarraVida.value = enemigo.vida_actual
			if enemigo.vida_actual <= 0:
				enemigo.dead()
	else:
		personaje.perder_vida()
		enemigo.quemadura_acumulada = 0
		mostrar_mensaje("Daño recibido, pierde 1 almavida")
	
	# Siempre llamar a _continuar_despues_de_defensa()
	_continuar_despues_de_defensa()


func _continuar_despues_de_defensa():
	if personaje.almavidas > 0:
		modo_defensa = false
		estado_combate.modo_defensa = false
		estado_combate.proteccion_actual = 0
		danno_enemigo_actual = 0
		
		# Escudo persistente desde RunManager
		if RunManager.has_persistent_shield():
			estado_combate.proteccion_actual = int(estado_combate.proteccion_actual * 0.5)
		
		turno_jugador = true
		actualizar_interfaz()
		mostrar_mensaje("Turno del jugador, robas una carta")
		
		# Verificar límite de mano antes de preparar ataque
		var rm = Engine.get_singleton("RunManager")
		if rm and rm.has_method("iniciar_turno_jugador"):
			# Esta función calcula cuántas cartas robar y llama a deck.robar_carta_animada()
			rm.iniciar_turno_jugador(deck)
		else:
			# Fallback legacy si RunManager no tiene la función
			mostrar_mensaje("Turno del jugador, robas una carta")
			deck.robar_carta_animada()
		
		# Preparar próximo ataque del enemigo
		var proximo_danno = enemigo.preparar_proximo_ataque()
		danno_enemigo_actual = proximo_danno
		label_daño_enemigo.text = "Ataque enemigo: %d" % proximo_danno
		
		mostrar_mensaje_flotante("⚔️ Turno de ataque", Color(0, 1, 0))


func _on_modo_defensa_cambiado(activado: bool):
	estado_combate.modo_defensa = activado
	# Actualizar UI
	if mazo_y_mano:
		mazo_y_mano.actualizar_boton_segun_seleccion()


# Funciones auxiliares al ataque y defensa
func _actualizar_contexto_combate(carta: Carta):
	if EffectResolver.contexto == null:
		EffectResolver.contexto = CombatContext.new()
	
	EffectResolver.contexto.carta_en_ejecucion = carta.NombreCarta
	EffectResolver.contexto.faccion_carta = carta.FaccionCarta
	EffectResolver.contexto.dano_base_carta = carta.DannoCarta
	
	# Forzar actualización de es_turno_defensa con valor actual
	EffectResolver.contexto.es_turno_defensa = modo_defensa
	
	# Resetear contador de cartas jugadas (para evitar overflow)
	if EffectResolver.contexto.cartas_jugadas_este_turno > 20:
		EffectResolver.contexto.cartas_jugadas_este_turno = 0
	EffectResolver.contexto.cartas_jugadas_este_turno += 1
	
	# Sincronizar inmunidades (eliminar strings vacíos)
	EffectResolver.contexto.inmunidades_enemigo = []
	for inm in enemigo.inmunidades:
		if inm != "":
			EffectResolver.contexto.inmunidades_enemigo.append(inm)
	
	# Sincronizar quemadura
	EffectResolver.contexto.quemadura_enemigo = enemigo.quemadura_acumulada
	
	# Debug para verificar
	print("[Main] Contexto: turno_defensa=%s, modo_defensa=%s, cartas_jugadas=%d" % [
		EffectResolver.contexto.es_turno_defensa,
		modo_defensa,
		EffectResolver.contexto.cartas_jugadas_este_turno
	])


func _aplicar_resultados_combate(resultados: Dictionary, carta: Carta):
	print("[Main] === Aplicando resultados ===")
	print("[Main] Carta: %s | Daño base: %d | Facción: %s" % [
		carta.NombreCarta, 
		carta.DannoCarta, 
		carta.FaccionCarta
	])
	print("[Main] Resultados: %s" % resultados)
	
	# Aplicar daño de carta
	var dano_a_aplicar = carta.DannoCarta
	
	# Verificar bonus de daño
	if resultados.has("bonus_dano"):
		dano_a_aplicar += resultados.bonus_dano
	
	# Verificar multiplicador
	if resultados.has("multiplicador_dano"):
		dano_a_aplicar = int(dano_a_aplicar * resultados.multiplicador_dano)
	
	# Aplicar daño SOLO si es turno de ataque y no es Sumeria
	if not modo_defensa and carta.FaccionCarta != "Sumeria":
		if enemigo.tiene_inmunidad(carta.FaccionCarta):
			mostrar_mensaje("¡Inmune! (%s)" % carta.FaccionCarta, "defensa")
		else:
			enemigo.recibir_danno(dano_a_aplicar)
			mostrar_mensaje("¡Ataque de %d puntos!" % dano_a_aplicar, "ataque")
			print("[Main] Daño aplicado: %d" % dano_a_aplicar)
	else:
		print("[Main] No se aplica daño: modo_defensa=%s o facción=Sumeria" % modo_defensa)
	
	# Aplicar efecto robo
	if resultados.has("robar") and resultados.robar > 0:
		var cantidad = resultados.robar
		var rm = Engine.get_singleton("RunManager")
		
		if rm and rm.has_method("aplicar_robo_por_efecto"):
			var realmente_robadas = rm.aplicar_robo_por_efecto(cantidad, deck)
			
			if realmente_robadas > 0:
				mostrar_mensaje("Robas %d carta(s)" % realmente_robadas)
				print("[Main] Efecto robo ejecutado: %d/%d cartas" % [
					realmente_robadas, cantidad
				])
			else:
				mostrar_mensaje("No hay cartas para robar")
				print("[Main] Efecto robo: mazo vacío o mano llena")
		else:
			if rm:
				var cartas_robadas = rm.aplicar_efecto_robo(cantidad)
				if cartas_robadas.size() > 0:
					mostrar_mensaje("Robas %d carta(s)" % cartas_robadas.size())
			else:
				push_error("[Main] RunManager no disponible para efecto robo")
	
	# Aplicar Efecto Proteccion
	if resultados.has("proteccion"):
		estado_combate.proteccion_actual += resultados.proteccion
		mostrar_mensaje("+%d Protección" % resultados.proteccion, "defensa")
		actualizar_iconos_ui()
	
	# Aplicar Quemadura
	if resultados.has("quemadura_aplicada"):
		var cantidad = resultados.quemadura_aplicada
		enemigo.aplicar_quemadura(cantidad)
		mostrar_mensaje("Quemadura aplicada: %d" % cantidad)
		actualizar_iconos_ui()
		print("[Main] Quemadura acumulada: %d" % enemigo.quemadura_acumulada)
	
	# Reduccion de daño Flat
	if resultados.has("dano_enemigo_reducido"):
		mostrar_mensaje("Daño enemigo reducido en %d" % resultados.dano_enemigo_reducido)
	
	# Reduccion %
	if resultados.has("porcentaje_aplicado"):
		var pct = int(resultados.porcentaje_aplicado * 100)
		mostrar_mensaje("Daño enemigo reducido %d%%" % pct)
	
	# efecturar cambios de reglas de juego
	if resultados.has("regla_aplicada"):
		match resultados.regla_aplicada:
			"no_robar":
				if EffectResolver.contexto:
					EffectResolver.contexto.puede_robar = false
				mostrar_mensaje("No robas próximo turno")
			"no_atacar":
				if EffectResolver.contexto:
					EffectResolver.contexto.puede_atacar = false
				mostrar_mensaje("No atacas próximo turno")
			"perder_turno":
				if EffectResolver.contexto:
					EffectResolver.contexto.turno_saltado = true
				mostrar_mensaje("Enemigo pierde turno")
	
	# Aplicar efectos de recuperarción a mano
	if resultados.has("recuperar_a_mano") and resultados.recuperar_a_mano > 0:
		var cantidad = resultados.recuperar_a_mano
		var recuperadas = 0
		
		for i in range(cantidad):
			var carta_recuperada = RunManager.recover_card_from_discard()
			if not carta_recuperada.is_empty():
				if carta_recuperada.has("escena_path") and carta_recuperada.escena_path != "":
					var scene = load(carta_recuperada.escena_path)
					if scene:
						var carta_visual = scene.instantiate() as Carta
						if carta_visual:
							carta_visual.set_datos(
								carta_recuperada.nombre,
								carta_recuperada.danno,
								carta_recuperada.faccion,
								carta_recuperada.efecto
							)
							if deck.mano.cartas_en_mano.size() < RunManager.get_max_hand_size():
								deck.mano.Agregar_carta(carta_visual)
								recuperadas += 1
		
		mostrar_mensaje("¡%d carta(s) recuperada(s) a mano!" % recuperadas)

	# Aplicar efectos de recuperación a mazo
	if resultados.has("recuperar_a_mazo") and resultados.recuperar_a_mazo > 0:
		var cantidad = deck.recuperar_del_descarte_visual(resultados.recuperar_a_mazo)
		mostrar_mensaje("¡%d carta(s) devuelta(s) al mazo!" % cantidad)
	
	print("[Main] Fin aplicación de resultados \n")



func _crear_instancia_carta_visual(card_data: Dictionary) -> Carta:
	# Validaciones básicas
	if not card_data.has("escena_path") or card_data.escena_path == "":
		push_warning("[Main] Carta sin escena_path: %s" % card_data.get("nombre", "desconocida"))
		return null
	
	var scene = load(card_data.escena_path)
	if not scene:
		push_warning("[Main] No se pudo cargar escena: %s" % card_data.escena_path)
		return null
	
	var carta = scene.instantiate() as Carta
	if not carta:
		push_warning("[Main] Falló instancia de carta: %s" % card_data.escena_path)
		return null
	
	# Datos básicos
	carta.set_datos(
		card_data.get("nombre", "Carta"),
		card_data.get("danno", 1),
		card_data.get("faccion", "Pueblo"),
		card_data.get("efecto", "Sin efecto")
	)
	carta.escena_path = card_data.escena_path
	
	# Mejora de cartas
	var tipo_mejora = card_data.get("estado_mejora", "base")
	var sprite_final = card_data.get("sprite_base", "")
	var dano_final = card_data.get("danno", 1)
	
	match tipo_mejora:
		"calma":
			dano_final += card_data.get("bonus_calma", 0)
			var sprite_calma = card_data.get("sprite_calma", "")
			if sprite_calma != "":
				sprite_final = sprite_calma
			
		"agresiva":
			dano_final += card_data.get("bonus_agresiva", 0)
			var sprite_agresiva = card_data.get("sprite_agresiva", "")
			if sprite_agresiva != "":
				sprite_final = sprite_agresiva
	
	# Aplicar valores finales
	carta.DannoCarta = dano_final
	
	# Asignar Sprite si existe
	if sprite_final != "" and ResourceLoader.exists(sprite_final):
		var texture = load(sprite_final) as Texture2D
		if texture:
			var sprite_node = carta.get_node_or_null("SpriteCarta")
			if sprite_node:
				sprite_node.texture = texture
	
	# Aplicar mejora de efectos
	var efectos_finales = card_data.get("efectos_base", [])

	if tipo_mejora == "calma" and card_data.get("efectos_calma"):
		if card_data.get("mejora_sobrescribe", false):
			# Reemplazar efectos completamente
			efectos_finales = card_data.efectos_calma
		else:
			# Modificar efectos existentes
			efectos_finales = _fusionar_efectos(efectos_finales, card_data.efectos_calma)
			
	elif tipo_mejora == "agresiva" and card_data.get("efectos_agresiva"):
		if card_data.get("mejora_sobrescribe", false):
			efectos_finales = card_data.efectos_agresiva
		else:
			efectos_finales = _fusionar_efectos(efectos_finales, card_data.efectos_agresiva)

	# Guardar efectos finales en la carta visual
	if carta.has_method("set_efectos"):
		carta.set_efectos(efectos_finales)
	
	return carta


func _fusionar_efectos(efectos_base: Array, efectos_mejora: Array) -> Array:
	var resultados = efectos_base.duplicate(true)
	
	for efecto_mejora in efectos_mejora:
		var id_mejora = efecto_mejora.get("id", "")
		var encontrado = false
		
		# Buscar si el efecto ya existe en la base
		for i in range(resultados.size()):
			if resultados[i].get("id") == id_mejora:
				# Fusionar parámetros: la mejora sobrescribe los valores
				for key in efecto_mejora.keys():
					if key != "id":
						resultados[i][key] = efecto_mejora[key]
				encontrado = true
				break
		
		# Si no existe, añadirlo como nuevo efecto
		if not encontrado:
			resultados.append(efecto_mejora.duplicate(true))
	
	return resultados


func _validar_sincronizacion_mazo(fuente: String) -> bool:
	var rm = Engine.get_singleton("RunManager")
	if not rm or not deck or not deck.mano:
		return true
	
	var logical_hand = rm.get_hand_size()
	var visual_hand = deck.mano.cartas_en_mano.size()
	
	if logical_hand != visual_hand:
		push_error("[SYNC %s] DESINCRONIZACIÓN: hand lógico=%d, visual=%d" % [
			fuente, logical_hand, visual_hand
		])
		return false
	
	return true


func _obtener_id_carta_unico(carta: Carta) -> String:
	var card_def = _obtener_definicion_carta(carta.NombreCarta)
	if card_def and card_def.id_carta != "":
		return card_def.id_carta
	
	# Fallback legacy
	return carta.NombreCarta.to_lower().replace(" ", "_").replace("'", "")


#func _mostrar_narrativa_ia(texto: String):
	#label_mensajes.modulate = Color(1, 1, 1, 1)
	#if label_mensajes.has_method("set_text_and_fit"):
		#label_mensajes.set_text_and_fit(texto)
	#else:
		#label_mensajes.text = texto


func turno_enemigo():
	turno_jugador = false
	mostrar_mensaje("Enemigo ataca")
	
	var dano_base = enemigo.preparar_proximo_ataque()
	var dano_final = dano_base
	
	# Efectos que amplifican el daño enemigo (Mapuche_08, Nok_08)
	if EffectResolver.contexto and EffectResolver.contexto.tiene_debuff("aura_dano_base_enemigo"):
		var aumento = EffectResolver.contexto.obtener_valor_debuff("aura_dano_base_enemigo")
		if aumento > 0:
			dano_final += aumento
			print("[Main] Aumento de daño: %d → %d (+%d)" % [dano_base, dano_final, aumento])
	
	# Efectos que aplican reducción de daño (Mapuche_06, Jomon_08, Sumeria_06, etc.)
	if EffectResolver.contexto and EffectResolver.contexto.tiene_debuff("reduccion_dano"):
		var reduccion = EffectResolver.contexto.obtener_valor_debuff("reduccion_dano")
		dano_final = max(0, dano_final - reduccion)
		print("[Main] Reducción flat: %d → %d (-%d)" % [dano_base, dano_final, reduccion])
	
	# Efectos de reduccion de daño % (Mapuche_09, Mapuche_02)
	if EffectResolver.contexto and EffectResolver.contexto.tiene_debuff("porcentaje_dano_enemigo"):
		var porcentaje = EffectResolver.contexto.obtener_valor_debuff("porcentaje_dano_enemigo")
		dano_final = int(dano_final * (1 - porcentaje))
		print("[Main] Reducción %%: %d → %d (%.0f%%)" % [dano_base, dano_final, porcentaje * 100])
	
	danno_enemigo_actual = dano_final
	label_daño_enemigo.text = "Ataque enemigo: %d" % dano_final
	
	await get_tree().create_timer(1.0).timeout
	enemigo.atacar()


func enemigo_ataca(_danno: int):
	modo_defensa = true
	estado_combate.cartas_defensa = []
	mazo_y_mano.set_modo_defensa(true)
	danno_enemigo_actual = _danno
	mostrar_mensaje_flotante("🛡️ Turno de defensa", Color(1, 0.5, 0))
	
	#narrative_manager.generar_narrativa("estado_critico", {
		#"fase": "enemigo_ataca",
		#"enemigo": enemigo.name,
		#"personaje": "Arca",
		#"carta_jugada": "ninguna",
		#"vida_jugador": personaje.almavidas * 2,
		#"vida_enemigo": enemigo.vida_actual
	#})


func actualizar_interfaz():
	mazo_y_mano.set_modo_defensa(estado_combate.modo_defensa)


# UI para iconos
func actualizar_iconos_ui():
	# Protección
	if estado_combate.proteccion_actual > 0:
		label_escudo.text = "%d" % estado_combate.proteccion_actual
		label_escudo.visible = true
		icono_escudo.visible = true
	else:
		label_escudo.visible = false
		icono_escudo.visible = false
	
	# Quemadura
	if enemigo.quemadura_acumulada > 0:
		label_quemadura.text = "x%d" % enemigo.quemadura_acumulada
		label_quemadura.visible = true
		icono_quemadura.visible = true
	else:
		label_quemadura.visible = false
		icono_quemadura.visible = false


# UI para mensajes
func mostrar_mensaje(texto: String, tipo: String = "normal"):
	if tipo in ["descarte", "robo"]:
		return
	
	label_mensajes.text = texto
	label_mensajes.modulate = Color(1, 1, 1, 1)
	
	match tipo:
		"ataque":
			label_mensajes.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
		"defensa":
			label_mensajes.add_theme_color_override("font_color", Color(0.2, 0.5, 1.0))


func mostrar_mensaje_flotante(texto: String, color: Color = Color(1, 1, 1)):
	label_flotante.text = texto
	label_flotante.modulate = color
	label_flotante.visible = true
	
	var viewport_size = get_viewport().get_visible_rect().size
	label_flotante.position = viewport_size / 2
	
	var duracion = 2.0
	var velocidad_y = -100.0
	
	for t in range(1, int(duracion * 60)):
		var delta = 1.0 / 60
		label_flotante.position = label_flotante.position + Vector2(0, velocidad_y * delta)
		
		var fade_progress = min(delta / duracion, 1.0)
		label_flotante.modulate = label_flotante.modulate.lerp(Color(1, 1, 1, 0), fade_progress)
		await get_tree().create_timer(delta).timeout
		
		if label_flotante.modulate.a <= 0.01:
			break
	
	label_flotante.visible = false


# Siguiente piso al ganar
func _on_enemigo_derrotado():
	print("¡Has ganado el combate!")
	
	var siguiente_piso = RunManager.get_current_floor() + 1
	RunManager.advance_floor()
	
	if siguiente_piso >= 5:
		_finalizar_juego()
		return
	
	var reward_gen = RewardGeneratorScript.new()
	var opciones = reward_gen.generate_reward_options(siguiente_piso, 3)
	reward_screen.mostrar(opciones)


# Selección de recompensa
func _aplicar_recompensa(recompensa: Dictionary) -> void:
	match recompensa.type:
		"carta":
			RunManager.add_card_to_deck(recompensa)
			
			if deck and deck.pila_mazo:
				var carta_visual = _crear_instancia_carta_visual(recompensa)
				if carta_visual:
					deck.pila_mazo.append(carta_visual)
					deck.mazo_cambiado.emit()
		
		"reliquia":
			RunManager.add_relic(recompensa.id)
		
		"curacion":
			RunManager.heal(recompensa.value)


func _on_transicion_completada() -> void:
	if ui_manager and ui_manager.has_method("iniciar_transicion"):
		ui_manager.iniciar_transicion("Avanzando al Piso %d" % RunManager.get_current_floor())
	
	await get_tree().create_timer(1.5).timeout
	
	if ui_manager and ui_manager.has_method("finalizar_transicion"):
		ui_manager.finalizar_transicion()
	
	_iniciar_combate()


func _finalizar_juego():
	$UIManager/FinCombate.visible = true
	$UIManager/FinCombate/Titulo.text = "¡VICTORIA ABSOLUTA!"
	$UIManager/FinCombate/Titulo.modulate = Color(0, 1, 0)
	$UIManager/FinCombate/BotonReset.text = "Nueva Run"
	$UIManager/FinCombate/BotonReset.visible = true


func _reiniciar_run_completa() -> void:
	RunManager.start_new_run()
	
	if deck:
		deck.pila_mazo.clear()
		deck.pila_descartes.clear()
	
	if deck.mano:
		for carta in deck.mano.cartas_en_mano.duplicate():
			if carta.get_parent() == deck.mano:
				deck.mano.remove_child(carta)
				carta.queue_free()
		deck.mano.cartas_en_mano.clear()
	
	if ui_manager:
		ui_manager.reiniciar_ui()
	
	$UIManager/FinCombate.visible = false
	panel_reliquias.get_node("Descripcion").text = ""
	
	# Resetear todos los estados de combate
	estado_combate.proteccion_actual = 0
	estado_combate.modo_defensa = false  # ← AGREGAR
	modo_defensa = false  # ← YA ESTÁ, pero confirmar
	turno_jugador = true  # ← CONFIRMAR
	danno_enemigo_actual = 0
	
	personaje.almavidas = 2
	if personaje.has_method("_actualizar_almavida"):
		personaje._actualizar_almavida()
	
	EffectResolver.resetear_contexto_combate()
	
	# Resetear UI de MazoYMano
	if mazo_y_mano:
		mazo_y_mano.set_modo_defensa(false)  # ← AGREGAR
	
	# Mostrar pantalla de reliquias
	panel_reliquias.visible = true
	_configurar_botones_reliquias()
	
	print("[Main] Run reiniciada completamente")


func _on_game_over():
	print("El jugador ha sido derrotado")
	$UIManager/FinCombate.visible = true
	$UIManager/FinCombate/Titulo.text = "Derrota"
	$UIManager/FinCombate/Titulo.modulate = Color(1, 0, 0)
	$UIManager/FinCombate/BotonReset.visible = true


# Procesos
func _process(_delta: float):
	actualizar_iconos_ui()
	
	var viewport_size = get_viewport().get_visible_rect().size
	label_mensajes.get_parent().position = Vector2(viewport_size.x - 1800, viewport_size.y - 1000)
	
	label_quemadura.position = Vector2(viewport_size.x - 780, viewport_size.y - 990)
	icono_quemadura.position = Vector2(viewport_size.x - 800, viewport_size.y - 970)
	label_escudo.position = Vector2(viewport_size.x - 225, viewport_size.y - 850)
	icono_escudo.position = Vector2(viewport_size.x - 280, viewport_size.y - 830)
	label_daño_enemigo.position = Vector2(viewport_size.x / 2, viewport_size.y - 690)
	$UIManager/FinCombate/BotonReset.position = Vector2(viewport_size.x / 2.15, viewport_size.y / 3)
