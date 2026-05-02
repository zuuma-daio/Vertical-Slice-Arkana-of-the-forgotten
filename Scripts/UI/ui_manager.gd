class_name UIManager
extends Control

@onready var fondo: TextureRect = $Fondo
@onready var label_flotante: Label = $LabelFlotante
@onready var efectos_root: Control = $EfectosCombate
@onready var dano_jugador_texture: TextureRect = efectos_root.get_node("DannoJugador")
@onready var ataque_enemigo_texture: TextureRect = efectos_root.get_node("AtaqueEnemigo")



# Tween UNICO para el fondo
var tween_fondo: Tween
# Tweenes independientes para impactos
var tween_danno: Tween
var tween_ataque: Tween

func _ready() -> void:
	if not fondo:
		push_error("[UIManager] Fondo no asignado o no encontrado")
	else:
		print("[UIManager] Fondo asignado correctamente")
		
	if not dano_jugador_texture:
		dano_jugador_texture = $EfectosCombate/DannoJugador
	if not ataque_enemigo_texture:
		ataque_enemigo_texture = $EfectosCombate/AtaqueEnemigo
		
	if dano_jugador_texture:
		dano_jugador_texture.visible = false
		dano_jugador_texture.modulate.a = 0
	if ataque_enemigo_texture:
		ataque_enemigo_texture.visible = false
		ataque_enemigo_texture.modulate.a = 0
		
	_reiniciar_estado_visual()


func _reiniciar_estado_visual():
	restaurar_fondo()
	if dano_jugador_texture:
		dano_jugador_texture.visible = false
		dano_jugador_texture.modulate.a = 0
	if ataque_enemigo_texture:
		ataque_enemigo_texture.visible = false
		ataque_enemigo_texture.modulate.a = 0
		
	tween_fondo = null
	tween_danno = null
	tween_ataque = null

func reiniciar_ui():
	_reiniciar_estado_visual()


func _on_decision_tomada(decision: Dictionary) -> void:
	if not decision: return
	
	match decision.get("accion", ""):
		"oscurecer_fondo":
			oscurecer_fondo()
			
		"impacto_jugador":
			impacto_jugador()
			
		"impacto_enemigo":
			impacto_enemigo()
			
		"ninguna":
			restaurar_fondo()


func oscurecer_fondo():
	if not fondo: return
	
	if tween_fondo:
		tween_fondo.kill()
		
	tween_fondo = create_tween()
	tween_fondo.tween_property(fondo, "modulate", Color(0.15,0.15,0.15), 0.28)
	tween_fondo.tween_interval(0.18)
	tween_fondo.tween_property(fondo, "modulate", Color(1,1,1), 0.35)


func restaurar_fondo():
	if tween_fondo:
		tween_fondo.kill()
		
	if fondo:
		fondo.modulate = Color(1,1,1)


func impacto_jugador():
	if not dano_jugador_texture: return
	
	if tween_danno:
		tween_danno.kill()
		
	dano_jugador_texture.visible = true
	dano_jugador_texture.modulate = Color(1,1,1,0)
	
	tween_danno = create_tween()
	tween_danno.tween_property(dano_jugador_texture, "modulate:a", 1.0, 0.08)
	tween_danno.tween_property(dano_jugador_texture, "modulate:a", 0.0, 0.22)
	tween_danno.tween_callback(Callable(self, "ocultar_impacto_jugador"))


func ocultar_impacto_jugador():
	dano_jugador_texture.visible = false


func impacto_enemigo():
	if not ataque_enemigo_texture: return
	
	if tween_ataque:
		tween_ataque.kill()

	ataque_enemigo_texture.visible = true
	ataque_enemigo_texture.modulate = Color(1,1,1,0)

	tween_ataque = create_tween()
	tween_ataque.tween_property(ataque_enemigo_texture, "modulate:a", 1.0, 0.09)
	tween_ataque.tween_property(ataque_enemigo_texture, "modulate:a", 0.0, 0.28)
	tween_ataque.tween_callback(Callable(self, "ocultar_impacto_enemigo"))

	_shake_ui()


func ocultar_impacto_enemigo():
	ataque_enemigo_texture.visible = false


func _shake_ui():
	var original = position
	var tw = create_tween()
	tw.tween_property(self, "position", original + Vector2(6, -4), 0.04)
	tw.tween_property(self, "position", original + Vector2(-5, 3), 0.04)
	tw.tween_property(self, "position", original, 0.04)


func ejecutar_efecto(decision: Dictionary) -> void:
	_on_decision_tomada(decision)


func mostrar_ataque_enemigo(danno):
	print("UIManager: Ataque enemigo recibido:", danno)
	impacto_enemigo()


func mostrar_dano_jugador(danno):
	print("UIManager: Daño al jugador:", danno)
	impacto_jugador()


func animar_inicio_turno():
	print("UIManager: Inicio turno jugador")
	restaurar_fondo()


func animar_modo_peligro():
	print("UIManager: Modo peligro enemigo")
	oscurecer_fondo()

func iniciar_transicion(mensaje: String = "Cargando...") -> void:
	# Si existe PantallaTransicion
	if has_node("PantallaTransicion"):
		var screen = get_node("PantallaTransicion")
		if screen.has_node("Label") and screen.get_node("Label").has_method("set_text"):
			screen.get_node("Label").text = mensaje
		screen.visible = true
		return
	
	# Fallback elegante (oscurecer fondo + texto flotante)
	if fondo:
		fondo.modulate = Color(0.05, 0.05, 0.1, 0.85)
	if label_flotante:  # ← Ahora sí tiene valor
		label_flotante.text = mensaje
		label_flotante.visible = true
		label_flotante.modulate = Color(1, 1, 1, 1)
		var viewport_size = get_viewport().get_visible_rect().size
		label_flotante.position = viewport_size / 2


func finalizar_transicion() -> void:
	# Restaurar estado original
	if has_node("PantallaTransicion"):
		get_node("PantallaTransicion").visible = false
	
	if fondo:
		fondo.modulate = Color(1, 1, 1, 1)
	if label_flotante:
		label_flotante.visible = false
