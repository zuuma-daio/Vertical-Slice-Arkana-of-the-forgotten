class_name EfectoPorcentaje
extends EffectComponent

@export var porcentaje: float = 0.25  # 0.25 = 25%
@export var estadistica: String = "dano_enemigo"  # "dano_enemigo", "bloqueo"
@export var duracion: int = 3  # turnos
@export var objetivo: String = "enemigo"  # "enemigo", "jugador"

func aplicar_efecto(contexto: CombatContext) -> Dictionary:
	var id_buff = "porcentaje_%s_%s" % [estadistica, objetivo]
	contexto.agregar_debuff(id_buff, porcentaje, duracion)
	return { 
		"porcentaje_aplicado": porcentaje,
		"estadistica": estadistica,
		"duracion": duracion
	}

func obtener_descripcion() -> String:
	return "Reduce %s en %d%% por %d turno(s)" % [estadistica, int(porcentaje * 100), duracion]

func duplicar() -> EffectComponent:
	var copia = EfectoPorcentaje.new()
	copia.porcentaje = porcentaje
	copia.estadistica = estadistica
	copia.duracion = duracion
	copia.objetivo = objetivo
	return copia
