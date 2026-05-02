class_name EfectoRetrasado
extends EffectComponent

@export var turnos_retraso: int = 2
@export var efecto_contenido: EffectComponent
@export var accion: String = "barajar_descarte"  # "barajar_descarte", "aplicar_efecto"
@export var cantidad: int = 6

func aplicar_efecto(_contexto: CombatContext) -> Dictionary:
	if Engine.has_singleton("EffectResolver"):
		var resolver = Engine.get_singleton("EffectResolver")
		resolver.registrar_efecto_retrasado({
			"turnos_restantes": turnos_retraso,
			"accion": accion,
			"cantidad": cantidad,
			"efecto": efecto_contenido
		})
	return { 
		"efecto_retrasado": true,
		"turnos_retraso": turnos_retraso,
		"accion": accion
	}

func obtener_descripcion() -> String:
	return "Al final de %d turno(s): %s" % [turnos_retraso, accion]

func duplicar() -> EffectComponent:
	var copia = EfectoRetrasado.new()
	copia.turnos_retraso = turnos_retraso
	copia.cantidad = cantidad
	copia.accion = accion
	if efecto_contenido and efecto_contenido.has_method("duplicar"):
		copia.efecto_contenido = efecto_contenido.duplicar()
	return copia
