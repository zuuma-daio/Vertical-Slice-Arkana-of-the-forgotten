@tool
class_name Carta
extends Node2D

signal mouse_entered(carta: Carta)
signal mouse_exited(carta: Carta)
signal seleccion_cambiada(estado: bool)

@export var NombreCarta: String = "nombre carta"
@export var DannoCarta: int = 1
@export var FaccionCarta: String = "Pueblo"
@export var EfectoCarta: String = "Efecto base"
@export var escala_base: float = 1.2

var escena_path: String = ""
var seleccionada: bool = false
var tween_brillo: Tween = null
var tween_escala: Tween = null

@onready var nameCarta: Label = $SpriteCarta/LabelNombre
@onready var damageCarta: Label = $"SpriteCarta/LabelDaño"
@onready var factionCarta: Label = $SpriteCarta/LabelFaccion
@onready var effectCarta: RichTextLabel = $SpriteCarta/LabelEfecto
@onready var Brillo: Sprite2D = $BrilloFondo
@onready var fuego_animado = $FuegoAnimado


func _ready() -> void:
	$Area2D.mouse_entered.connect(func(): emit_signal("mouse_entered", self))
	$Area2D.mouse_exited.connect(func(): emit_signal("mouse_exited", self))
	scale = Vector2(escala_base, escala_base)


# Actualiza los Label con los valores actuales
func _update_graphics():
	if nameCarta:
		nameCarta.text = NombreCarta
	if damageCarta:
		damageCarta.text = str(DannoCarta)
	if factionCarta:
		factionCarta.text = FaccionCarta
	if effectCarta and is_instance_valid(effectCarta):
		effectCarta.text = str(EfectoCarta)


# Método público para cambiar todos los valores a la vez
func set_datos(nombre: String, danno: int, faccion: String, efecto: String):
	NombreCarta = nombre
	DannoCarta    = danno
	FaccionCarta = faccion
	EfectoCarta  = efecto
	_update_graphics()


func _process(_delta: float) -> void:
	if is_inside_tree(): 
		_update_graphics()


func jugar(_jugador, _objetivo) -> Dictionary:
	push_warning("Carta.jugar() no implementado: ", NombreCarta)
	return {
		"danno": DannoCarta,
		"se_descarta": true
	}


func Animar_brillo():
	if seleccionada:
		return
	if tween_brillo:
		tween_brillo.stop()
	tween_brillo = null
	if is_instance_valid(Brillo):
		Brillo.modulate = Color(1, 1, 1, 0.6)


func Eliminar_brillo():
	if tween_brillo:
		tween_brillo.stop()
	tween_brillo = null
	if is_instance_valid(Brillo):
		Brillo.modulate = Color(1, 1, 1, 0)


func Seleccionar():
	if seleccionada:
		return
	seleccionada = true
	
	Eliminar_brillo()
	if tween_brillo:
		tween_brillo.stop()
	tween_brillo = null

	tween_brillo = create_tween().set_loops().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween_brillo.tween_property(Brillo, "modulate", Color(1, 1, 0, 0.8), 0.6)
	tween_brillo.tween_property(Brillo, "modulate", Color(1, 1, 0, 0.3), 0.6)
	seleccion_cambiada.emit(true)


func Deseleccionar():
	seleccionada = false
	Eliminar_brillo()
	if is_inside_tree() and is_instance_valid(get_viewport()):
		var mouse_pos = get_viewport().get_mouse_position()
		if mouse_pos.distance_to(global_position) < 50:
			Animar_brillo()
	seleccion_cambiada.emit(false)


#animacion de descarte
func iniciar_quemado():
	fuego_animado.position = Vector2.ZERO
	fuego_animado.visible = true
	fuego_animado.play("quemar")


func detener_quemado():
	if fuego_animado:
		fuego_animado.stop()
		fuego_animado.visible = false


func aplicar_zoom(escala: float):
	if tween_escala:
		tween_escala.stop()
	tween_escala = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween_escala.tween_property(self, "scale", Vector2(escala, escala), 0.15)


func restaurar_zoom():
	if tween_escala:
		tween_escala.stop()
	tween_escala = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween_escala.tween_property(self, "scale", Vector2(escala_base, escala_base), 0.15)


func _on_area_2d_mouse_entered() -> void:
	mouse_entered.emit(self)
	if not seleccionada:
		Animar_brillo()


func _on_area_2d_mouse_exited() -> void:
	mouse_exited.emit(self)
	if not seleccionada:
		Eliminar_brillo()
