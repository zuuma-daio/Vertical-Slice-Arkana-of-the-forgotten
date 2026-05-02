class_name EfectoReduccion
extends EffectComponent

@export var reduccion: int = 1
@export var duracion: int = 1  # turnos (0 = permanente)
@export var objetivo: String = "enemigo"  # "enemigo", "jugador"
@export var estadistica: String = "dano_base"  # "dano_base", "dano_proximo"

func aplicar_efecto(contexto: CombatContext) -> Dictionary:
	if objetivo == "enemigo":
		if duracion == 0:  # Permanente
			contexto.agregar_debuff("reduccion_dano_permanente", reduccion, -1)
		else:
			contexto.agregar_debuff("reduccion_dano", reduccion, duracion)
		return { "dano_enemigo_reducido": reduccion }
	else:
		contexto.agregar_buff("reduccion_dano_recibido", reduccion, duracion)
		return { "dano_jugador_reducido": reduccion }

func obtener_descripcion() -> String:
	if duracion == 0:
		return "Reduce %d de daño del %s permanentemente" % [reduccion, objetivo]
	return "Reduce %d de daño del %s por %d turno(s)" % [reduccion, objetivo, duracion]

func duplicar() -> EffectComponent:
	var copia = EfectoReduccion.new()
	copia.id_efecto = id_efecto
	copia.descripcion = descripcion
	copia.reduccion = reduccion
	copia.duracion = duracion
	copia.objetivo = objetivo
	copia.estadistica = estadistica
	return copia
