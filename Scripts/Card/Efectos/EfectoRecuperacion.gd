class_name EfectoRecuperacion
extends EffectComponent

@export var cantidad: int = 1
@export var origen: String = "descarte"  # "descarte", "exilio", "mazo"
@export var destino: String = "mazo"  # "mazo", "mano"

func aplicar_efecto(_contexto: CombatContext) -> Dictionary:
	return {
		"recuperar_a_mano": cantidad if destino == "mano" else 0,
		"recuperar_a_mazo": cantidad if destino == "mazo" else 0,
		"origen": origen
	}

func obtener_descripcion() -> String:
	return "Recupera %d carta(s) del %s al %s" % [cantidad, origen, destino]

func duplicar() -> EffectComponent:
	var copia = EfectoRecuperacion.new()
	copia.id_efecto = id_efecto
	copia.descripcion = descripcion
	copia.cantidad = cantidad
	copia.origen = origen
	copia.destino = destino
	return copia
