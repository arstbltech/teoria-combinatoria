extends Control
## Preguntas de combinatoria de opción múltiple.

var preguntas: Array = []
var actual := 0
var aciertos := 0
var respondida := false

var lbl_progreso: Label
var lbl_tema: Label
var lbl_puntos: Label
var txt_pregunta: RichTextLabel
var botones: Array = []
var panel_explicacion: PanelContainer
var txt_explicacion: RichTextLabel
var btn_siguiente: Button
var juego: VBoxContainer
var final: VBoxContainer


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	preguntas = Preguntas.generar_lote(Juego.quiz.temas, Juego.quiz.cantidad, rng)
	_construir()
	_mostrar_pregunta()


func _construir() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Estilo.fondo())
	var m := Estilo.margen(24)
	add_child(m)
	var raiz := VBoxContainer.new()
	raiz.add_theme_constant_override("separation", 16)
	m.add_child(raiz)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 14)
	raiz.add_child(cab)
	cab.add_child(Estilo.boton("← Volver", _volver))
	var titulo := Estilo.etiqueta("Preguntas · " + Juego.quiz.titulo, 24, Estilo.TINTA, true)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(titulo)
	lbl_puntos = Estilo.etiqueta("", 20, Estilo.COLOR_OK, true)
	cab.add_child(lbl_puntos)

	var centro := HBoxContainer.new()
	centro.size_flags_vertical = Control.SIZE_EXPAND_FILL
	raiz.add_child(centro)
	centro.add_child(_espaciador())
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_stretch_ratio = 6.0
	centro.add_child(col)
	centro.add_child(_espaciador())

	juego = VBoxContainer.new()
	juego.add_theme_constant_override("separation", 14)
	col.add_child(juego)
	var info := HBoxContainer.new()
	lbl_progreso = Estilo.etiqueta("", 17, Estilo.TINTA_SUAVE, true)
	info.add_child(lbl_progreso)
	lbl_tema = Estilo.etiqueta("", 17, Estilo.ACENTO, true)
	lbl_tema.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_tema.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	info.add_child(lbl_tema)
	juego.add_child(info)
	var tarjeta := PanelContainer.new()
	txt_pregunta = Estilo.rich("", 24)
	tarjeta.add_child(txt_pregunta)
	juego.add_child(tarjeta)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	for i in 4:
		var b := Estilo.boton("", _responder.bind(i), 26)
		b.custom_minimum_size = Vector2(0, 68)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(b)
		botones.append(b)
	juego.add_child(grid)
	juego.add_child(Estilo.etiqueta("Responde con un clic o con las teclas 1 a 4.", 14, Estilo.TINTA_SUAVE))
	panel_explicacion = PanelContainer.new()
	panel_explicacion.add_theme_stylebox_override("panel", Estilo.caja(Estilo.CREMA, Color("eed58a"), 12, 14, 2))
	txt_explicacion = Estilo.rich("", 18)
	panel_explicacion.add_child(txt_explicacion)
	juego.add_child(panel_explicacion)
	btn_siguiente = Estilo.boton("Siguiente →", _siguiente, 20)
	Estilo.pintar_boton(btn_siguiente, Estilo.PALETA[2])
	btn_siguiente.size_flags_horizontal = Control.SIZE_SHRINK_END
	juego.add_child(btn_siguiente)

	final = VBoxContainer.new()
	final.visible = false
	final.size_flags_vertical = Control.SIZE_EXPAND_FILL
	final.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_child(final)


func _espaciador() -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


func _mostrar_pregunta() -> void:
	respondida = false
	var p: Dictionary = preguntas[actual]
	lbl_progreso.text = "Pregunta %d de %d" % [actual + 1, preguntas.size()]
	lbl_tema.text = p.tema
	lbl_puntos.text = "Aciertos: %d" % aciertos
	txt_pregunta.text = p.texto
	for i in 4:
		var b: Button = botones[i]
		b.text = p.opciones[i]
		b.disabled = false
		b.modulate = Color.WHITE
		b.remove_theme_stylebox_override("disabled")
		b.remove_theme_color_override("font_disabled_color")
	panel_explicacion.visible = false
	btn_siguiente.visible = false


func _responder(i: int) -> void:
	if respondida:
		return
	respondida = true
	var p: Dictionary = preguntas[actual]
	var correcta: int = p.correcta
	if i == correcta:
		aciertos += 1
	for j in 4:
		var b: Button = botones[j]
		b.disabled = true
		if j == correcta or j == i:
			var color := Estilo.COLOR_OK if j == correcta else Estilo.COLOR_ERROR
			b.add_theme_stylebox_override("disabled", Estilo.caja(color, color.darkened(0.3)))
			b.add_theme_color_override("font_disabled_color", Color.WHITE)
		else:
			b.modulate = Color(1, 1, 1, 0.55)
	var encabezado: String
	if i == correcta:
		encabezado = "[color=%s][b]¡Correcto![/b][/color] " % Estilo.hex(Estilo.COLOR_OK)
	else:
		encabezado = "[color=%s][b]No es correcto.[/b][/color] La respuesta es [b]%s[/b]. " % [Estilo.hex(Estilo.COLOR_ERROR), p.opciones[correcta]]
	txt_explicacion.text = encabezado + p.explicacion
	panel_explicacion.visible = true
	btn_siguiente.text = "Siguiente →" if actual + 1 < preguntas.size() else "Ver resultado →"
	btn_siguiente.visible = true
	lbl_puntos.text = "Aciertos: %d" % aciertos


func _siguiente() -> void:
	if not respondida:
		return
	actual += 1
	if actual < preguntas.size():
		_mostrar_pregunta()
	else:
		_mostrar_final()


func _mostrar_final() -> void:
	juego.visible = false
	var nivel: int = Juego.quiz.nivel
	if nivel >= 0:
		Juego.registrar_quiz(nivel, aciertos, preguntas.size())
	final.visible = true
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.custom_minimum_size = Vector2(560, 0)
	panel.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, Estilo.BORDE, 16, 34, 4))
	final.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	var fraccion := float(aciertos) / preguntas.size()
	var mensaje := "Repasa la pestaña Teoría del nivel y vuelve a intentarlo." if _hay_nivel() else "Repasa la teoría de los niveles donde fallaste y vuelve a intentarlo."
	if fraccion == 1.0:
		mensaje = "¡Perfecto! Dominas este tema."
	elif fraccion >= 0.66:
		mensaje = "¡Muy bien! Revisa la explicación de las que fallaste."
	for linea in [
		Estilo.etiqueta("Resultado", 22, Estilo.TINTA_SUAVE, true),
		Estilo.etiqueta("%d de %d" % [aciertos, preguntas.size()], 56, Estilo.ACENTO, true),
		Estilo.etiqueta(mensaje, 20, Estilo.TINTA),
		Estilo.etiqueta("Estrellas: %s" % Estilo.estrellas(Juego.estrellas(nivel)), 26, Estilo.COLOR_ESTRELLA, true),
	]:
		linea.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(linea)
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 12)
	var otra := Estilo.boton("Otra ronda", _otra_ronda, 20)
	Estilo.pintar_boton(otra, Estilo.PALETA[2])
	fila.add_child(otra)
	fila.add_child(Estilo.boton("Volver al nivel" if _hay_nivel() else "Volver al menú", _volver, 20))
	v.add_child(fila)


func _hay_nivel() -> bool:
	var nivel: int = Juego.quiz.nivel
	return nivel >= 0 and nivel < Niveles.cantidad()


func _otra_ronda() -> void:
	Juego.ir_a_quiz(Juego.quiz.temas, Juego.quiz.cantidad, Juego.quiz.nivel, Juego.quiz.titulo)


func _volver() -> void:
	if _hay_nivel():
		Juego.ir_a_nivel(Juego.quiz.nivel)
	else:
		Juego.ir_a_menu()


func _unhandled_input(event: InputEvent) -> void:
	var tecla := event as InputEventKey
	if tecla == null or not tecla.pressed or tecla.echo:
		return
	if tecla.keycode >= KEY_1 and tecla.keycode <= KEY_4 and juego.visible:
		_responder(tecla.keycode - KEY_1)
	elif tecla.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and juego.visible:
		_siguiente()
	elif tecla.keycode == KEY_ESCAPE:
		_volver()
	else:
		return
	get_viewport().set_input_as_handled()
