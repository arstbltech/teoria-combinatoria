extends Control
## Menú principal: el mapa de Brickópolis. Muestra los tres mundos con sus
## niveles, el jefe final, las monedas y estrellas del jugador, y da acceso a los
## premios, la historia y la ayuda. En celulares en vertical va en una columna.

var _margen: MarginContainer
var _cabecera: BoxContainer
var _hud: HBoxContainer
var _grids: Array = []
var _titulos: Array = []
var _btn_borrar: Button
var _confirmar_borrado := false
var _modales: Array = []            # [capa, margen, contenido, panel] de cada ventana
var _capa_ayuda: Control
var _capa_historia: Control


func _ready() -> void:
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
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 20)
	_margen.add_child(v)

	_cabecera = BoxContainer.new()
	_cabecera.add_theme_constant_override("separation", 16)
	v.add_child(_cabecera)
	_cabecera.add_child(_marca())
	_hud = HBoxContainer.new()
	_hud.add_theme_constant_override("separation", 8)
	_hud.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_hud.add_child(Juego.pastilla_monedas(16))
	_hud.add_child(Estilo.pastilla("estrella", "%d/%d" % [Juego.estrellas_totales(), (Niveles.cantidad() + 1) * 3], 16))
	var premios := Estilo.boton("        Premios", Juego.ir_a_premios, "Primario")
	premios.add_child(_icono_en_boton("trofeo"))
	_hud.add_child(premios)
	_cabecera.add_child(_hud)

	var orden := 0
	for m in Mundos.cantidad():
		var seccion := _seccion_mundo(m)
		v.add_child(seccion)
		Estilo.aparecer(seccion, 0.08 * orden)
		orden += 1
	var jefe := _tarjeta_jefe()
	v.add_child(jefe)
	Estilo.aparecer(jefe, 0.08 * orden)

	var pie := HFlowContainer.new()
	pie.add_theme_constant_override("h_separation", 4)
	pie.add_child(Estilo.boton("¿Cómo se juega?", _mostrar.bind(0), "Fantasma"))
	pie.add_child(Estilo.boton("La historia", _mostrar.bind(1), "Fantasma"))
	_btn_borrar = Estilo.boton("Borrar progreso", _borrar, "Fantasma", 14)
	pie.add_child(_btn_borrar)
	v.add_child(pie)

	_crear_ayuda()
	_crear_historia()
	Estilo.dejar_pasar_arrastre(self)
	resized.connect(_disponer)
	_disponer()
	if not Juego.historia_vista():
		_capa_historia.visible = true


func _disponer() -> void:
	var ancho := get_viewport_rect().size.x
	var estrecho := ancho < Estilo.ANCHO_ESTRECHO
	Estilo.fijar_margen(_margen, 16 if estrecho else 30)
	_cabecera.vertical = estrecho
	for g in _grids:
		g.columns = 1 if estrecho else (3 if ancho >= 1100 else 2)
	for l in _titulos:
		l.add_theme_font_size_override("font_size", 30 if estrecho else 38)
	for modal in _modales:
		Estilo.fijar_margen(modal[1], 12 if estrecho else 60)
		Estilo.relleno_modal(modal[3], estrecho)


func _icono_en_boton(tipo: String) -> Icono:
	var i := Icono.crear(tipo, 22)
	i.position = Vector2(16, 11)
	return i


func _marca() -> Control:
	var marca := HBoxContainer.new()
	marca.add_theme_constant_override("separation", 16)
	marca.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var logo := TextureRect.new()
	logo.texture = load("res://icon.svg")
	logo.custom_minimum_size = Vector2(64, 64)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	marca.add_child(logo)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 2)
	var linea := HFlowContainer.new()
	linea.add_theme_constant_override("h_separation", 10)
	for parte in [["Ladrillos", Estilo.TINTA], ["Combinatorios", Estilo.ACENTO]]:
		var l := Estilo.etiqueta(parte[0], 38, parte[1], 900, true)
		_titulos.append(l)
		linea.add_child(l)
	textos.add_child(linea)
	var subtitulo := Estilo.etiqueta("Reconstruye Brickópolis dominando la combinatoria.", 16, Estilo.TINTA_SUAVE, 500)
	subtitulo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(subtitulo)
	marca.add_child(textos)
	return marca


func _seccion_mundo(m: int) -> Control:
	var mundo := Mundos.obtener(m)
	var abierto := Juego.mundo_desbloqueado(m)
	var seccion := VBoxContainer.new()
	seccion.add_theme_constant_override("separation", 12)

	var banner := PanelContainer.new()
	var estilo := Estilo.caja(mundo.color if abierto else Color("9aa0b4"), 20, Vector2(22, 16))
	estilo.shadow_color = Color(mundo.color, 0.25) if abierto else Estilo.SOMBRA
	estilo.shadow_size = 14
	estilo.shadow_offset = Vector2(0, 5)
	banner.add_theme_stylebox_override("panel", estilo)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	banner.add_child(fila)
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.add_theme_constant_override("separation", 2)
	textos.add_child(Estilo.etiqueta("MUNDO %d" % (m + 1), 12, Color(1, 1, 1, 0.75), 800))
	textos.add_child(Estilo.etiqueta(mundo.nombre, 24, Color.WHITE, 900, true))
	var historia := Estilo.etiqueta(mundo.historia, 14, Color(1, 1, 1, 0.9), 500)
	historia.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(historia)
	fila.add_child(textos)
	# El estado (estrellas o candado) va debajo del texto para no ensanchar el banner en celulares.
	var estado := HBoxContainer.new()
	var hueco := Control.new()
	hueco.custom_minimum_size.y = 4
	textos.add_child(hueco)
	if abierto:
		var ganadas := 0
		for n in mundo.niveles:
			ganadas += Juego.estrellas(n)
		estado.add_child(Estilo.pastilla("estrella", "%d/%d" % [ganadas, mundo.niveles.size() * 3], 15))
	else:
		var candado := PanelContainer.new()
		candado.add_theme_stylebox_override("panel", Estilo.caja(Color(1, 1, 1, 0.9), 14, Vector2(12, 8)))
		var c := HBoxContainer.new()
		c.add_theme_constant_override("separation", 6)
		c.add_child(Icono.crear("candado", 18))
		c.add_child(Estilo.etiqueta("Necesitas %d ★" % mundo.requiere, 14, Estilo.TINTA, 800))
		candado.add_child(c)
		estado.add_child(candado)
	textos.add_child(estado)
	seccion.add_child(banner)

	var grid := GridContainer.new()
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	for n in mundo.niveles:
		grid.add_child(_tarjeta(n, abierto))
	_grids.append(grid)
	seccion.add_child(grid)
	return seccion


func _tarjeta(i: int, abierto: bool) -> Button:
	var d := Niveles.obtener(i)
	var color: Color = Estilo.PALETA[i % Estilo.PALETA.size()]
	var total: int = Niveles.calcular(d.lab, d.params).valor
	var hallados := mini(Juego.encontradas(i).size(), total)
	var b := Button.new()
	b.theme_type_variation = "TarjetaBoton"
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 134)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.disabled = not abierto
	if not abierto:
		b.modulate = Color(1, 1, 1, 0.55)
		b.add_theme_stylebox_override("disabled", Estilo.caja(Estilo.SUPERFICIE, 20, Vector2(16, 16), 0, Estilo.BORDE, 1))
	b.pressed.connect(Juego.ir_a_nivel.bind(i))

	var m := Estilo.margen(16)
	b.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	m.add_child(h)
	var insignia := PanelContainer.new()
	insignia.add_theme_stylebox_override("panel", Estilo.caja(color if abierto else Color("c5cad8"), 16, Vector2.ZERO))
	insignia.custom_minimum_size = Vector2(54, 54)
	insignia.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if abierto:
		var numero := Estilo.etiqueta(str(i + 1), 24, Estilo.TINTA if color.get_luminance() > 0.6 else Color.WHITE, 900, true)
		numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		insignia.add_child(numero)
	else:
		var centro := CenterContainer.new()
		var candado := Icono.crear("candado", 26)
		candado.apagado = false
		centro.add_child(candado)
		insignia.add_child(centro)
	h.add_child(insignia)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 4)
	h.add_child(col)
	var arriba := HBoxContainer.new()
	var titulo := Estilo.etiqueta(d.titulo, 18, Estilo.TINTA, 800, true)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	arriba.add_child(titulo)
	arriba.add_child(Estilo.etiqueta(Estilo.estrellas(Juego.estrellas(i)), 15, Estilo.COLOR_ESTRELLA, 700))
	col.add_child(arriba)
	var concepto := Estilo.etiqueta(d.concepto, 14, Estilo.TINTA_SUAVE, 500)
	concepto.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	col.add_child(concepto)
	var formula := Estilo.chip(d.formula_corta, Estilo.ACENTO, Estilo.ACENTO_SUAVE, 12)
	formula.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	col.add_child(formula)
	var progreso := HBoxContainer.new()
	progreso.add_theme_constant_override("separation", 8)
	var barra := ProgressBar.new()
	barra.show_percentage = false
	barra.max_value = total
	barra.value = hallados
	barra.custom_minimum_size = Vector2(0, 6)
	barra.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	barra.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	progreso.add_child(barra)
	progreso.add_child(Estilo.etiqueta("%d/%d" % [hallados, total], 12, Estilo.TINTA_SUAVE, 600))
	col.add_child(progreso)
	_ignorar_raton(m)
	return b


func _tarjeta_jefe() -> Control:
	var abierto := Juego.desafio_desbloqueado()
	var p := PanelContainer.new()
	var estilo := Estilo.caja(Estilo.TINTA if abierto else Color("9aa0b4"), 20, Vector2(22, 18))
	estilo.shadow_color = Color(0.1, 0.1, 0.3, 0.3)
	estilo.shadow_size = 16
	estilo.shadow_offset = Vector2(0, 6)
	p.add_theme_stylebox_override("panel", estilo)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	p.add_child(h)
	h.add_child(Icono.crear("trofeo", 52))
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_child(Estilo.etiqueta("JEFE FINAL", 12, Color("ff8a7f"), 800))
	var nombre_jefe := Estilo.etiqueta("El Caos Aleatorio", 22, Color.WHITE, 900, true)
	nombre_jefe.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(nombre_jefe)
	var detalle := Estilo.etiqueta("10 preguntas de todos los temas · 3 vidas", 14, Color(1, 1, 1, 0.8), 500)
	detalle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	textos.add_child(detalle)
	textos.add_child(Estilo.etiqueta(Estilo.estrellas(Juego.estrellas(Juego.DESAFIO)), 16, Color("ffd36b"), 700))
	textos.add_theme_constant_override("separation", 4)
	h.add_child(textos)
	if abierto:
		var b := Estilo.boton("Enfrentar  →", _iniciar_desafio)
		b.add_theme_stylebox_override("normal", Estilo.caja(Color.WHITE, 12, Vector2(20, 10)))
		b.add_theme_stylebox_override("hover", Estilo.caja(Color("f4f3ff"), 12, Vector2(20, 10)))
		b.add_theme_stylebox_override("pressed", Estilo.caja(Color("e6e4ff"), 12, Vector2(20, 10)))
		for nombre in ["font_color", "font_hover_color", "font_pressed_color"]:
			b.add_theme_color_override(nombre, Estilo.TINTA)
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		textos.add_child(b)
	else:
		var bloqueo := HBoxContainer.new()
		bloqueo.add_theme_constant_override("separation", 6)
		bloqueo.add_child(Icono.crear("candado", 20))
		var aviso := Estilo.etiqueta("Se abre junto con la Base Lunar", 13, Color.WHITE, 700)
		aviso.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		aviso.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bloqueo.add_child(aviso)
		textos.add_child(bloqueo)
	return p


## Los hijos de la tarjeta no deben quedarse con los clics del botón.
func _ignorar_raton(nodo: Node) -> void:
	if nodo is Control:
		nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for hijo in nodo.get_children():
		_ignorar_raton(hijo)


func _modal(titulo: String) -> Array:
	var modal := Estilo.capa_modal(self)
	_modales.append(modal)
	var v: VBoxContainer = modal[2]
	var cab := HBoxContainer.new()
	var t := Estilo.titulo(titulo, 26)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(t)
	cab.add_child(Estilo.boton_icono("✕", func() -> void: modal[0].visible = false, Estilo.SUPERFICIE_2))
	v.add_child(cab)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	return [modal[0], scroll, v]


func _crear_ayuda() -> void:
	var partes := _modal("¿Cómo se juega?")
	_capa_ayuda = partes[0]
	partes[1].add_child(Estilo.rich("\n\n".join(PackedStringArray([
		"[b]El objetivo.[/b] Reconstruye los tres mundos de Brickópolis. En cada nivel construyes todas las configuraciones distintas posibles: el total sale de un teorema de combinatoria (pestaña [i]Teoría[/i]) y la computadora lo comprueba por fuerza bruta (pestaña [i]Comprobar[/i]).",
		"[b]Construir.[/b] Pon piezas con los botones de colores y quítalas con «Quitar». Cuando la construcción está completa se registra sola; si ya la tenías, el juego te avisa. En el nivel de los ladrillos 2×4 mueves el ladrillo azul con la cruceta, lo giras y lo registras. Arrastra sobre la vista 3D para girarla y pellizca o usa la rueda para acercarte.",
		"[b]Monedas.[/b] Ganas 1 por cada construcción nueva, 20 al completar un reto, 5 por cada respuesta correcta (10 si llevas una racha de 3), 15 por una ronda perfecta, 50 por el cofre de cada mundo y 15 por cada logro.",
		"[b]Bonus.[/b] Cada nivel esconde una configuración [b]dorada[/b] que vale 10 monedas extra, y una racha de 3 aciertos duplica las monedas de las respuestas.",
		"[b]Vidas.[/b] Cada ronda de preguntas empieza con 3 corazones. Cada error cuesta uno; si te quedas sin vidas pierdes la ronda (pero conservas las monedas).",
		"[b]Estrellas.[/b] En cada nivel: ★ completar el reto, ★ acertar al menos 2/3 de las preguntas, ★ acertarlas todas. Las estrellas abren los mundos: las Dunas Doradas piden 2 ★ y la Base Lunar 5 ★. Con la Base Lunar abierta puedes enfrentar al Caos Aleatorio.",
		"[b]Premios.[/b] En la tienda gastas tus monedas en vidas extra, comodines 50/50 y pistas. También hay 12 logros que dan monedas al desbloquearse.",
	])), 16))


func _crear_historia() -> void:
	var partes := _modal("La historia")
	_capa_historia = partes[0]
	partes[1].add_child(Estilo.rich("\n\n".join(PackedStringArray(Mundos.HISTORIA)), 17))
	var empezar := Estilo.boton("¡A construir!", _cerrar_historia, "Primario", 17)
	partes[2].add_child(empezar)


func _cerrar_historia() -> void:
	_capa_historia.visible = false
	Juego.marcar_historia_vista()


func _mostrar(cual: int) -> void:
	(_capa_ayuda if cual == 0 else _capa_historia).visible = true


func _iniciar_desafio() -> void:
	Juego.ir_a_quiz(Preguntas.TEMAS, 10, Juego.DESAFIO, "Desafío final")


func _borrar() -> void:
	if not _confirmar_borrado:
		_confirmar_borrado = true
		_btn_borrar.text = "¿Seguro? Pulsa otra vez"
		return
	Juego.borrar_progreso()
	Juego.ir_a_menu()


func _unhandled_input(event: InputEvent) -> void:
	var tecla := event as InputEventKey
	if tecla and tecla.pressed and tecla.keycode == KEY_ESCAPE:
		for capa in [_capa_ayuda, _capa_historia]:
			if capa.visible:
				capa.visible = false
				get_viewport().set_input_as_handled()
