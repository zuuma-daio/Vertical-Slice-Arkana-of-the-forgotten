extends Node

var _cache_cartas: Dictionary = {}  # String para DefinicionCarta
var _cache_por_faccion: Dictionary = {}  # String para Array[DefinicionCarta]
var _cache_por_tag: Dictionary = {}  # String para Array[DefinicionCarta]
var _inicializado: bool = false

@warning_ignore("unused_signal")
signal cache_completado(cantidad: int)

func inicializar(ruta_base: String = "res://Recursos/DefinicionCartas/") -> void:
	if _inicializado:
		push_warning("[CardDatabase] Ya inicializado")
		return
	
	_cache_cartas.clear()
	_cache_por_faccion.clear()
	_cache_por_tag.clear()
	
	# Función interna para cargar recursivamente
	_cargar_cartas_desde_directorio(ruta_base)
	
	_inicializado = true
	
	# Reporte de carga
	print("[CardDatabase] Inicializado: %d cartas cargadas" % _cache_cartas.size())
	print("[CardDatabase] Facciones encontradas: %s" % str(_cache_por_faccion.keys()))
	
	emit_signal("cache_completado", _cache_cartas.size())


# funcion de apoyo a Inicializar
func _cargar_cartas_desde_directorio(ruta: String) -> void:
	var dir = DirAccess.open(ruta)
	if not dir:
		push_error("[CardDatabase] No se pudo acceder a: %s" % ruta)
		return
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var full_path = ruta + "/" + file_name
		
		if dir.current_is_dir():
			if file_name != "." and file_name != "..":
				_cargar_cartas_desde_directorio(full_path)
				
		elif file_name.ends_with(".tres"):
			var recurso = load(full_path) as DefinicionCarta
			
			if recurso:
				var errores = recurso.validar()
				for error in errores:
					if not "Tag no registrado" in error:
						push_error("[CardDatabase] %s: %s" % [recurso.nombre_carta, error])
				
				# Indexar por ID y nombre
				if recurso.id_carta != "":
					_cache_cartas[recurso.id_carta] = recurso
				if recurso.nombre_carta != "":
					_cache_cartas[recurso.nombre_carta] = recurso
				
				# Indexar por facción
				if not _cache_por_faccion.has(recurso.faccion):
					_cache_por_faccion[recurso.faccion] = []
				_cache_por_faccion[recurso.faccion].append(recurso)
				
				# Indexar por tags
				for tag in recurso.tags:
					if not _cache_por_tag.has(tag):
						_cache_por_tag[tag] = []
					_cache_por_tag[tag].append(recurso)
		
		file_name = dir.get_next()
	
	dir.list_dir_end()


# Búsqueda O(1)
func get_carta_por_id(id: String) -> DefinicionCarta:
	return _cache_cartas.get(id, null)


func get_carta_por_nombre(nombre: String) -> DefinicionCarta:
	return _cache_cartas.get(nombre, null)


func get_cartas_por_faccion(faccion: String) -> Array[DefinicionCarta]:
	return _cache_por_faccion.get(faccion, [])


func get_cartas_por_tag(tag: String) -> Array[DefinicionCarta]:
	return _cache_por_tag.get(tag, [])


func get_cartas_por_tags(tags: Array[String], modo: String = "any") -> Array[DefinicionCarta]:
	"""
	modo: "any" = tiene al menos 1 tag, "all" = tiene todos los tags
	"""
	var resultados = []
	
	if modo == "any":
		var vistas = {}
		for tag in tags:
			for carta in get_cartas_por_tag(tag):
				vistas[carta.id_carta] = carta
		resultados = vistas.values()
	else:  # "all"
		for carta in _cache_cartas.values():
			if carta is DefinicionCarta:
				var tiene_todos = true
				for tag in tags:
					if not carta.tags.has(tag):
						tiene_todos = false
						break
				if tiene_todos:
					resultados.append(carta)
	
	return resultados


func get_todos_los_tags() -> Array[String]:
	return _cache_por_tag.keys()


func get_todas_las_facciones() -> Array[String]:
	return _cache_por_faccion.keys()


func esta_inicializado() -> bool:
	return _inicializado


func limpiar_cache() -> void:
	_cache_cartas.clear()
	_cache_por_faccion.clear()
	_cache_por_tag.clear()
	_inicializado = false
