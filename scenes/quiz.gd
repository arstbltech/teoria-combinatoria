extends Control
## Ronda de preguntas de combinatoria. Empiezas con 3 vidas (corazones): cada
## error cuesta una y sin vidas pierdes la ronda. Cada acierto da monedas y una
## racha de 3 aciertos las duplica. Se pueden usar objetos comprados en la
## tienda: comodín 50/50, pista y vida extra. El desafío final es la pelea contra
## el Caos Aleatorio, con su propia barra de vida.

const LETRAS := ["A", "B", "C", "D"]

var preguntas: Array = []
var actual := 0
var aciertos := 0
var respondida := false
var resultados: Array = []          # true/false por pregunta respondida
var vidas := Premios.VIDAS
var racha := 0
var monedas_ronda := 0
var es_jefe := false
var sin_vidas := false
var _comodin_usado := false
var _rng := RandomNumberGenerator.new()

var lbl_progreso: Label
var chip_tema: PanelContainer
var chip_racha: PanelContainer
var txt_pregunta: RichTextLabel
var botones: Array = []
var grid_opciones: GridContainer
var panel_explicacion: PanelContainer
var txt_explicacion: RichTextLabel
var panel_pista: PanelContainer
var txt_pista: RichTextLabel
var btn_siguiente: Button
var btn_comodin: Button
var btn_pista: Button
var juego: VBoxContainer
var final: VBoxContainer

var _margen: MarginContainer
var _columna: VBoxContainer
var _pasos: HBoxContainer
var _corazones: HBoxContainer
var _barra_jefe: ProgressBar


func _ready() -> void:
	_rng.randomize()
	es_jefe = Juego.quiz.nivel == Juego.DESAFIO
	preguntas = Preguntas.generar_lote(Juego.quiz.temas, Juego.quiz.cantidad, _rng)
	_construir()
	_mostrar_pregunta()
	Estilo.dejar_pasar_arrastre(self)
	resized.connect(_disponer)
	_disponer()


func _construir() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Estilo.fondo())
	var scroll := ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_margen = MarginContainer.new()
	_margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.add_child(_margen)
	var centro := HBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	_margen.add_child(centro)
	_columna = VBoxContainer.new()
	_columna.add_theme_constant_override("separation", 14)
	_columna.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	centro.add_child(_columna)

	# Cabecera: volver, título, vidas y monedas.
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	cab.add_child(Estilo.boton_icono("←", _volver))
	var titulo := Estilo.titulo(Juego.quiz.titulo, 22)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cab.add_child(titulo)
	_corazones = HBoxContainer.new()
	_corazones.add_theme_constant_override("separation", 2)
	_corazones.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	for i in Premios.VIDAS:
		_corazones.add_child(Icono.crear("corazon", 22))
	cab.add_child(_corazones)
	cab.add_child(Juego.pastilla_monedas())
	_columna.add_child(cab)

	if es_jefe:
		var jefe := PanelContainer.new()
		jefe.add_theme_stylebox_override("panel", Estilo.caja(Estilo.TINTA, 16, Vector2(16, 12)))
		var v := VBoxContainer.new()
		v.add_theme_constant_override("separation", 8)
		jefe.add_child(v)
		var fila := HBoxContainer.new()
		var nombre := Estilo.etiqueta("JEFE FINAL · EL CAOS ALEATORIO", 13, Color("ff8a7f"), 800)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nombre)
		fila.add_child(Estilo.etiqueta("Cada acierto lo debilita", 12, Color(1, 1, 1, 0.7), 500))
		v.add_child(fila)
		_barra_jefe = ProgressBar.new()
		_barra_jefe.show_percentage = false
		_barra_jefe.custom_minimum_size = Vector2(0, 12)
		_barra_jefe.max_value = preguntas.size()
		_barra_jefe.value = preguntas.size()
		_barra_jefe.add_theme_stylebox_override("background", Estilo.caja(Color(1, 1, 1, 0.15), 99, Vector2.ZERO))
		_barra_jefe.add_theme_stylebox_override("fill", Estilo.caja(Estilo.COLOR_ERROR, 99, Vector2.ZERO))
		v.add_child(_barra_jefe)
		_columna.add_child(jefe)

	# Una rayita por pregunta: verde/roja si ya se respondió, índigo la actual.
	_pasos = HBoxContainer.new()
	_pasos.add_theme_constant_override("separation", 6)
	for i in preguntas.size():
		var paso := Panel.new()
		paso.custom_minimum_size = Vector2(0, 6)
		paso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_pasos.add_child(paso)
	_columna.add_child(_pasos)

	juego = VBoxContainer.new()
	juego.add_theme_constant_override("separation", 14)
	_columna.add_child(juego)
	var info := HBoxContainer.new()
	info.add_theme_constant_override("separation", 8)
	lbl_progreso = Estilo.etiqueta("", 14, Estilo.TINTA_SUAVE, 600)
	lbl_progreso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_child(lbl_progreso)
	chip_racha = Estilo.chip("Racha ×2", Estilo.COLOR_AVISO, Estilo.COLOR_AVISO_SUAVE, 13)
	info.add_child(chip_racha)
	chip_tema = Estilo.chip("", Estilo.ACENTO, Estilo.ACENTO_SUAVE, 13)
	info.add_child(chip_tema)
	juego.add_child(info)
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", Estilo.caja(Estilo.SUPERFICIE, 20, Vector2(24, 22), 18, Estilo.BORDE, 1))
	txt_pregunta = Estilo.rich("", 21)
	tarjeta.add_child(txt_pregunta)
	juego.add_child(tarjeta)
	grid_opciones = GridContainer.new()
	grid_opciones.add_theme_constant_override("h_separation", 12)
	grid_opciones.add_theme_constant_override("v_separation", 12)
	for i in 4:
		var b := Estilo.boton("", _responder.bind(i), "Opcion", 22)
		b.custom_minimum_size = Vector2(0, 64)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		grid_opciones.add_child(b)
		botones.append(b)
	juego.add_child(grid_opciones)

	# Objetos de la tienda.
	var comodines := HFlowContainer.new()
	comodines.add_theme_constant_override("h_separation", 8)
	comodines.add_theme_constant_override("v_separation", 8)
	btn_comodin = Estilo.boton("", _usar_comodin, "", 14)
	btn_comodin.add_child(_icono_en_boton("comodin"))
	comodines.add_child(btn_comodin)
	btn_pista = Estilo.boton("", _usar_pista, "", 14)
	btn_pista.add_child(_icono_en_boton("pista"))
	comodines.add_child(btn_pista)
	juego.add_child(comodines)
	panel_pista = PanelContainer.new()
	panel_pista.theme_type_variation = "Formula"
	txt_pista = Estilo.rich("", 15)
	panel_pista.add_child(txt_pista)
	juego.add_child(panel_pista)

	if not DisplayServer.is_touchscreen_available():
		juego.add_child(Estilo.etiqueta("Responde con un clic o con las teclas 1 a 4.", 13, Estilo.TINTA_SUAVE, 500))
	panel_explicacion = PanelContainer.new()
	txt_explicacion = Estilo.rich("", 16)
	panel_explicacion.add_child(txt_explicacion)
	juego.add_child(panel_explicacion)
	btn_siguiente = Estilo.boton("Siguiente  →", _siguiente, "Primario", 17)
	btn_siguiente.custom_minimum_size = Vector2(200, 50)
	juego.add_child(btn_siguiente)

	final = VBoxContainer.new()
	final.visible = false
	final.add_theme_constant_override("separation", 16)
	_columna.add_child(final)


## Ícono a la izquierda dentro de un botón de texto.
func _icono_en_boton(tipo: String) -> Icono:
	var i := Icono.crear(tipo, 20)
	i.position = Vector2(14, 12)
	return i


func _disponer() -> void:
	var ancho := get_viewport_rect().size.x
	var estrecho := ancho < Estilo.ANCHO_ESTRECHO
	Estilo.fijar_margen(_margen, 14 if estrecho else 28)
	_columna.custom_minimum_size.x = clampf(ancho - 28.0, 300.0, 820.0) if estrecho else 820.0
	grid_opciones.columns = 1 if estrecho else 2
	btn_siguiente.size_flags_horizontal = Control.SIZE_FILL if estrecho else Control.SIZE_SHRINK_END
	for clave in ["normal_font_size", "bold_font_size"]:
		txt_pregunta.add_theme_font_size_override(clave, 19 if estrecho else 22)


func _pintar_pasos() -> void:
	for i in _pasos.get_child_count():
		var color := Color("dfe3ee")
		if i < resultados.size():
			color = Estilo.COLOR_OK if resultados[i] else Estilo.COLOR_ERROR
		elif i == actual:
			color = Estilo.ACENTO
		_pasos.get_child(i).add_theme_stylebox_override("panel", Estilo.caja(color, 99, Vector2.ZERO))


func _pintar_vidas() -> void:
	for i in _corazones.get_child_count():
		_corazones.get_child(i).apagado = i >= vidas


func _pintar_comodines() -> void:
	var n_comodin := Juego.objetos("comodin")
	var n_pista := Juego.objetos("pista")
	btn_comodin.text = "      50/50 · %d" % n_comodin
	btn_pista.text = "      Pista · %d" % n_pista
	btn_comodin.disabled = respondida or n_comodin == 0 or _comodin_usado
	btn_pista.disabled = respondida or n_pista == 0 or panel_pista.visible
	var falta := "  (cómpralo en Premios)"
	btn_comodin.tooltip_text = "Elimina dos respuestas incorrectas" + (falta if n_comodin == 0 else "")
	btn_pista.tooltip_text = "Muestra la fórmula del tema" + (falta if n_pista == 0 else "")



func _mostrar_pregunta() -> void:
	respondida = false
	_comodin_usado = false
	var p: Dictionary = preguntas[actual]
	lbl_progreso.text = "Pregunta %d de %d" % [actual + 1, preguntas.size()]
	(chip_tema.get_child(0) as Label).text = p.tema
	chip_racha.visible = racha >= Premios.RACHA_BONUS
	txt_pregunta.text = p.texto
	for i in 4:
		var b: Button = botones[i]
		b.text = "%s    %s" % [LETRAS[i], p.opciones[i]]
		b.disabled = false
		b.modulate = Color.WHITE
		b.remove_theme_stylebox_override("disabled")
		b.remove_theme_color_override("font_disabled_color")
	panel_explicacion.visible = false
	panel_pista.visible = false
	btn_siguiente.visible = false
	_pintar_pasos()
	_pintar_vidas()
	_pintar_comodines()
	Estilo.aparecer(juego)


func _responder(i: int) -> void:
	if respondida or botones[i].disabled:
		return
	respondida = true
	var p: Dictionary = preguntas[actual]
	var correcta: int = p.correcta
	var bien := i == correcta
	resultados.append(bien)
	var detalle := ""
	if bien:
		aciertos += 1
		racha += 1
		var ganancia := Premios.MONEDAS_RACHA if racha >= Premios.RACHA_BONUS else Premios.MONEDAS_ACIERTO
		Juego.sumar_monedas(ganancia)
		Juego.maximo_estadistica("racha_max", racha)
		monedas_ronda += ganancia
		detalle = "  [color=%s]+%d monedas%s[/color]" % [Estilo.hex(Estilo.COLOR_AVISO), ganancia, " (racha ×2)" if racha >= Premios.RACHA_BONUS else ""]
		if racha == Premios.RACHA_BONUS:
			Juego.notificar("¡Bonus de racha! Ahora cada acierto vale el doble", "rayo", Estilo.COLOR_AVISO)
		if es_jefe:
			var tw := create_tween()
			tw.tween_property(_barra_jefe, "value", preguntas.size() - aciertos, 0.4)
	else:
		racha = 0
		vidas -= 1
		_latir(_corazones)
		if vidas == 0:
			if Juego.usar_objeto("vida_extra"):
				vidas = 1
				Juego.notificar("¡Usaste una vida extra!", "corazon", Estilo.COLOR_ERROR)
			else:
				sin_vidas = true
	chip_racha.visible = racha >= Premios.RACHA_BONUS
	_pintar_vidas()
	for j in 4:
		var b: Button = botones[j]
		b.disabled = true
		if j == correcta:
			b.add_theme_stylebox_override("disabled", Estilo.caja(Estilo.COLOR_OK_SUAVE, 16, Vector2(18, 14), 0, Estilo.COLOR_OK, 2))
			b.add_theme_color_override("font_disabled_color", Estilo.COLOR_OK.darkened(0.25))
			b.modulate = Color.WHITE
		elif j == i:
			b.add_theme_stylebox_override("disabled", Estilo.caja(Estilo.COLOR_ERROR_SUAVE, 16, Vector2(18, 14), 0, Estilo.COLOR_ERROR, 2))
			b.add_theme_color_override("font_disabled_color", Estilo.COLOR_ERROR.darkened(0.15))
		else:
			b.add_theme_stylebox_override("disabled", Estilo.caja(Estilo.SUPERFICIE, 16, Vector2(18, 14), 0, Estilo.BORDE, 2))
			b.modulate = Color(1, 1, 1, 0.5)
	var color := Estilo.COLOR_OK if bien else Estilo.COLOR_ERROR
	var estilo := Estilo.caja(Estilo.COLOR_OK_SUAVE if bien else Estilo.COLOR_ERROR_SUAVE, 16, Vector2(18, 14))
	estilo.border_color = color
	estilo.border_width_left = 4
	panel_explicacion.add_theme_stylebox_override("panel", estilo)
	var encabezado: String
	if bien:
		encabezado = "[color=%s][b]✓ ¡Correcto![/b][/color]%s\n" % [Estilo.hex(color.darkened(0.2)), detalle]
	else:
		encabezado = "[color=%s][b]✗ No es correcto.[/b][/color] La respuesta es [b]%s[/b]. [color=%s]−1 vida[/color]\n" % [
			Estilo.hex(color.darkened(0.1)), p.opciones[correcta], Estilo.hex(Estilo.COLOR_ERROR)]
	txt_explicacion.text = encabezado + p.explicacion
	panel_explicacion.visible = true
	Estilo.aparecer(panel_explicacion)
	if sin_vidas:
		btn_siguiente.text = "Continuar  →"
	else:
		btn_siguiente.text = "Siguiente  →" if actual + 1 < preguntas.size() else "Ver resultado  →"
	btn_siguiente.visible = true
	_pintar_comodines()
	_pintar_pasos()


func _latir(nodo: Control) -> void:
	nodo.pivot_offset = nodo.size / 2
	var tw := create_tween()
	tw.tween_property(nodo, "scale", Vector2(1.25, 1.25), 0.1)
	tw.tween_property(nodo, "scale", Vector2.ONE, 0.2)


## Comodín 50/50: desactiva dos respuestas incorrectas al azar.
func _usar_comodin() -> void:
	if respondida or _comodin_usado or not Juego.usar_objeto("comodin"):
		return
	_comodin_usado = true
	var correcta: int = preguntas[actual].correcta
	var incorrectas := []
	for j in 4:
		if j != correcta:
			incorrectas.append(j)
	incorrectas.shuffle()
	for j in incorrectas.slice(0, 2):
		botones[j].disabled = true
		botones[j].modulate = Color(1, 1, 1, 0.3)
	_pintar_comodines()


func _usar_pista() -> void:
	if respondida or panel_pista.visible or not Juego.usar_objeto("pista"):
		return
	txt_pista.text = "[b]Pista.[/b] " + preguntas[actual].pista
	panel_pista.visible = true
	Estilo.aparecer(panel_pista)
	_pintar_comodines()


func _siguiente() -> void:
	if not respondida:
		return
	if sin_vidas:
		_mostrar_sin_vidas()
		return
	actual += 1
	if actual < preguntas.size():
		_mostrar_pregunta()
	else:
		_mostrar_final()


## Panel de cierre de ronda con un título, líneas centradas y dos botones.
func _panel_final(lineas: Array, principal: Array, secundario: Array) -> void:
	juego.visible = false
	_pintar_pasos()
	for h in final.get_children():
		h.queue_free()
	final.visible = true
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Estilo.caja(Estilo.SUPERFICIE, 24, Vector2(28, 28), 24, Estilo.BORDE, 1))
	final.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	for linea in lineas:
		if linea is Label:
			linea.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			linea.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(linea)
	var espacio := Control.new()
	espacio.custom_minimum_size.y = 8
	v.add_child(espacio)
	v.add_child(Estilo.boton(principal[0], principal[1], "Primario", 17))
	v.add_child(Estilo.boton(secundario[0], secundario[1], "", 17))
	Estilo.dejar_pasar_arrastre(panel)
	Estilo.aparecer(panel)


func _fila_centrada(hijos: Array) -> HBoxContainer:
	var fila := HBoxContainer.new()
	fila.alignment = BoxContainer.ALIGNMENT_CENTER
	fila.add_theme_constant_override("separation", 8)
	for h in hijos:
		fila.add_child(h)
	return fila


func _mostrar_final() -> void:
	var nivel: int = Juego.quiz.nivel
	var perfecto := aciertos == preguntas.size()
	if nivel >= 0:
		Juego.registrar_quiz(nivel, aciertos, preguntas.size())
	if perfecto:
		Juego.sumar_monedas(Premios.MONEDAS_PERFECTO)
		monedas_ronda += Premios.MONEDAS_PERFECTO
		if not es_jefe:
			Juego.sumar_estadistica("quiz_perfectos")
	var titulo := "¡Ronda completada!"
	var mensaje := "Repasa la pestaña Teoría del nivel y vuelve a intentarlo."
	if es_jefe:
		Juego.sumar_monedas(Premios.MONEDAS_JEFE)
		monedas_ronda += Premios.MONEDAS_JEFE
		Juego.sumar_estadistica("jefe_vencido")
		if vidas == Premios.VIDAS:
			Juego.sumar_estadistica("jefe_sin_danio")
		titulo = "¡Venciste al Caos Aleatorio!"
		mensaje = "Brickópolis vuelve a estar en orden. ¡Eres un verdadero Maestro Constructor!"
	elif perfecto:
		mensaje = "¡Perfecto! Dominas este tema."
	elif aciertos * 3 >= preguntas.size() * 2:
		mensaje = "¡Muy bien! Revisa la explicación de las que fallaste."
	var monedas := _fila_centrada([Icono.crear("moneda", 22), Estilo.etiqueta("+%d monedas en esta ronda" % monedas_ronda, 16, Estilo.COLOR_AVISO, 700)])
	_panel_final([
		Estilo.etiqueta(titulo.to_upper(), 13, Estilo.TINTA_SUAVE, 800),
		Estilo.etiqueta("%d / %d" % [aciertos, preguntas.size()], 64, Estilo.ACENTO, 900, true),
		Estilo.etiqueta(Estilo.estrellas(Juego.estrellas(nivel)), 34, Estilo.COLOR_ESTRELLA, 700),
		monedas,
		Estilo.etiqueta(mensaje, 17, Estilo.TINTA, 500),
	], ["Otra ronda", _otra_ronda], ["Volver al nivel" if _hay_nivel() else "Volver al mapa", _volver])


func _mostrar_sin_vidas() -> void:
	var corazon := Icono.crear("corazon", 64)
	corazon.apagado = true
	var texto_monedas := "Conservas las %d monedas que ganaste" % monedas_ronda if monedas_ronda > 0 else "Esta vez no ganaste monedas"
	var monedas := _fila_centrada([Icono.crear("moneda", 22), Estilo.etiqueta(texto_monedas, 15, Estilo.COLOR_AVISO, 700)])
	_panel_final([
		_fila_centrada([corazon]),
		Estilo.etiqueta("¡Te quedaste sin vidas!", 28, Estilo.COLOR_ERROR, 900, true),
		Estilo.etiqueta("Respondiste bien %d de %d preguntas." % [aciertos, resultados.size()], 16, Estilo.TINTA, 500),
		monedas,
		Estilo.etiqueta("Consejo: repasa la teoría o compra una vida extra en Premios.", 14, Estilo.TINTA_SUAVE, 500),
	], ["Reintentar", _otra_ronda], ["Volver al nivel" if _hay_nivel() else "Volver al mapa", _volver])


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
