@tool
class_name CartaJomon
extends Carta

func jugar(_jugador, _objetivo) -> Dictionary:
	#print("%s: Roba 1 carta y se queda en mano" % NombreCarta)
	#
	#if _jugador.deck:
		#_jugador.deck.robar_carta()
	#else:
		#print("Jugador no tiene deck")
	#
	#if _jugador.deck and _jugador.deck.has_method("mezclar_descartes"):
		#_jugador.deck.mezclar_descartes()
		
	return {
		"danno": DannoCarta,
		"se_descarta": true
	}
