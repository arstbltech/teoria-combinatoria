extends Node
## Prueba de humo: recorre todas las pantallas del juego real simulando lo que
## haría un jugador (lee la historia, resuelve cada reto, abre la galería,
## compra en la tienda, usa comodines, pierde una ronda y vence al jefe final).
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
	var menu: Node = get_tree().current_scene
	_comprobar(menu._capa_historia.visible, "la historia se muestra la primera vez")
	await _foto("00_historia")
	menu._cerrar_historia()
	_comprobar(Juego.historia_vista(), "historia marcada como vista")
	await _foto("00_menu")
	_comprobar(not Juego.mundo_desbloqueado(1), "el mundo 2 empieza bloqueado")

	for i in Niveles.cantidad():
		if not _niveles.is_empty() and not i in _niveles:
			continue
		var monedas_antes := Juego.monedas()
		Juego.ir_a_nivel(i)
		await _esperar()
		var nivel: Node = get_tree().current_scene
		_comprobar(nivel.id == i, "se cargó el nivel %d" % (i + 1))
		nivel.resolver_automaticamente()
		await _esperar()
		_comprobar(nivel.orden.size() == nivel.total, "nivel %d: %d de %d" % [i + 1, nivel.orden.size(), nivel.total])
		_comprobar(Juego.reto_completado(i), "nivel %d marcado como completado" % (i + 1))
		var esperadas: int = nivel.total * Premios.MONEDAS_CONFIGURACION + Premios.MONEDAS_DORADA + Premios.MONEDAS_RETO
		_comprobar(Juego.monedas() - monedas_antes >= esperadas, "nivel %d: monedas ganadas %d (al menos %d)" % [i + 1, Juego.monedas() - monedas_antes, esperadas])
		# Reiniciar y volver a resolver no debe volver a pagar monedas.
		var antes_de_repetir := Juego.monedas()
		nivel._reiniciar()
		nivel.resolver_automaticamente()
		_comprobar(Juego.monedas() == antes_de_repetir, "nivel %d: repetir el reto no paga dos veces" % (i + 1))
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

	for logro in ["primer_ladrillo", "constructor", "coleccionista", "buscador_oro", "cofre"]:
		_comprobar(Juego.logro_obtenido(logro), "logro «%s» obtenido" % logro)

	# Tienda: comprar un comodín, una pista y una vida extra.
	Juego.ir_a_premios()
	await _esperar()
	var monedas_tienda := Juego.monedas()
	for objeto in ["comodin", "pista", "vida_extra"]:
		_comprobar(Juego.comprar(objeto), "comprar %s" % objeto)
	_comprobar(Juego.monedas() == monedas_tienda - 40 - 20 - 30, "precio de la tienda")
	await _foto("premios_tienda")
	get_tree().current_scene._mostrar_pagina(1)
	await _foto("premios_logros")

	# Ronda de un nivel usando comodín y pista, y perdiendo las 3 vidas
	# (la vida extra comprada salva una vez, así que hacen falta 4 errores).
	Juego.ir_a_quiz(["producto"], 5, 0, "Nivel 1 · Prueba")
	await _esperar()
	var quiz: Node = get_tree().current_scene
	quiz._usar_comodin()
	quiz._usar_pista()
	var desactivadas := 0
	for b in quiz.botones:
		desactivadas += int(b.disabled)
	_comprobar(desactivadas == 2, "el comodín 50/50 quita dos opciones")
	_comprobar(quiz.panel_pista.visible, "la pista se muestra")
	await _foto("comodines")
	for i in 4:
		var correcta: int = quiz.preguntas[quiz.actual].correcta
		var incorrecta := (correcta + 1) % 4
		while quiz.botones[incorrecta].disabled:
			incorrecta = (incorrecta + 1) % 4
			if incorrecta == correcta:
				incorrecta = (incorrecta + 1) % 4
		quiz._responder(incorrecta)
		if not quiz.sin_vidas:
			quiz._siguiente()
	_comprobar(quiz.sin_vidas, "sin vidas tras 4 errores con una vida extra")
	_comprobar(Juego.objetos("vida_extra") == 0, "la vida extra se gastó")
	quiz._siguiente()
	await _foto("sin_vidas")

	# Jefe final: 8 aciertos y 2 errores (quedan vidas), con racha de bonus.
	Juego.ir_a_quiz(Preguntas.TEMAS, 10, Juego.DESAFIO, "Desafío final")
	await _esperar()
	quiz = get_tree().current_scene
	for i in 10:
		var correcta: int = quiz.preguntas[quiz.actual].correcta
		quiz._responder(correcta if i not in [0, 9] else (correcta + 1) % 4)
		if i == 0:
			await _foto("pregunta_fallada")
		if i == 4:
			await _foto("pregunta_racha")
		quiz._siguiente()
	await _esperar()
	_comprobar(quiz.aciertos == 8, "aciertos contra el jefe: %d" % quiz.aciertos)
	_comprobar(not quiz.sin_vidas, "el jefe se vence con vidas de sobra")
	_comprobar(Juego.estrellas(Juego.DESAFIO) == 1, "estrellas del desafío")
	_comprobar(Juego.logro_obtenido("jefe"), "logro del jefe")
	_comprobar(Juego.logro_obtenido("racha_5"), "logro de racha")
	await _foto("resultado")

	Juego.ir_a_menu()
	await _esperar()
	await _foto("menu_con_progreso")
	print("PRUEBA DE HUMO: %s · %d monedas · %d estrellas" % ["OK" if _errores == 0 else "%d fallos" % _errores, Juego.monedas(), Juego.estrellas_totales()])
	get_tree().quit(1 if _errores > 0 else 0)
