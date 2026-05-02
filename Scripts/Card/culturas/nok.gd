@tool
class_name CartaNok
extends Carta


func jugar(_jugador, _objetivo) -> Dictionary:
	#var _danno_base = DannoCarta
	#
	#if randf() < 1:
		#print("%s: Aplica quemadura al enemigo!" % NombreCarta)
		#
		#for i in range(DannoCarta):
			#if _objetivo.has_method("aplicar_quemadura"):
				#_objetivo.aplicar_quemadura()
			#else:
				#_objetivo.meta_quemadura = true
	#else:
		#print("%s: Ataca sin efecto secundario" % NombreCarta)
	
	return {
		"danno": DannoCarta,
		"se_descarta": true
	}
