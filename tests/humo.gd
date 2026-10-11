extends Node
## Prueba de humo: recorre todas las pantallas del juego real simulando lo que
## haría un jugador (resuelve cada reto, abre la galería, responde preguntas).
##   godot --headless --path . -- --prueba-humo
##   godot --path . -- --capturas=/carpeta    (además guarda capturas PNG)
##   ... --niveles=1,9                         (sólo esos niveles)
## Usa un archivo de progreso aparte, así que no toca el progreso del jugador.

var _carpeta := ""
var _errores := 0
var _niveles: Array = []


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--capturas="):
			_carpeta = a.trim_prefix("--capturas=")
		elif a.begins_with("--niveles="):
			for n in a.trim_prefix("--niveles=").split(","):
				_niveles.append(int(n) - 1)
	_recorrer.call_deferred()


func _esperar(cuadros := 4) -> void:
	for i in cuadros:
		await get_tree().process_frame


func _foto(nombre: String) -> void:
	if _carpeta == "":
		return
	await _esperar(30)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(_carpeta.path_join(nombre + ".png"))


func _comprobar(condicion: bool, texto: String) -> void:
	if not condicion:
		_errores += 1
		printerr("HUMO FALLO: " + texto)


func _recorrer() -> void:
	await _esperar()
	await _foto("00_menu")
	for i in Niveles.cantidad():
		if not _niveles.is_empty() and not i in _niveles:
			continue
		Juego.ir_a_nivel(i)
		await _esperar()
		var nivel: Node = get_tree().current_scene
		_comprobar(nivel.id == i, "se cargó el nivel %d" % (i + 1))
		nivel.resolver_automaticamente()
		await _esperar()
		_comprobar(nivel.orden.size() == nivel.total, "nivel %d: %d de %d" % [i + 1, nivel.orden.size(), nivel.total])
		_comprobar(Juego.reto_completado(i), "nivel %d marcado como completado" % (i + 1))
		nivel.preparar_captura()
		await _foto("nivel_%d" % (i + 1))
		nivel._abrir_galeria()
		await _esperar()
		_comprobar(nivel.grid_galeria.get_child_count() == nivel.total, "galería del nivel %d" % (i + 1))
		if i in [0, 3, 8]:
			await _foto("galeria_%d" % (i + 1))
		nivel._cerrar_galeria()

	if not _niveles.is_empty():
		get_tree().quit(1 if _errores > 0 else 0)
		return
	Juego.ir_a_quiz(Preguntas.TEMAS, 10, Juego.DESAFIO, "Desafío final")
	await _esperar()
	var quiz: Node = get_tree().current_scene
	for i in 10:
		var correcta: int = quiz.preguntas[quiz.actual].correcta
		quiz._responder(correcta if i % 3 != 0 else (correcta + 1) % 4)
		if i == 0:
			await _foto("pregunta_fallada")
		if i == 1:
			await _foto("pregunta_acertada")
		quiz._siguiente()
	await _esperar()
	_comprobar(quiz.aciertos == 6, "aciertos del desafío: %d" % quiz.aciertos)
	_comprobar(Juego.estrellas(Juego.DESAFIO) == 1, "estrellas del desafío")
	await _foto("resultado")

	Juego.ir_a_menu()
	await _esperar()
	await _foto("menu_con_progreso")
	print("PRUEBA DE HUMO: %s" % ("OK" if _errores == 0 else "%d fallos" % _errores))
	get_tree().quit(1 if _errores > 0 else 0)
