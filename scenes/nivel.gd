extends Control
## Pantalla de un nivel: constructor 3D, reto, teoría y comprobación de la fórmula.
## En pantallas anchas va en dos columnas; en un celular en vertical, en una
## sola columna que se desplaza.

var id := 0
var datos: Dictionary
var modo := ""        # "torre", "fila", "altura" o "eilers"
var reglas := {}
var total := 0
var objetivo := 0

var seq: Array = []                 # piezas en el orden en que se pusieron
var pos := Vector3i(1, 1, 0)        # modo eilers: (x, y, orientación) del ladrillo de arriba
var ladrillo := Vector2i(2, 4)
var encontradas := {}               # clave canónica → true
var orden: Array = []               # claves canónicas en el orden en que se hallaron
var ver_gemela := false
var revelar := false

var vista: VistaLadrillos
var lbl_estado: RichTextLabel
var lbl_mensaje: Label
var lbl_contador: Label
var lbl_contador_vista: Label
var lbl_objetivo: Label
var lbl_anuncio: Label
var barra: ProgressBar
var botones_pieza: Array = []
var btn_gemela: Button
var capa_galeria: Control
var grid_galeria: GridContainer
var lbl_galeria: Label
var valores_lab: Array = []
var etiquetas_lab: Array = []
var lab_res: RichTextLabel

var _margen: MarginContainer
var _cuerpo: BoxContainer
var _izq: VBoxContainer
var _marco: PanelContainer
var _panel: PanelContainer
var _titulo: Label
var _toast: PanelContainer
var _paginas: Array = []
var _margen_galeria: MarginContainer
var _panel_galeria: PanelContainer
var _cuenta_galeria: Label
var _tam_miniatura := Vector2(104, 124)
var _toques := {}                   # dedos sobre la vista 3D: índice → posición
var _acciones_eilers: BoxContainer  # Girar y Gemela: en fila o apilados según el ancho
var _clave_dorada := ""             # bonus: una configuración del reto vale monedas extra
var _lbl_bonus: RichTextLabel


func _ready() -> void:
	id = Juego.nivel_actual
	datos = Niveles.obtener(id)
	modo = datos.modo
	if datos.has("reglas"):
		reglas = Enumerador.reglas(datos.reglas)
	if modo == "eilers":
		ladrillo = Vector2i(datos.params[0], datos.params[1])
	total = Niveles.calcular(datos.lab, datos.params).valor
	objetivo = datos.objetivo
	var todas := _todas()
	_clave_dorada = todas[(id * 7 + 3) % todas.size()].clave
	_construir_ui()
	_preparar_escena()
	_cargar_progreso()
	_actualizar()
	vista.saltar_camara()
	_calcular_lab()
	Estilo.dejar_pasar_arrastre(self)
	resized.connect(_disponer)
	_disponer()


# --- Construcción de la interfaz ---------------------------------------------

func _construir_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Estilo.fondo())
	var pagina := ScrollContainer.new()
	pagina.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pagina.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(pagina)
	_margen = MarginContainer.new()
	_margen.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_margen.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pagina.add_child(_margen)
	_cuerpo = BoxContainer.new()
	_cuerpo.add_theme_constant_override("separation", 16)
	_margen.add_child(_cuerpo)

	_izq = VBoxContainer.new()
	_izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_izq.size_flags_stretch_ratio = 1.6
	_izq.add_theme_constant_override("separation", 12)
	_cuerpo.add_child(_izq)
	_izq.add_child(_cabecera())
	_izq.add_child(_escena())
	_izq.add_child(_herramientas())

	_panel = PanelContainer.new()
	_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_cuerpo.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	_panel.add_child(v)
	v.add_child(Estilo.segmentos(["Reto", "Teoría", "Comprobar"], _mostrar_pagina))
	for pagina_ in [_pagina_reto(), _envolver_scroll(Estilo.rich(datos.teoria, 15)), _pagina_comprobar()]:
		pagina_.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_paginas.append(pagina_)
		v.add_child(pagina_)
	_mostrar_pagina(0)

	_crear_galeria()


func _cabecera() -> Control:
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	cab.add_child(Estilo.boton_icono("←", Juego.ir_a_menu))
	var textos := VBoxContainer.new()
	textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	textos.alignment = BoxContainer.ALIGNMENT_CENTER
	textos.add_theme_constant_override("separation", 0)
	var mundo := Mundos.obtener(Mundos.de_nivel(id))
	var antetitulo := Estilo.etiqueta(("%s · Nivel %d" % [mundo.nombre, id + 1]).to_upper(), 12, mundo.color.darkened(0.15), 800)
	antetitulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	textos.add_child(antetitulo)
	_titulo = Estilo.titulo(datos.titulo, 26)
	_titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	textos.add_child(_titulo)
	cab.add_child(textos)
	cab.add_child(Juego.pastilla_monedas())
	return cab


func _escena() -> Control:
	_marco = PanelContainer.new()
	_marco.theme_type_variation = "Escena"
	_marco.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var capa := Control.new()
	_marco.add_child(capa)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svc.gui_input.connect(_al_tocar_vista)
	capa.add_child(svc)
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.msaa_3d = Viewport.MSAA_4X
	svc.add_child(sv)
	vista = VistaLadrillos.new()
	sv.add_child(vista)

	var tactil := DisplayServer.is_touchscreen_available()
	var ayuda := Estilo.chip("Arrastra para girar · " + ("pellizca para acercar" if tactil else "rueda para acercar"),
		Estilo.TINTA_SUAVE, Color(1, 1, 1, 0.8), 12)
	ayuda.position = Vector2(12, 12)
	capa.add_child(ayuda)
	var contador := PanelContainer.new()
	contador.add_theme_stylebox_override("panel", Estilo.caja(Color.WHITE, 99, Vector2(12, 5), 8))
	lbl_contador_vista = Estilo.etiqueta("", 14, Estilo.COLOR_OK, 800)
	contador.add_child(lbl_contador_vista)
	contador.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	contador.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	contador.position += Vector2(-12, 12)
	capa.add_child(contador)
	lbl_anuncio = Estilo.etiqueta("", 34, Estilo.COLOR_OK, 900, true)
	lbl_anuncio.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	lbl_anuncio.offset_top = 56
	lbl_anuncio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_anuncio.add_theme_constant_override("outline_size", 12)
	lbl_anuncio.add_theme_color_override("font_outline_color", Color.WHITE)
	lbl_anuncio.modulate.a = 0.0
	capa.add_child(lbl_anuncio)
	return _marco


func _herramientas() -> Control:
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", Estilo.caja(Estilo.SUPERFICIE, 20, Vector2(16, 14), 18, Estilo.BORDE, 1))
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	tarjeta.add_child(v)
	lbl_estado = Estilo.rich("", 15)
	v.add_child(lbl_estado)
	if modo == "eilers":
		v.add_child(_controles_eilers())
	else:
		var controles := HFlowContainer.new()
		controles.add_theme_constant_override("h_separation", 8)
		controles.add_theme_constant_override("v_separation", 8)
		_crear_controles(controles)
		v.add_child(controles)
	_toast = PanelContainer.new()
	_toast.visible = false
	lbl_mensaje = Estilo.etiqueta("", 15, Estilo.COLOR_AVISO, 600)
	lbl_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_toast.add_child(lbl_mensaje)
	v.add_child(_toast)
	return tarjeta


func _crear_controles(caja: Container) -> void:
	match modo:
		"torre", "fila":
			for c in reglas.k:
				var b := Estilo.boton("", _agregar.bind(c))
				Estilo.pintar_boton(b, Estilo.PALETA[c])
				b.tooltip_text = "Tecla %d" % (c + 1)
				caja.add_child(b)
				botones_pieza.append(b)
		"altura":
			var placa := Estilo.boton("+ Placa (1)", _agregar.bind(0))
			Estilo.pintar_boton(placa, Estilo.COLOR_PLACA)
			caja.add_child(placa)
			var alto := Estilo.boton("+ Ladrillo (3)", _agregar.bind(1))
			Estilo.pintar_boton(alto, Estilo.COLOR_LADRILLO)
			caja.add_child(alto)
	caja.add_child(Estilo.boton("Quitar", _quitar))
	caja.add_child(Estilo.boton("Vaciar", _vaciar, "Fantasma"))


## Cruceta y acciones del nivel de los ladrillos 2×4.
func _controles_eilers() -> Control:
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 16)
	var cruceta := GridContainer.new()
	cruceta.columns = 3
	cruceta.add_theme_constant_override("h_separation", 6)
	cruceta.add_theme_constant_override("v_separation", 6)
	for celda in [null, ["↑", Vector2i(0, -1)], null, ["←", Vector2i(-1, 0)], ["↓", Vector2i(0, 1)], ["→", Vector2i(1, 0)]]:
		if celda == null:
			var hueco := Control.new()
			hueco.custom_minimum_size = Vector2(44, 44)
			cruceta.add_child(hueco)
		else:
			var b := Estilo.boton(celda[0], _mover.bind(celda[1]), "", 18)
			b.custom_minimum_size = Vector2(48, 44)
			cruceta.add_child(b)
	fila.add_child(cruceta)
	var acciones := VBoxContainer.new()
	acciones.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	acciones.add_theme_constant_override("separation", 6)
	var arriba := BoxContainer.new()
	arriba.add_theme_constant_override("separation", 6)
	_acciones_eilers = arriba
	var girar := Estilo.boton("↻ Girar", _girar)
	girar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	arriba.add_child(girar)
	btn_gemela = Estilo.boton("Gemela ρ", _alternar_gemela)
	btn_gemela.toggle_mode = true
	btn_gemela.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_gemela.add_theme_stylebox_override("pressed", Estilo.caja(Color("fff1d2"), 12, Vector2(18, 10)))
	btn_gemela.add_theme_stylebox_override("hover_pressed", Estilo.caja(Color("ffe7b3"), 12, Vector2(18, 10)))
	arriba.add_child(btn_gemela)
	acciones.add_child(arriba)
	acciones.add_child(Estilo.boton("✓ Registrar", _registrar, "Primario"))
	fila.add_child(acciones)
	return fila


func _envolver_scroll(contenido: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_NONE
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(contenido)
	return scroll


func _mostrar_pagina(i: int) -> void:
	for j in _paginas.size():
		_paginas[j].visible = j == i


func _pagina_reto() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	var chips := HFlowContainer.new()
	chips.add_theme_constant_override("h_separation", 6)
	chips.add_child(Estilo.chip(datos.concepto))
	v.add_child(chips)
	v.add_child(Estilo.rich(datos.enunciado, 16))
	var bonus := PanelContainer.new()
	bonus.add_theme_stylebox_override("panel", Estilo.caja(Estilo.COLOR_AVISO_SUAVE, 14, Vector2(14, 10)))
	var fila_bonus := HBoxContainer.new()
	fila_bonus.add_theme_constant_override("separation", 10)
	fila_bonus.add_child(Icono.crear("rayo", 26))
	_lbl_bonus = Estilo.rich("", 14)
	fila_bonus.add_child(_lbl_bonus)
	bonus.add_child(fila_bonus)
	v.add_child(bonus)

	var progreso := VBoxContainer.new()
	progreso.add_theme_constant_override("separation", 6)
	var fila := HBoxContainer.new()
	var titulo := Estilo.etiqueta("Encontradas", 14, Estilo.TINTA_SUAVE, 600)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.size_flags_vertical = Control.SIZE_SHRINK_END
	fila.add_child(titulo)
	lbl_contador = Estilo.etiqueta("", 28, Estilo.TINTA, 900, true)
	fila.add_child(lbl_contador)
	progreso.add_child(fila)
	barra = ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 10)
	barra.max_value = total
	progreso.add_child(barra)
	lbl_objetivo = Estilo.etiqueta("", 13, Estilo.TINTA_SUAVE, 500)
	lbl_objetivo.visible = objetivo < total
	progreso.add_child(lbl_objetivo)
	v.add_child(progreso)

	var tarjeta := PanelContainer.new()
	tarjeta.theme_type_variation = "Formula"
	var calculo := Niveles.calcular(datos.lab, datos.params)
	tarjeta.add_child(Estilo.rich("[b]¿Por qué %s?[/b]\n%s\n[color=%s]La demostración está en la pestaña Teoría.[/color]" % [
		Combinatoria.fmt(total), calculo.formula, Estilo.hex(Estilo.TINTA_SUAVE)], 15))
	v.add_child(tarjeta)

	v.add_child(Estilo.boton("Preguntas del nivel  →", _ir_a_preguntas, "Primario"))
	var botones := HBoxContainer.new()
	botones.add_theme_constant_override("separation", 8)
	var galeria := Estilo.boton("Ver galería", _abrir_galeria)
	galeria.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botones.add_child(galeria)
	var reiniciar := Estilo.boton("Reiniciar reto", _reiniciar, "Fantasma")
	reiniciar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	botones.add_child(reiniciar)
	v.add_child(botones)
	if not DisplayServer.is_touchscreen_available():
		v.add_child(Estilo.rich("[color=%s]%s[/color]" % [Estilo.hex(Estilo.TINTA_SUAVE), _texto_atajos()], 13))
	return _envolver_scroll(v)


func _texto_atajos() -> String:
	match modo:
		"altura":
			return "Teclas: 1 = placa · 2 = ladrillo · Retroceso quita la última pieza."
		"eilers":
			return "Teclas: flechas o WASD mueven el ladrillo azul · R lo gira · G muestra su gemela · Enter registra."
	return "Teclas: 1 a %d ponen una pieza · Retroceso quita la última." % reglas.k


func _pagina_comprobar() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	v.add_child(Estilo.rich("Cambia los parámetros y compara la [b]fórmula[/b] con una [b]enumeración por fuerza bruta[/b]: la computadora genera todas las configuraciones, aplica la definición y cuenta las distintas.", 15))
	var specs: Array = Niveles.LAB[datos.lab]
	for i in specs.size():
		var spec: Array = specs[i]
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 8)
		var nombre := Estilo.etiqueta(spec[0], 15, Estilo.TINTA, 600)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fila.add_child(nombre)
		fila.add_child(Estilo.boton_icono("−", _cambiar_parametro.bind(i, -1), Estilo.SUPERFICIE_2))
		var valor := Estilo.etiqueta(str(datos.params[i]), 20, Estilo.TINTA, 900, true)
		valor.custom_minimum_size = Vector2(40, 0)
		valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fila.add_child(valor)
		fila.add_child(Estilo.boton_icono("+", _cambiar_parametro.bind(i, 1), Estilo.SUPERFICIE_2))
		v.add_child(fila)
		valores_lab.append(int(datos.params[i]))
		etiquetas_lab.append(valor)
	var tarjeta := PanelContainer.new()
	tarjeta.theme_type_variation = "Formula"
	lab_res = Estilo.rich("", 15)
	tarjeta.add_child(lab_res)
	v.add_child(tarjeta)
	v.add_child(Estilo.rich("[color=%s][b]Cómo se enumera:[/b] %s[/color]" % [Estilo.hex(Estilo.TINTA_SUAVE), Niveles.METODO[datos.lab]], 13))
	return _envolver_scroll(v)


func _crear_galeria() -> void:
	var modal := Estilo.capa_modal(self)
	capa_galeria = modal[0]
	_margen_galeria = modal[1]
	var v: VBoxContainer = modal[2]
	_panel_galeria = modal[3]
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	lbl_galeria = Estilo.titulo("Galería", 22)
	cab.add_child(lbl_galeria)
	var cuenta := Estilo.chip("", Estilo.COLOR_OK.darkened(0.15), Estilo.COLOR_OK_SUAVE, 13)
	_cuenta_galeria = cuenta.get_child(0)
	cab.add_child(cuenta)
	var espacio := Control.new()
	espacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(espacio)
	var rev := Estilo.boton("Revelar", _alternar_revelar)
	rev.toggle_mode = true
	rev.add_theme_stylebox_override("pressed", Estilo.caja(Estilo.ACENTO_SUAVE, 12, Vector2(18, 10)))
	rev.add_theme_color_override("font_pressed_color", Estilo.ACENTO)
	cab.add_child(rev)
	cab.add_child(Estilo.boton_icono("✕", _cerrar_galeria, Estilo.SUPERFICIE_2))
	v.add_child(cab)
	var explicacion := "El enumerador generó [b]todas[/b] las configuraciones aplicando la definición del reto, no la fórmula. Las que ya encontraste tienen ✓."
	if modo == "eilers":
		explicacion += " Cada casilla es una construcción distinta (una órbita) vista desde arriba: rojo = ladrillo de abajo, azul = el de arriba."
	v.add_child(Estilo.rich("[color=%s]%s[/color]" % [Estilo.hex(Estilo.TINTA_SUAVE), explicacion], 14))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	grid_galeria = GridContainer.new()
	grid_galeria.add_theme_constant_override("h_separation", 10)
	grid_galeria.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid_galeria)


## Una o dos columnas según el ancho disponible.
func _disponer() -> void:
	var tam := get_viewport_rect().size
	var estrecho := tam.x < Estilo.ANCHO_ESTRECHO
	Estilo.fijar_margen(_margen, 12 if estrecho else 20)
	_cuerpo.vertical = estrecho
	_izq.size_flags_vertical = Control.SIZE_FILL if estrecho else Control.SIZE_EXPAND_FILL
	_marco.size_flags_vertical = Control.SIZE_FILL if estrecho else Control.SIZE_EXPAND_FILL
	_marco.custom_minimum_size.y = clampf(tam.y * 0.36, 240.0, 380.0) if estrecho else 0.0
	_panel.size_flags_vertical = Control.SIZE_FILL if estrecho else Control.SIZE_EXPAND_FILL
	_panel.custom_minimum_size.x = 0.0 if estrecho else 420.0
	_titulo.add_theme_font_size_override("font_size", 22 if estrecho else 26)
	if _acciones_eilers:
		_acciones_eilers.vertical = estrecho
	# En una columna se desplaza la página entera, no cada pestaña.
	for p in _paginas:
		p.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED if estrecho else ScrollContainer.SCROLL_MODE_AUTO
		# En una columna la pestaña no se desplaza sola: que el gesto llegue a la página.
		p.mouse_filter = Control.MOUSE_FILTER_IGNORE if estrecho else Control.MOUSE_FILTER_PASS
	Estilo.fijar_margen(_margen_galeria, 10 if estrecho else 36)
	Estilo.relleno_modal(_panel_galeria, estrecho)
	_tam_miniatura = Vector2(96, 116) if estrecho else Vector2(104, 124)
	var libre := tam.x - 2.0 * (10.0 if estrecho else 36.0) - 2.0 * (16.0 if estrecho else 24.0) - 14.0
	grid_galeria.columns = maxi(2, floori((libre + 10.0) / (_tam_miniatura.x + 10.0)))


## Ambiente del mundo del nivel y placa base con espacio para la decoración.
func _preparar_escena() -> void:
	var mundo := Mundos.obtener(Mundos.de_nivel(id))
	match modo:
		"torre", "altura":
			vista.preparar_ambiente(mundo, Vector2i(-8, -8), Vector2i(18, 18), Rect2i(0, 0, 2, 2))
		"fila":
			var ancho: int = reglas.n * 3 - 1
			vista.preparar_ambiente(mundo, Vector2i(-7, -7), Vector2i(ancho + 14, 16), Rect2i(0, 0, ancho, 2))
		"eilers":
			vista.preparar_ambiente(mundo, Vector2i(-12, -11), Vector2i(26, 26), Rect2i(-3, -3, 8, 10))


# --- Configuraciones y progreso -------------------------------------------------

## Todas las configuraciones del reto según el enumerador: [{clave, datos}].
func _todas() -> Array:
	var lista := []
	match modo:
		"torre", "fila":
			for s in Enumerador.enumerar_torres(reglas):
				lista.append({"clave": Enumerador.clave_simple(s), "datos": s})
		"altura":
			for s in Enumerador.enumerar_pilas(datos.altura):
				lista.append({"clave": Enumerador.clave_simple(s), "datos": s})
		"eilers":
			for p in Enumerador.clases_eilers(ladrillo.x, ladrillo.y):
				lista.append({"clave": Enumerador.clave_eilers(p), "datos": p})
	return lista


func _cargar_progreso() -> void:
	var validas := {}
	for item in _todas():
		validas[item.clave] = true
	for c in Juego.encontradas(id):
		if validas.has(c) and not encontradas.has(c):
			encontradas[c] = true
			orden.append(c)


## Clave de la forma canónica de la construcción actual.
func _clave_actual() -> String:
	match modo:
		"eilers":
			return Enumerador.clave_eilers(Enumerador.canonica_eilers(pos, ladrillo.x, ladrillo.y))
		"altura":
			return Enumerador.clave_simple(seq)
	return Enumerador.clave(seq, reglas)


func _esta_completa() -> bool:
	if modo == "altura":
		return Enumerador.altura(seq) == datos.altura
	return seq.size() == reglas.n


# --- Acciones del jugador -------------------------------------------------------

func _agregar(pieza: int) -> void:
	if modo == "altura":
		var actual := Enumerador.altura(seq)
		if actual + Enumerador.ALTO_PIEZA[pieza] > datos.altura:
			_mensaje("Así te pasarías de la altura %d (llevas %d)." % [datos.altura, actual], Estilo.COLOR_ERROR)
			return
	else:
		var motivo := Enumerador.motivo_para_no_agregar(seq, pieza, reglas)
		if motivo != "":
			_mensaje(motivo, Estilo.COLOR_ERROR)
			return
	seq.append(pieza)
	_mensaje("", Estilo.COLOR_AVISO)
	_actualizar(true)
	if _esta_completa():
		_registrar()


func _quitar() -> void:
	if seq.is_empty():
		return
	seq.pop_back()
	_mensaje("", Estilo.COLOR_AVISO)
	_actualizar()


func _vaciar() -> void:
	seq.clear()
	_mensaje("", Estilo.COLOR_AVISO)
	_actualizar()


func _registrar() -> void:
	if modo == "torre" or modo == "fila":
		var motivo := Enumerador.motivo_incompleta(seq, reglas)
		if motivo != "":
			_mensaje(motivo + " Quita piezas y prueba otra.", Estilo.COLOR_ERROR)
			return
	var clave := _clave_actual()
	if encontradas.has(clave):
		_mensaje(_texto_repetida(orden.find(clave) + 1), Estilo.COLOR_AVISO)
		return
	encontradas[clave] = true
	orden.append(clave)
	Juego.guardar_encontradas(id, orden)
	var texto := "¡Nueva! Llevas %d de %d." % [orden.size(), total]
	if Juego.pagar_configuracion(id, clave):
		Juego.sumar_monedas(Premios.MONEDAS_CONFIGURACION)
		Juego.sumar_estadistica("configuraciones")
		texto += "  +%d moneda" % Premios.MONEDAS_CONFIGURACION
		if clave == _clave_dorada:
			Juego.sumar_monedas(Premios.MONEDAS_DORADA)
			Juego.sumar_estadistica("doradas")
			Juego.notificar("¡Configuración dorada! +%d monedas" % Premios.MONEDAS_DORADA, "rayo", Estilo.COLOR_AVISO)
	var completo_ahora := orden.size() >= objetivo and not Juego.reto_completado(id)
	if completo_ahora:
		Juego.marcar_reto(id)
		Juego.sumar_monedas(Premios.MONEDAS_RETO)
		Juego.notificar("¡Reto completado! +%d monedas" % Premios.MONEDAS_RETO, "estrella", Estilo.COLOR_OK)
	if orden.size() == total and Juego.completar_galeria(id):
		Juego.sumar_estadistica("galerias_completas")
	if clave == _clave_dorada:
		texto = "¡Bonus! Encontraste la configuración dorada."
		_anunciar("¡Dorada! ★", Estilo.COLOR_AVISO)
	elif orden.size() == total:
		texto = "¡Las encontraste todas: exactamente %d, como predice la fórmula! Sigue con las preguntas del nivel." % total
		_anunciar("¡%d de %d! ★" % [total, total])
	elif completo_ahora and clave != _clave_dorada:
		texto = "¡Reto completado! Puedes seguir buscando hasta las %d o pasar a las preguntas." % total
		_anunciar("¡Reto completado! ★")
	_mensaje(texto, Estilo.COLOR_OK)
	_actualizar()


func _texto_repetida(n: int) -> String:
	match modo:
		"fila":
			if datos.get("bolsa", false):
				return "Esa bolsa ya la tenías (#%d): en una bolsa sólo importa cuántos ladrillos hay de cada color." % n
			return "Esa selección ya la tenías (#%d): en un conjunto el orden no importa." % n
		"eilers":
			var g := Enumerador.girar_180(pos, ladrillo.x, ladrillo.y)
			if g == pos:
				return "Ya la tenías (#%d). Esta posición es simétrica: el giro de 180° la deja igual." % n
			return "Ya la tenías (#%d). Recuerda: esta posición y su gemela (%s, %s) girada 180° son la misma construcción." % [n, Combinatoria.fmt(g.x), Combinatoria.fmt(g.y)]
	return "Esa ya la tenías (#%d). Cambia alguna pieza." % n


func _mover(pantalla: Vector2i) -> void:
	var d := vista.direccion_rejilla(pantalla)
	var nueva := Vector3i(pos.x + d.x, pos.y + d.y, pos.z)
	if not Enumerador.se_solapa(nueva, ladrillo.x, ladrillo.y):
		_mensaje("Ahí ya no encajaría: debe compartir al menos un stud con el ladrillo de abajo.", Estilo.COLOR_ERROR)
		return
	pos = nueva
	_mensaje("", Estilo.COLOR_AVISO)
	_actualizar()


## Gira el ladrillo de arriba 90° conservando (en lo posible) su centro.
func _girar() -> void:
	var a := ladrillo.x
	var b := ladrillo.y
	var d := Enumerador.dims(pos.z, a, b)
	var o := 0 if a == b else 1 - pos.z
	var d2 := Enumerador.dims(o, a, b)
	var x := floori((2 * pos.x + d.x - d2.x) / 2.0)
	var y := floori((2 * pos.y + d.y - d2.y) / 2.0)
	pos = Enumerador.ajustar(Vector3i(x, y, o), a, b)
	_mensaje("", Estilo.COLOR_AVISO)
	_actualizar()


func _alternar_gemela() -> void:
	ver_gemela = not ver_gemela
	btn_gemela.set_pressed_no_signal(ver_gemela)
	_actualizar()


func _reiniciar() -> void:
	encontradas.clear()
	orden.clear()
	seq.clear()
	Juego.guardar_encontradas(id, orden)
	_mensaje("Reto reiniciado. Tus estrellas se conservan.", Estilo.COLOR_AVISO)
	_actualizar()


func _ir_a_preguntas() -> void:
	Juego.ir_a_quiz(datos.temas, 5, id, "Nivel %d · %s" % [id + 1, datos.titulo])


# --- Dibujo ---------------------------------------------------------------------

func _actualizar(animar := false) -> void:
	var piezas := []
	var animada := -1
	var alto_ladrillo := VistaLadrillos.ALTO_LADRILLO
	match modo:
		"torre":
			for i in seq.size():
				piezas.append({"pos": Vector3(0, i * alto_ladrillo, 0), "tam": Vector2i(2, 2), "alto": alto_ladrillo, "color": Estilo.PALETA[seq[i]]})
			animada = seq.size() - 1
			var alto_total: float = reglas.n * alto_ladrillo
			vista.enfocar(Vector3(1, alto_total * 0.45, 1), 8.0 + alto_total * 1.3)
		"fila":
			var ordenada := seq.duplicate()
			ordenada.sort()
			for i in ordenada.size():
				piezas.append({"pos": Vector3(i * 3, 0, 0), "tam": Vector2i(2, 2), "alto": alto_ladrillo, "color": Estilo.PALETA[ordenada[i]]})
			if not seq.is_empty():
				animada = ordenada.rfind(seq[-1])
			vista.enfocar(Vector3(reglas.n * 1.5 - 0.5, 0.5, 1), 7.0 + reglas.n * 2.2)
		"altura":
			var y := 0.0
			for t in seq:
				var alto: float = VistaLadrillos.ALTO_PLACA * Enumerador.ALTO_PIEZA[t]
				piezas.append({"pos": Vector3(0, y, 0), "tam": Vector2i(2, 2), "alto": alto, "color": Estilo.COLOR_PLACA if t == 0 else Estilo.COLOR_LADRILLO})
				y += alto
			animada = seq.size() - 1
			var meta: float = datos.altura * VistaLadrillos.ALTO_PLACA
			# Marca transparente a la altura que hay que alcanzar.
			piezas.append({"pos": Vector3(0, meta, 0), "tam": Vector2i(2, 2), "alto": 0.05, "color": Estilo.ACENTO, "fantasma": true, "studs": false, "margen": 0.45})
			vista.enfocar(Vector3(1, meta * 0.5, 1), 8.0 + meta * 1.2)
		"eilers":
			var a := ladrillo.x
			var b := ladrillo.y
			piezas.append({"pos": Vector3.ZERO, "tam": Vector2i(a, b), "alto": alto_ladrillo, "color": Estilo.PALETA[0]})
			piezas.append({"pos": Vector3(pos.x, alto_ladrillo, pos.y), "tam": Enumerador.dims(pos.z, a, b), "alto": alto_ladrillo, "color": Estilo.PALETA[1], "sombra": true})
			if ver_gemela:
				var g := Enumerador.girar_180(pos, a, b)
				piezas.append({"pos": Vector3(g.x, alto_ladrillo, g.y), "tam": Enumerador.dims(g.z, a, b), "alto": alto_ladrillo, "color": Estilo.PALETA[2], "fantasma": true, "margen": 0.03})
			vista.enfocar(Vector3(a / 2.0, alto_ladrillo, b / 2.0), 15.0)
	vista.mostrar(piezas, animada if animar else -1)
	_actualizar_textos()


func _actualizar_textos() -> void:
	lbl_contador.text = "%d / %d" % [orden.size(), total]
	lbl_contador_vista.text = "✓ %d / %d" % [orden.size(), total]
	lbl_objetivo.text = "Objetivo del reto: al menos %d." % objetivo
	barra.value = orden.size()
	lbl_estado.text = _describir_estado()
	if encontradas.has(_clave_dorada):
		_lbl_bonus.text = "[b]¡Bonus conseguido![/b] Ya encontraste la configuración dorada de este nivel (+%d monedas)." % Premios.MONEDAS_DORADA
	else:
		_lbl_bonus.text = "[b]Bonus:[/b] una de las configuraciones es [b]dorada[/b] y vale +%d monedas extra. ¡Encuéntrala!" % Premios.MONEDAS_DORADA
	var inventario: Array = reglas.get("inventario", [])
	for c in botones_pieza.size():
		var texto: String = "+ " + Estilo.NOMBRES[c].capitalize()
		if not inventario.is_empty():
			texto += " · %d" % (int(inventario[c]) - seq.count(c))
		botones_pieza[c].text = texto


func _cuadro(c: int) -> String:
	return "[color=%s]■[/color] %s" % [Estilo.hex(Estilo.PALETA[c]), Estilo.NOMBRES[c]]


func _describir_estado() -> String:
	var suave := Estilo.hex(Estilo.TINTA_SUAVE)
	match modo:
		"torre":
			if seq.is_empty():
				return "[b]Torre vacía.[/b] Pon el primer ladrillo."
			var partes := PackedStringArray()
			for c in seq:
				partes.append(_cuadro(c))
			return "[b]Torre[/b] (de abajo arriba): %s   [color=%s]%d de %d[/color]" % [", ".join(partes), suave, seq.size(), reglas.n]
		"fila":
			var ordenada := seq.duplicate()
			ordenada.sort()
			if datos.get("bolsa", false):
				var cuentas := PackedStringArray()
				var estrellas := PackedStringArray()
				for c in reglas.k:
					var n := seq.count(c)
					if n > 0:
						cuentas.append("%d %s" % [n, Estilo.NOMBRES[c] if n == 1 else Estilo.PLURALES[c]])
					estrellas.append("★".repeat(n))
				var contenido := ", ".join(cuentas) if not cuentas.is_empty() else "vacía"
				return "[b]Bolsa:[/b] %s   [color=%s]%d de %d[/color]\nEstrellas y barras: [b]%s[/b]" % [contenido, suave, seq.size(), reglas.n, "|".join(estrellas)]
			var partes := PackedStringArray()
			for c in ordenada:
				partes.append(_cuadro(c))
			return "[b]Selección:[/b] {%s}   [color=%s]%d de %d[/color]" % [", ".join(partes), suave, seq.size(), reglas.n]
		"altura":
			var nombres := PackedStringArray()
			for t in seq:
				nombres.append("placa" if t == 0 else "ladrillo")
			var detalle := ("  [color=%s](%s)[/color]" % [suave, " + ".join(nombres)]) if not nombres.is_empty() else ""
			return "[b]Altura:[/b] %d de %d%s" % [Enumerador.altura(seq), datos.altura, detalle]
		"eilers":
			var g := Enumerador.girar_180(pos, ladrillo.x, ladrillo.y)
			var texto := "[b]Ladrillo azul:[/b] x = %s, y = %s, %s." % [Combinatoria.fmt(pos.x), Combinatoria.fmt(pos.y), "paralelo" if pos.z == 0 else "perpendicular"]
			if g == pos:
				texto += "  [color=%s]El giro ρ la deja igual: es un punto fijo.[/color]" % Estilo.hex(Estilo.COLOR_OK)
			else:
				texto += "  [color=%s]Gemela ρ(p): x = %s, y = %s.[/color]" % [suave, Combinatoria.fmt(g.x), Combinatoria.fmt(g.y)]
			return texto
	return ""


## Aviso bajo los controles, con el color de su tipo; vacío lo oculta.
func _mensaje(texto: String, color: Color) -> void:
	_toast.visible = texto != ""
	lbl_mensaje.text = texto
	lbl_mensaje.add_theme_color_override("font_color", color.darkened(0.15))
	var fondo := Estilo.COLOR_AVISO_SUAVE
	if color == Estilo.COLOR_OK:
		fondo = Estilo.COLOR_OK_SUAVE
	elif color == Estilo.COLOR_ERROR:
		fondo = Estilo.COLOR_ERROR_SUAVE
	_toast.add_theme_stylebox_override("panel", Estilo.caja(fondo, 12, Vector2(14, 10)))


func _anunciar(texto: String, color := Estilo.COLOR_OK) -> void:
	lbl_anuncio.text = texto
	lbl_anuncio.add_theme_color_override("font_color", color)
	lbl_anuncio.modulate.a = 1.0
	lbl_anuncio.pivot_offset = lbl_anuncio.size / 2
	lbl_anuncio.scale = Vector2(0.7, 0.7)
	var tw := create_tween()
	tw.tween_property(lbl_anuncio, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.2)
	tw.tween_property(lbl_anuncio, "modulate:a", 0.0, 0.5)


# --- Galería y laboratorio --------------------------------------------------------

func _abrir_galeria() -> void:
	for hijo in grid_galeria.get_children():
		hijo.queue_free()
	var todas := _todas()
	for i in todas.size():
		var mini := Miniatura.new()
		mini.modo = modo
		mini.datos = todas[i].datos
		mini.ladrillo = ladrillo
		mini.numero = i + 1
		mini.encontrada = encontradas.has(todas[i].clave)
		mini.revelar = revelar
		mini.dorada = todas[i].clave == _clave_dorada and mini.encontrada
		mini.tam = _tam_miniatura
		grid_galeria.add_child(mini)
	_cuenta_galeria.text = "✓ %d de %d" % [orden.size(), todas.size()]
	Estilo.dejar_pasar_arrastre(grid_galeria)
	capa_galeria.visible = true


func _cerrar_galeria() -> void:
	capa_galeria.visible = false


func _alternar_revelar() -> void:
	revelar = not revelar
	for mini in grid_galeria.get_children():
		mini.revelar = revelar
		mini.queue_redraw()


func _cambiar_parametro(i: int, delta: int) -> void:
	var spec: Array = Niveles.LAB[datos.lab][i]
	valores_lab[i] = clampi(valores_lab[i] + delta, spec[1], spec[2])
	etiquetas_lab[i].text = str(valores_lab[i])
	_calcular_lab()


func _calcular_lab() -> void:
	var r := Niveles.calcular(datos.lab, valores_lab, true)
	var texto := "[b]Fórmula:[/b] %s\n" % r.formula
	if r.enumerado < 0:
		texto += "[b]Enumeración:[/b] habría que revisar %s casos, demasiados para hacerlo aquí. Prueba con valores más pequeños." % Combinatoria.fmt(r.costo)
	else:
		texto += "[b]Enumeración por fuerza bruta:[/b] %s configuraciones distintas.\n" % Combinatoria.fmt(r.enumerado)
		if r.enumerado == r.valor:
			texto += "[color=%s][b]✓ La fórmula y la enumeración coinciden.[/b][/color]" % Estilo.hex(Estilo.COLOR_OK)
		else:
			texto += "[color=%s][b]✗ No coinciden.[/b][/color]" % Estilo.hex(Estilo.COLOR_ERROR)
	lab_res.text = texto


# --- Entrada ----------------------------------------------------------------------

func _al_tocar_vista(event: InputEvent) -> void:
	# Dos dedos: pellizcar para acercar o alejar.
	var toque := event as InputEventScreenTouch
	if toque:
		if toque.pressed:
			_toques[toque.index] = toque.position
		else:
			_toques.erase(toque.index)
		return
	var arrastre := event as InputEventScreenDrag
	if arrastre:
		if _toques.size() == 2 and _toques.has(arrastre.index):
			var otro := Vector2.ZERO
			for k in _toques:
				if k != arrastre.index:
					otro = _toques[k]
			var antes: float = _toques[arrastre.index].distance_to(otro)
			var ahora := arrastre.position.distance_to(otro)
			if antes > 1.0 and ahora > 1.0:
				vista.acercar(antes / ahora)
		_toques[arrastre.index] = arrastre.position
		return
	var movimiento := event as InputEventMouseMotion
	if movimiento and _toques.size() < 2 and movimiento.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT):
		vista.orbitar(movimiento.relative)
		return
	var boton := event as InputEventMouseButton
	if boton and boton.pressed:
		if boton.button_index == MOUSE_BUTTON_WHEEL_UP:
			vista.acercar(0.9)
		elif boton.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			vista.acercar(1.1)
		return
	var pellizco := event as InputEventMagnifyGesture
	if pellizco:
		vista.acercar(1.0 / pellizco.factor)


func _unhandled_input(event: InputEvent) -> void:
	var tecla := event as InputEventKey
	if tecla == null or not tecla.pressed:
		return
	var codigo := tecla.keycode
	if capa_galeria.visible:
		if codigo == KEY_ESCAPE:
			_cerrar_galeria()
			get_viewport().set_input_as_handled()
		return
	var manejada := true
	if modo == "eilers":
		match codigo:
			KEY_LEFT, KEY_A:
				_mover(Vector2i(-1, 0))
			KEY_RIGHT, KEY_D:
				_mover(Vector2i(1, 0))
			KEY_UP, KEY_W:
				_mover(Vector2i(0, -1))
			KEY_DOWN, KEY_S:
				_mover(Vector2i(0, 1))
			KEY_R:
				if not tecla.echo:
					_girar()
			KEY_G:
				if not tecla.echo:
					_alternar_gemela()
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
				if not tecla.echo:
					_registrar()
			KEY_ESCAPE:
				Juego.ir_a_menu()
			_:
				manejada = false
	elif tecla.echo:
		manejada = false
	elif codigo >= KEY_1 and codigo <= KEY_9:
		var i := codigo - KEY_1
		if i < botones_pieza.size() or (modo == "altura" and i < 2):
			_agregar(i)
	elif codigo == KEY_BACKSPACE or codigo == KEY_DELETE:
		_quitar()
	elif codigo == KEY_ESCAPE:
		Juego.ir_a_menu()
	else:
		manejada = false
	if manejada:
		get_viewport().set_input_as_handled()


# --- Apoyo para la prueba automática ------------------------------------------------

## Juega el reto completo: arma la primera configuración pieza por pieza, como lo
## haría el jugador, y registra después todas las demás.
func resolver_automaticamente() -> void:
	var todas := _todas()
	if modo != "eilers" and not todas.is_empty():
		_vaciar()
		for pieza in todas[0].datos:
			_agregar(pieza)
	for item in todas:
		if modo == "eilers":
			pos = item.datos
		else:
			seq = item.datos.duplicate()
		_registrar()
	if modo == "eilers":
		_mover(Vector2i(1, 0))
		_girar()


## Deja una construcción de ejemplo en pantalla (para las capturas).
func preparar_captura() -> void:
	if modo == "eilers":
		pos = Vector3i(-2, 0, 1)
		if not ver_gemela:
			_alternar_gemela()
	else:
		var todas := _todas()
		seq = todas[mini(3, todas.size() - 1)].datos.duplicate()
	_registrar()
	_actualizar()
