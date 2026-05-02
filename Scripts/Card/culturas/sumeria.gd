@tool
class_name CartaSumeria
extends Carta

func jugar(_jugador, _objetivo) -> Dictionary:
#
	#print("%s: Aumenta defensa o cura" % NombreCarta)
	#
	#if _jugador.personaje:
		#_jugador.escudo += DannoCarta
		#print("Escudo actual: %d" % _jugador.escudo)
	
	return {
		"danno": DannoCarta,
		"se_descarta": true
	}
