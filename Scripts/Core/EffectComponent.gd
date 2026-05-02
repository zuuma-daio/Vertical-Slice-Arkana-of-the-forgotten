class_name EffectComponent
extends Resource

@export var id_efecto: String = ""
@export var descripcion: String = ""
@export var valor_base: int = 0
@export var duracion_turnos: int = 0

# Señales para notificar aplicación de efectos
@warning_ignore("unused_signal")
signal efecto_aplicado(datos: Dictionary)
@warning_ignore("unused_signal")
signal efecto_fallo(motivo: String)

# Método principal de efectos
func aplicar_efecto(_contexto: CombatContext) -> Dictionary:
	push_warning("EffectComponent.aplicar_efecto() no implementado en: ", get_class())
	return {}

# Validar si el efecto puede aplicarse 
func puede_aplicarse(_contexto: CombatContext) -> bool:
	return true

# Obtener descripción formateada
func obtener_descripcion() -> String:
	return descripcion

# Ejecutar lógica post-aplicación para efectos con duración
func post_aplicacion(_contexto: CombatContext) -> void:
	pass

# Clonar efecto para Resources
func duplicar() -> EffectComponent:
	var copia = get_script().new()
	copia.id_efecto = id_efecto
	copia.descripcion = descripcion
	copia.valor_base = valor_base
	copia.duracion_turnos = duracion_turnos
	return copia
