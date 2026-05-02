@tool
class_name Enemigo extends Node2D

@export var vida_maxima: int = 100
@export var vida_actual: int = 100

@onready var SpriteEnemigo: Sprite2D = $SpriteEnemigo
@onready var BarraVida: ProgressBar = $ColorRect/ProgressBar
@onready var Nombre: Label = $Nombre
@onready var Numero: Label = $Numero
@onready var Tarot: Label = $Tarot
@onready var icono_inmunidad: Sprite2D = $IconoInmunidad
@onready var label_inmunidad: Label = $LabelInmunidad

var danno_ataque: int = 0  
var ataques: Array[int] = [12, 14, 16, 18, 20]
var quemadura_acumulada: int = 0
var proximo_danno: int = 0
var inmunidades: Array[String] = [] 
var inmunidades_duraccion: Dictionary = {}  
var nombre: String = "Gran terror, Orea"


var iconos_inmunidad = {
	"Mapuche": preload("res://sprites/oficiales/iconos/palomapuche.png"),
	"Sumeria": preload("res://sprites/oficiales/iconos/palosumerio.png"),
	"Nok": preload("res://sprites/oficiales/iconos/Nok_icon_RS.webp"),
	"Jomon": preload("res://sprites/oficiales/iconos/Jomon_icon_RS.webp"),
}

signal enemigo_ataca(danno: int)
@warning_ignore("unused_signal")
signal derrotado()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	BarraVida.max_value = vida_maxima
	BarraVida.value = vida_actual
	# posicion inicial (una sola vez)
	var viewport_size = get_viewport().get_visible_rect().size
	position = Vector2(viewport_size.x / 1.8, viewport_size.y / 4)


func configurar_desde_datos(config: Dictionary) -> void:
	# Acceso seguro a diccionario + conversión de arrays tipados
	nombre = config.get("name", "Enemigo Desconocido")
	Nombre.text = nombre
	
	var vida = config.get("health", 100)
	vida_maxima = vida
	vida_actual = vida
	BarraVida.max_value = vida_maxima
	BarraVida.value = vida_actual
	
	var damage = config.get("damage", 15)
	ataques = [damage]  # Daño fijo por diseño (no progresivo)
	
	# Convertir Array no tipado → Array[String] tipado
	var immunities_raw = config.get("immunities", [])
	inmunidades.clear()
	for item in immunities_raw:
		if typeof(item) == TYPE_STRING:
			inmunidades.append(item)
	
	var sprite_path = config.get("sprite_path", "")
	if sprite_path != "" and ResourceLoader.exists(sprite_path):
		var texture = load(sprite_path) as Texture2D
		if texture and SpriteEnemigo:
			SpriteEnemigo.texture = texture
	
	_actualizar_ui_inmunidades()
	
	print("[Enemigo] Configurado: %s (daño: %d, inmunidades: %s)" % [
		nombre,
		damage,
		str(inmunidades)
	])


func _actualizar_ui_inmunidades() -> void:
	if inmunidades.is_empty():
		icono_inmunidad.visible = false
		label_inmunidad.visible = false
		return
	
	var faccion = inmunidades[0]  # Mostrar primera inmunidad
	if iconos_inmunidad.has(faccion):
		icono_inmunidad.texture = iconos_inmunidad[faccion]
	icono_inmunidad.visible = true
	label_inmunidad.text = "Inmunidad a\npalo %s" % faccion
	label_inmunidad.visible = true


func recibir_danno(danno: int):
	vida_actual = max(0, vida_actual - danno)
	BarraVida.value = vida_actual
	if vida_actual <= 0:
		dead()


func dead():
	print("El enemigo ha sido derrotado")
	emit_signal("derrotado")

func preparar_proximo_ataque() -> int:
	proximo_danno = ataques[randi() % ataques.size()]
	print("Enemigo prepara ataque de %d de daño" % proximo_danno)
	return proximo_danno

func atacar():
	if vida_actual <= 0:
		return  
	
	var danno = proximo_danno
	
	danno_ataque = danno
	print("Enemigo ataca con %d de daño" % danno)
	enemigo_ataca.emit(danno)


func aplicar_quemadura(cantidad: int = 1):
	quemadura_acumulada += cantidad
	print("Enemigo tiene %d de quemadura acumulada" % quemadura_acumulada)


func aplicar_inmunidad(faccion: String):
	if not inmunidades.has(faccion):
		inmunidades.append(faccion)
	if iconos_inmunidad.has(faccion):
		icono_inmunidad.texture = iconos_inmunidad[faccion]
	icono_inmunidad.visible = true
	label_inmunidad.text = "Inmunidad a\npalo %s" % faccion
	label_inmunidad.visible = true


func tiene_inmunidad(faccion: String) -> bool:
	return inmunidades.has(faccion)


func limpiar_inmunidad():
	inmunidades = []
	icono_inmunidad.visible = false
	label_inmunidad.visible = false


func resetear_combate() -> void:
	# Resetear vida
	vida_actual = vida_maxima
	BarraVida.value = vida_maxima
	
	# Resetear estados temporales
	quemadura_acumulada = 0
	proximo_danno = 0
	inmunidades_duraccion.clear()
	
	# Resetear UI
	_actualizar_ui_inmunidades()
	
	print("[Enemigo] Combate reseteado: %s (vida: %d/%d, inmunidades: %s)" % [
		nombre, vida_actual, vida_maxima, str(inmunidades)
	])


func resetear_inmunidades_por_combate() -> void:
	# Solo mantener inmunidades base del FloorManager y eliminar inmunidades añadidas dinámicamente
	var inmunidades_base = inmunidades.duplicate()
	inmunidades.clear()
	for inm in inmunidades_base:
		inmunidades.append(inm)
	_actualizar_ui_inmunidades()
	print("[Enemigo] Inmunidades reseteadas: %s" % str(inmunidades))







# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	position = Vector2(viewport_size.x / 1.8, viewport_size.y / 4)
	
