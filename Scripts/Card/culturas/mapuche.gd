@tool
class_name CartaMapuche
extends Carta

func jugar(_jugador, _objetivo) -> Dictionary:
	
	#print("%s activa su efecto: roba %d cartas" % [NombreCarta, DannoCarta])
	#if _jugador.deck:
		#for i in range(DannoCarta):
			#_jugador.deck.robar_carta()
	#else:
		#print("Jugador no tiene deck")
	
	return {
		"danno": DannoCarta,
		"se_descarta": true
	}
