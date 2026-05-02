class_name CombatContext
extends RefCounted

# Jugador
var vidas_jugador: int = 2
var max_vidas_jugador: int = 2
var mano_actual: Array = []
var mazo_tamano: int = 0
var descarte_tamano: int = 0
var proteccion_actual: int = 0
var quemadura_jugador: int = 0

# Enemigo
var vida_enemigo: int = 100
var dano_enemigo_proximo: int = 12
var quemadura_enemigo: int = 0
var inmunidades_enemigo: Array[String] = []
var dano_base_enemigo: int = 12

# Turno
var es_turno_defensa: bool = false
var cartas_jugadas_este_turno: int = 0
var bloqueo_completo: bool = false
var turno_saltado: bool = false

# Reglas
var puede_robar: bool = true
var puede_atacar: bool = true
var limite_cartas_jugables: int = -1

# Buff y Debuff
var buffs: Dictionary = {}
var debuffs: Dictionary = {}

# Contexto
var carta_en_ejecucion: String = ""
var faccion_carta: String = ""
var dano_base_carta: int = 0


# Metodos de gestión
func agregar_buff(id: String, valor: Variant, turnos: int = 1) -> void:
	if not buffs.has(id):
		buffs[id] = { "valor": valor, "turnos_restantes": turnos }
	else:
		buffs[id].valor = valor
		buffs[id].turnos_restantes = max(buffs[id].turnos_restantes, turnos)

func obtener_valor_buff(id: String) -> Variant:
	if buffs.has(id):
		return buffs[id].valor
	return null

func tiene_buff(id: String) -> bool:
	return buffs.has(id)

func agregar_debuff(id: String, valor: Variant, turnos: int = 1) -> void:
	if not debuffs.has(id):
		debuffs[id] = { "valor": valor, "turnos_restantes": turnos }
	else:
		debuffs[id].valor = valor
		debuffs[id].turnos_restantes = max(debuffs[id].turnos_restantes, turnos)

func obtener_valor_debuff(id: String) -> Variant:
	if debuffs.has(id):
		return debuffs[id].valor
	return null

func tiene_debuff(id: String) -> bool:
	return debuffs.has(id)

func avanzar_turno() -> void:
	# Reducir duración de buffs
	var buffs_a_eliminar = []
	for id in buffs:
		buffs[id].turnos_restantes -= 1
		if buffs[id].turnos_restantes <= 0:
			buffs_a_eliminar.append(id)
	for id in buffs_a_eliminar:
		buffs.erase(id)
	
	# Reducir duración de debuffs (excepto permanentes)
	var debuffs_a_eliminar = []
	for id in debuffs:
		if debuffs[id].turnos_restantes > 0:  # No eliminar permanentes (-1)
			debuffs[id].turnos_restantes -= 1
			if debuffs[id].turnos_restantes <= 0:
				debuffs_a_eliminar.append(id)
	for id in debuffs_a_eliminar:
		debuffs.erase(id)
	
	# Resetear estado de turno
	cartas_jugadas_este_turno = 0
	bloqueo_completo = false
	turno_saltado = false

func obtener_bonus_bloqueo_permanente() -> int:
	if buffs.has("aura_bloqueo_permanente"):
		return buffs["aura_bloqueo_permanente"].valor
	return 0


func reiniciar_turno() -> void:
	cartas_jugadas_este_turno = 0
	bloqueo_completo = false
	turno_saltado = false
	puede_robar = true
	puede_atacar = true
	limite_cartas_jugables = -1

func duplicar() -> CombatContext:
	var copia = CombatContext.new()
	copia.vidas_jugador = vidas_jugador
	copia.max_vidas_jugador = max_vidas_jugador
	copia.mano_actual = mano_actual.duplicate()
	copia.mazo_tamano = mazo_tamano
	copia.descarte_tamano = descarte_tamano
	copia.proteccion_actual = proteccion_actual
	copia.quemadura_jugador = quemadura_jugador
	copia.vida_enemigo = vida_enemigo
	copia.dano_enemigo_proximo = dano_enemigo_proximo
	copia.quemadura_enemigo = quemadura_enemigo
	copia.inmunidades_enemigo = inmunidades_enemigo.duplicate()
	copia.dano_base_enemigo = dano_base_enemigo
	copia.es_turno_defensa = es_turno_defensa
	copia.cartas_jugadas_este_turno = cartas_jugadas_este_turno
	copia.bloqueo_completo = bloqueo_completo
	copia.turno_saltado = turno_saltado
	copia.puede_robar = puede_robar
	copia.puede_atacar = puede_atacar
	copia.limite_cartas_jugables = limite_cartas_jugables
	copia.buffs = buffs.duplicate(true)
	copia.debuffs = debuffs.duplicate(true)
	copia.carta_en_ejecucion = carta_en_ejecucion
	copia.faccion_carta = faccion_carta
	copia.dano_base_carta = dano_base_carta
	return copia
