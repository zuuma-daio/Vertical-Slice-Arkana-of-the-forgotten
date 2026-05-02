class_name NarrativeManager
extends Node

#var lore_mapuche = {}
#var templates = {}
#var historial_eventos = []
#var modelo_path: String
#var server_running = false
#var http: HTTPRequest
#var hc_http: HTTPRequest
#var system_prompt: String
#var lore_minificado = {}
#
#var llama_pid: int = -1
#
#var request_en_progreso = false
#var cola_solicitudes = []
#var puerto_escucha: int = 8081
#
#@warning_ignore("unused_signal")
#signal narrativa_generada(texto: String)
#
#func _ready():
	#http = HTTPRequest.new()
	#add_child(http)
	#http.connect("request_completed", Callable(self, "_on_request_completed"))
	#
	#hc_http = HTTPRequest.new()
	#add_child(hc_http)
	#hc_http.connect("request_completed", Callable(self, "_on_health_completed"))
	#
	#if not _cargar_datos_json():
		#return
		#
	#_iniciar_servidor_ia()
	#print("NarrativeManager listo")
#
#
## Iniciar servidor y esperar hasta que responda la API
#func _iniciar_servidor_ia():
	#if _puerto_ocupado(puerto_escucha):
		#print("NarrativeManager: puerto %d ocupado, buscando PID existente..." % puerto_escucha)
		#var pid_existente = _obtener_pid_por_puerto(puerto_escucha)
		#if pid_existente != -1:
			#print("NarrativeManager: matando proceso existente (PID: %d)" % pid_existente)
			#OS.kill(pid_existente)
			#await get_tree().create_timer(0.3).timeout  # Esperar cierre
	#
	#if server_running:
		#return 
	#
	#var base_path = OS.get_executable_path().get_base_dir()
	#var server_path = base_path.path_join("Narrative/llama-server.exe")
	#var model_path = base_path.path_join("Models/gemma-2b-it-Q4_K_M.gguf")
	#
	#if not FileAccess.file_exists(server_path):
		#push_error("llama-server.exe no encontrado.")
		#return
	#
	#if not FileAccess.file_exists(model_path):
		#push_error("Modelo no encontrado.")
		#return
	#
	#var args = [
		#"--model", model_path,
		#"--host", "127.0.0.1",
		#"--port", "8081",
		#"--ctx-size", "1024",
		#"--n-gpu-layers", "0",
		#"--threads", "4", 
		#"--temp", "0.6",
		#"--top-p", "0.9",
		#"--repeat-penalty", "1.1"
	#]
	#
	#llama_pid = OS.create_process(server_path, args, false)
	#print("IA iniciada. Esperando disponibilidad…")
	#
	#await get_tree().create_timer(1.0).timeout
	#_healthcheck_retry(1)
	#
	#if _puerto_ocupado(8081):
		#print("Servidor ya estaba corriendo, no se inicia otro.")
		#server_running = true
		#return
#
#
#func _healthcheck_retry(attempt):
	#var url = "http://127.0.0.1:8081/health"
	#var err = hc_http.request(url, [], HTTPClient.METHOD_GET)
	#
	#if err != OK:
		#print("Falló request healthcheck:", err)
	#
	#if attempt < 20:
		#await get_tree().create_timer(1.0).timeout
	#else:
		#push_error("El servidor no inició después de 20 intentos.")
#
#
## Manejo de respuesta de healthcheck
#func _on_health_completed(_result:int, response_code:int, _headers:Array, _body:PackedByteArray) -> void:
	#if response_code == 200:
		#server_running = true
		#print("Servidor listo")	
	#else:
		#print("Aún no disponible, reintentando…")
		#_healthcheck_retry(1)
#
#
#func _calentamiento_servidor():
	## Generar una narrativa corta y silenciosa
	#var payload = {
		#"prompt": "### Human:\nEscribe 2 frases sobre la montaña.\n### Assistant:\n",
		#"n_predict": 50,
		#"temperature": 0.6,
		#"stop": ["###", "<END>"]
	#}
	#
	#var headers = ["Content-Type: application/json"]
	#http.request("http://127.0.0.1:8081/completion", headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
#
#
## Generación narrativa (mantén la interfaz)
#func generar_narrativa(tipo_evento: String, variables: Dictionary):
	#if not server_running:
		#emit_signal("narrativa_generada", "Servidor de IA no disponible. Reintentando...")
		#_iniciar_servidor_ia()
		#return
	#
	#if not templates.has(tipo_evento):
		#emit_signal("narrativa_generada", "Formato desconocido.")
		#return
	#
	#var solicitud = {
		#"tipo": tipo_evento,
		#"variables": variables
	#}
	#
	#if request_en_progreso:
		## Añadir a cola si ya hay una solicitud en progreso
		#cola_solicitudes.append(solicitud)
		#emit_signal("narrativa_generada", "Narrativa en cola...")
	#else:
		## Procesar inmediatamente si no hay solicitud activa
		#_procesar_solicitud(solicitud)
#
#
## Nueva función para procesar solicitudes
#func _procesar_solicitud(solicitud):
	#request_en_progreso = true
	#
	#var prompt = _crear_prompt_mistral(solicitud.tipo, solicitud.variables)
	#
	#var payload = {
		#"prompt": prompt,
		#"n_predict": 45,
		#"temperature": 0.5,
		#"top_p": 0.8,
		#"repeat_penalty": 1.2,
		#"stop": ["###"]
	#}
	#
	#var headers = ["Content-Type: application/json"]
	#var url = "http://127.0.0.1:8081/completion"
	#
	#var err = http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload))
	#
	#if err != OK:
		#emit_signal("narrativa_generada", "Error al comunicarse con el servidor de IA.")
		#_finalizar_request()
#
#
## Manejar la respuesta de completion con streaming
#func _on_request_completed(_result, response_code, _headers, body):
	#if response_code != 200:
		#emit_signal("narrativa_generada", "Error HTTP %d" % response_code)
		#_finalizar_request()
		#return
	#
	#var raw = body.get_string_from_utf8()
	#
	#var jp = JSON.new()
	#if jp.parse(raw) != OK:
		#emit_signal("narrativa_generada", "Error: JSON inválido.")
		#_finalizar_request()
		#return
	#print("RAW:", raw)
#
	#var data = jp.data
	#var content = ""
#
	## extracción principal
	#if data.has("content") and typeof(data.content) == TYPE_STRING:
		#content = data.content
	#if content.strip_edges() == "" and data.has("stopping_word"):
		#content = str(data.stopping_word)
	#if content.strip_edges() == "":
		#if data.has("result") and data.result.has("content"):
			#content = str(data.result.content)
		#elif data.has("choices") and data.choices.size() > 0:
			#var first = data.choices[0]
			#if first.has("text"):
				#content = str(first.text)
			#elif first.has("content"):
				#content = str(first.content)
	#if content.strip_edges() == "":
		#content = "[Respuesta muy corta o detenida por servidor]"
#
	#
	## Limpieza y formateo
	#content = content.replace("### Assistant:", "").replace("### Assistant", "")
	#content = content.strip_edges().rstrip(".\"").strip_edges() + "."
	#
	## Limitar a 2 frases
	#var frases = content.split(".")
	#if frases.size() > 2:
		#content = frases[0] + ". " + frases[1] + "."
	#
	#emit_signal("narrativa_generada", content)
	#_finalizar_request()
#
#
## Nueva función para finalizar una solicitud y procesar la siguiente
#func _finalizar_request():
	#request_en_progreso = false
	#
	## Procesar siguiente solicitud en cola
	#if not cola_solicitudes.is_empty():
		#var siguiente_solicitud = cola_solicitudes.pop_front()
		## Pequeño retraso antes de la siguiente solicitud
		#await get_tree().create_timer(0.1).timeout
		#_procesar_solicitud(siguiente_solicitud)
#
#
#
## Carga JSON desde los archivos de datos narrativos
#func _cargar_datos_json() -> bool:
	#var paths = {
		#"lore": "res://data/lore_mapuche.json",
		#"templates": "res://data/narrative_templates.json"
	#}
	#
	## Cargar system prompt
	#var system_file = FileAccess.open("res://data/system_prompt.txt", FileAccess.READ)
	#if system_file:
		#system_prompt = system_file.get_as_text().strip_edges()
		#system_file.close()
	#else:
		#system_prompt = "Eres narrador misterioso."
	#
	## Cargar lore minificado
	#var lore_file = FileAccess.open("res://data/lore_minificado.json", FileAccess.READ)
	#if lore_file:
		#var lore_text = lore_file.get_as_text()
		#lore_file.close()
		#var lore_parser = JSON.new()
		#if lore_parser.parse(lore_text) == OK:
			#lore_minificado = lore_parser.data
	#
	#for nombre in paths.keys():
		#var ruta = paths[nombre]
		#var file = FileAccess.open(ruta, FileAccess.READ)
		#if not file:
			#push_error("No se pudo abrir: " + ruta)
			#return false
			#
		#var json_text = file.get_as_text()
		#file.close()
		#
		#var parser = JSON.new()
		#var result = parser.parse(json_text)
		#
		#if result != OK:
			#push_error("Error al parsear JSON (%s): %s" % [nombre, parser.get_error_message()])
			#return false
			#
		#if nombre == "lore":
			#lore_mapuche = parser.data
		#elif nombre == "templates":
			#templates = parser.data
			#
	#if lore_mapuche.is_empty() or templates.is_empty():
		#push_error("Archivos JSON vacíos o no cargados.")
		#return false
		#
	#print("Lore mapuche cargado:", lore_mapuche.keys())
	#print("Templates cargados:", templates.keys())
	#return true
#
#
## Crea el prompt con formato Mistral
#func _crear_prompt_mistral(tipo_evento: String, variables: Dictionary) -> String:
	#if not templates.has(tipo_evento):
		#return "Evento desconocido."
	#
	#var template = templates[tipo_evento]
	#var instruction = template.prompt if template.has("prompt") else ""
	#
	## Reemplazar variables
	#for clave in variables:
		#instruction = instruction.replace("{" + clave + "}", str(variables[clave]))
	#
	## system prompt + prompt dinamico
	#var prompt = system_prompt + "\n\n### Evento\n"
	#
	## Añadir contexto relevante
	#if variables.has("fase"):
		#prompt += "Fase: " + variables.fase + "\n"
	#if variables.has("enemigo"):
		#prompt += "Enemigo: " + variables.enemigo + "\n"
	#if variables.has("personaje"):
		#prompt += "Personaje: " + variables.personaje + "\n"
	#if variables.has("carta_jugada"):
		#prompt += "Carta jugada: " + variables.carta_jugada + "\n"
	#if variables.has("vida_jugador"):
		#prompt += "Vida jugador: " + str(variables.vida_jugador) + "\n"
	#if variables.has("vida_enemigo"):
		#prompt += "Vida enemigo: " + str(variables.vida_enemigo) + "\n"
	#prompt += "\n### Instrucción\n" + instruction + "\n\n### Respuesta:\n"
	#
	#return prompt
#
#
#func _exit_tree():
	#if llama_pid != -1:
		#print("NarrativeManager: terminando proceso LLM (PID: %d)..." % llama_pid)
		#OS.kill(llama_pid)
		#
		#var timeout_ms = 500
		#var start = Time.get_ticks_msec()
		#while Time.get_ticks_msec() - start < timeout_ms:
			#if not _puerto_ocupado(puerto_escucha):
				#print("NarrativeManager: puerto %d liberado correctamente" % puerto_escucha)
				#llama_pid = -1
				#return
			#OS.delay_usec(10000)
		#
		#if OS.get_name() == "Windows" and _puerto_ocupado(puerto_escucha):
			#print("NarrativeManager: usando taskkill para puerto %d (PID %d)" % [puerto_escucha, llama_pid])
			#OS.execute("cmd.exe", ["/C", "taskkill /F /PID %d" % llama_pid])
			#llama_pid = -1
#
#
#
#func _puerto_ocupado(puerto: int) -> bool:
	#var sock = StreamPeerTCP.new()
	#var err = sock.connect_to_host("127.0.0.1", puerto)
	#if err == OK:
		#sock.disconnect_from_host()
		#return true
	#return false
#
#
#func _obtener_pid_por_puerto(puerto: int) -> int:
	#if OS.get_name() != "Windows":
		#return -1
	#
	## Ejecutar netstat para encontrar PID asociado al puerto
	#var salida = []
	#var err = OS.execute("cmd.exe", ["/C", "netstat -ano | findstr :%d" % puerto], salida)
	#if err != OK or salida.is_empty():
		#return -1
	#
	#var linea = salida[0]
	#var partes = linea.split(" ", false)
	#var partes_filtradas: Array = []
	#for s in partes:
		#if s != "":
			#partes_filtradas.append(s)
	#partes = partes_filtradas
	#
	#if partes.size() >= 5:
		#return partes[-1].to_int()
	#return -1
