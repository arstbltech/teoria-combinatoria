class_name Estilo
extends RefCounted
## Sistema visual: colores, tipografía, tema y pequeñas fábricas de controles.
## Texto en Inter; títulos en Nunito. DejaVu queda de respaldo para los
## símbolos matemáticos que Inter no trae (∎, ⌊⌋, ℤ, …).

# Colores de las piezas (también en la escena 3D).
const PALETA := [Color("ef4136"), Color("1f6feb"), Color("ffc531"), Color("1fae66"), Color("ff8a1f")]
const NOMBRES := ["rojo", "azul", "amarillo", "verde", "naranja"]
const PLURALES := ["rojos", "azules", "amarillos", "verdes", "naranjas"]
const COLOR_PLACA := Color("ff8a1f")
const COLOR_LADRILLO := Color("1f6feb")
const COLOR_BASE := Color("b4bfd8")
const COLOR_FONDO_3D := Color("e6eaf6")

# Interfaz.
const FONDO := Color("f5f6fb")
const SUPERFICIE := Color("ffffff")
const SUPERFICIE_2 := Color("f0f2f8")
const BORDE := Color("e3e6ef")
const TINTA := Color("1b1f3b")
const TINTA_SUAVE := Color("6b7186")
const ACENTO := Color("5b55f0")
const ACENTO_SUAVE := Color("eeedff")
const COLOR_OK := Color("12a865")
const COLOR_OK_SUAVE := Color("e5f7ee")
const COLOR_ERROR := Color("e5483b")
const COLOR_ERROR_SUAVE := Color("fdecea")
const COLOR_AVISO := Color("b25e09")
const COLOR_AVISO_SUAVE := Color("fff3e2")
const COLOR_ESTRELLA := Color("f5a524")
const SOMBRA := Color(0.09, 0.1, 0.25, 0.08)

## Ancho (en unidades de la interfaz) por debajo del cual se usa el diseño de una columna.
const ANCHO_ESTRECHO := 820.0

static var _fuentes := {}


## Fuente con el peso indicado (100–900). `titulo` usa Nunito en vez de Inter.
static func fuente(peso := 400, titulo := false, cursiva := false) -> Font:
	var clave := "%s%d%s" % ["t" if titulo else "c", peso, "i" if cursiva else ""]
	if not _fuentes.has(clave):
		var f := FontVariation.new()
		f.base_font = load("res://fonts/Nunito.ttf" if titulo else "res://fonts/Inter.ttf")
		# El eje se indica con su etiqueta numérica; el nombre "wght" no siempre se reconoce.
		f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): peso}
		if cursiva:
			f.variation_transform = Transform2D(Vector2(1, 0), Vector2(0.2, 1), Vector2.ZERO)
		var respaldo: Array[Font] = [load("res://fonts/DejaVuSans-Bold.ttf" if peso >= 600 else "res://fonts/DejaVuSans.ttf")]
		f.fallbacks = respaldo
		_fuentes[clave] = f
	return _fuentes[clave]


static func es_estrecho(control: Control) -> bool:
	return control.get_viewport_rect().size.x < ANCHO_ESTRECHO


# --- Tema ---------------------------------------------------------------------

static func crear_tema() -> Theme:
	var t := Theme.new()
	t.default_font = fuente(400)
	t.default_font_size = 17

	t.set_color("font_color", "Label", TINTA)
	t.set_color("default_color", "RichTextLabel", TINTA)
	t.set_font("normal_font", "RichTextLabel", fuente(400))
	t.set_font("bold_font", "RichTextLabel", fuente(700))
	t.set_font("italics_font", "RichTextLabel", fuente(400, false, true))
	t.set_font("bold_italics_font", "RichTextLabel", fuente(700, false, true))
	t.set_constant("line_separation", "RichTextLabel", 5)

	# Botón base = secundario: gris suave, sin borde.
	t.set_font("font", "Button", fuente(600))
	_estilos_boton(t, "Button", SUPERFICIE_2, SUPERFICIE_2.darkened(0.04), SUPERFICIE_2.darkened(0.08), TINTA)
	t.set_color("font_disabled_color", "Button", TINTA_SUAVE.lerp(Color.WHITE, 0.4))
	t.set_stylebox("disabled", "Button", caja(SUPERFICIE_2.lerp(Color.WHITE, 0.4), 12, Vector2(18, 10)))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())

	t.set_type_variation("Primario", "Button")
	_estilos_boton(t, "Primario", ACENTO, ACENTO.lightened(0.08), ACENTO.darkened(0.1), Color.WHITE)
	for estado in ["normal", "hover"]:
		var s: StyleBoxFlat = t.get_stylebox(estado, "Primario")
		s.shadow_color = Color(ACENTO, 0.28)
		s.shadow_size = 8
		s.shadow_offset = Vector2(0, 3)

	t.set_type_variation("Fantasma", "Button")
	_estilos_boton(t, "Fantasma", Color(SUPERFICIE_2, 0.0), SUPERFICIE_2, SUPERFICIE_2.darkened(0.05), TINTA_SUAVE)
	t.set_color("font_hover_color", "Fantasma", TINTA)

	# Pestañas tipo «segmento»: la elegida es una pastilla blanca con sombra.
	t.set_type_variation("Segmento", "Button")
	var segmento := caja(Color(1, 1, 1, 0), 10, Vector2(14, 8))
	t.set_stylebox("normal", "Segmento", segmento)
	t.set_stylebox("hover", "Segmento", segmento)
	var elegido := caja(SUPERFICIE, 10, Vector2(14, 8), 6)
	t.set_stylebox("pressed", "Segmento", elegido)
	t.set_stylebox("hover_pressed", "Segmento", elegido)
	t.set_color("font_color", "Segmento", TINTA_SUAVE)
	t.set_color("font_hover_color", "Segmento", TINTA)
	t.set_color("font_pressed_color", "Segmento", ACENTO)
	t.set_color("font_hover_pressed_color", "Segmento", ACENTO)
	t.set_type_variation("Segmentos", "PanelContainer")
	t.set_stylebox("panel", "Segmentos", caja(SUPERFICIE_2, 13, Vector2(4, 4)))

	# Opciones de respuesta.
	t.set_type_variation("Opcion", "Button")
	t.set_font("font", "Opcion", fuente(700))
	t.set_stylebox("normal", "Opcion", caja(SUPERFICIE, 16, Vector2(18, 14), 0, BORDE, 2))
	t.set_stylebox("hover", "Opcion", caja(Color("fafaff"), 16, Vector2(18, 14), 0, ACENTO, 2))
	t.set_stylebox("pressed", "Opcion", caja(ACENTO_SUAVE, 16, Vector2(18, 14), 0, ACENTO, 2))
	for nombre in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(nombre, "Opcion", TINTA)

	# Tarjetas de nivel del menú.
	t.set_type_variation("TarjetaBoton", "Button")
	t.set_stylebox("normal", "TarjetaBoton", caja(SUPERFICIE, 20, Vector2(16, 16), 14, BORDE, 1))
	t.set_stylebox("hover", "TarjetaBoton", caja(SUPERFICIE, 20, Vector2(16, 16), 22, Color("c9c6ff"), 1))
	t.set_stylebox("pressed", "TarjetaBoton", caja(Color("fafaff"), 20, Vector2(16, 16), 8, Color("c9c6ff"), 1))

	# Paneles.
	t.set_stylebox("panel", "PanelContainer", caja(SUPERFICIE, 20, Vector2(20, 18), 18, BORDE, 1))
	t.set_type_variation("Suave", "PanelContainer")
	t.set_stylebox("panel", "Suave", caja(SUPERFICIE_2, 14, Vector2(16, 12)))
	t.set_type_variation("Formula", "PanelContainer")
	var formula := caja(ACENTO_SUAVE, 14, Vector2(16, 12))
	formula.border_color = ACENTO
	formula.border_width_left = 4
	t.set_stylebox("panel", "Formula", formula)
	t.set_type_variation("Chip", "PanelContainer")
	t.set_stylebox("panel", "Chip", caja(ACENTO_SUAVE, 99, Vector2(12, 4)))
	t.set_type_variation("Escena", "PanelContainer")
	# Sin sombra: la escena recorta a sus hijos (clip_children) y la sombra saldría cortada.
	t.set_stylebox("panel", "Escena", caja(COLOR_FONDO_3D, 20, Vector2.ZERO, 0, BORDE, 1))

	t.set_stylebox("background", "ProgressBar", caja(SUPERFICIE_2, 99, Vector2.ZERO))
	t.set_stylebox("fill", "ProgressBar", caja(COLOR_OK, 99, Vector2.ZERO))

	var riel := StyleBoxEmpty.new()
	riel.set_content_margin_all(3)
	var agarre := caja(Color("ccd1df"), 99, Vector2(3, 3))
	for barra in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", barra, riel)
		t.set_stylebox("grabber", barra, agarre)
		t.set_stylebox("grabber_highlight", barra, caja(Color("b3b9cc"), 99, Vector2(3, 3)))
		t.set_stylebox("grabber_pressed", barra, caja(ACENTO, 99, Vector2(3, 3)))

	t.set_stylebox("panel", "TooltipPanel", caja(TINTA, 10, Vector2(10, 6)))
	t.set_color("font_color", "TooltipLabel", Color.WHITE)
	return t


static func _estilos_boton(t: Theme, tipo: String, normal: Color, encima: Color, presionado: Color, texto: Color) -> void:
	t.set_stylebox("normal", tipo, caja(normal, 12, Vector2(18, 10)))
	t.set_stylebox("hover", tipo, caja(encima, 12, Vector2(18, 10)))
	t.set_stylebox("pressed", tipo, caja(presionado, 12, Vector2(18, 10)))
	t.set_stylebox("hover_pressed", tipo, caja(presionado, 12, Vector2(18, 10)))
	for nombre in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(nombre, tipo, texto)


## Caja redondeada con sombra suave opcional y borde opcional.
static func caja(fondo_: Color, radio := 12, relleno := Vector2(16, 10), sombra := 0, borde := Color.TRANSPARENT, grosor := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo_
	s.set_corner_radius_all(radio)
	s.corner_detail = 10
	s.content_margin_left = relleno.x
	s.content_margin_right = relleno.x
	s.content_margin_top = relleno.y
	s.content_margin_bottom = relleno.y
	if grosor > 0:
		s.border_color = borde
		s.set_border_width_all(grosor)
	if sombra > 0:
		s.shadow_color = SOMBRA
		s.shadow_size = sombra
		s.shadow_offset = Vector2(0, roundi(sombra * 0.35))
	return s


# --- Fábricas de controles ----------------------------------------------------

static func etiqueta(texto: String, tam := 17, color := TINTA, peso := 400, titulo := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if peso != 400 or titulo:
		l.add_theme_font_override("font", fuente(peso, titulo))
	return l


static func titulo(texto: String, tam := 28) -> Label:
	return etiqueta(texto, tam, TINTA, 900, true)


static func rich(bbcode: String, tam := 17) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r.mouse_filter = Control.MOUSE_FILTER_PASS
	for clave in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size"]:
		r.add_theme_font_size_override(clave, tam)
	r.text = bbcode
	return r


## Botón; `tipo` es "" (secundario), "Primario", "Fantasma", "Opcion"…
static func boton(texto: String, accion: Callable, tipo := "", tam := 16) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.theme_type_variation = tipo
	b.custom_minimum_size.y = 44
	b.add_theme_font_size_override("font_size", tam)
	b.pressed.connect(accion)
	return b


## Botón redondo con un símbolo (volver, cerrar…).
static func boton_icono(simbolo: String, accion: Callable, fondo_ := SUPERFICIE) -> Button:
	var b := boton(simbolo, accion, "", 20)
	b.custom_minimum_size = Vector2(44, 44)
	var borde := BORDE if fondo_ == SUPERFICIE else Color.TRANSPARENT
	b.add_theme_stylebox_override("normal", caja(fondo_, 22, Vector2.ZERO, 0, borde, 1))
	b.add_theme_stylebox_override("hover", caja(fondo_.darkened(0.04), 22, Vector2.ZERO, 0, borde, 1))
	b.add_theme_stylebox_override("pressed", caja(fondo_.darkened(0.08), 22, Vector2.ZERO, 0, borde, 1))
	return b


## Botón del color de una pieza, con texto blanco u oscuro según el contraste.
static func pintar_boton(b: Button, color: Color) -> void:
	var texto := TINTA if color.get_luminance() > 0.6 else Color.WHITE
	b.add_theme_stylebox_override("normal", caja(color, 12, Vector2(18, 10)))
	b.add_theme_stylebox_override("hover", caja(color.lightened(0.1), 12, Vector2(18, 10)))
	b.add_theme_stylebox_override("pressed", caja(color.darkened(0.1), 12, Vector2(18, 10)))
	b.add_theme_stylebox_override("hover_pressed", caja(color.darkened(0.1), 12, Vector2(18, 10)))
	b.add_theme_stylebox_override("disabled", caja(color.lerp(Color.WHITE, 0.6), 12, Vector2(18, 10)))
	for nombre in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(nombre, texto)


## Pastilla de texto (concepto, tema, contador…).
static func chip(texto: String, color := ACENTO, fondo_ := ACENTO_SUAVE, tam := 13) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", caja(fondo_, 99, Vector2(12, 4)))
	p.add_child(etiqueta(texto, tam, color, 600))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return p


## Pastilla con un ícono y un texto (estrellas, vidas…).
static func pastilla(icono: String, texto: String, tam := 15) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", caja(SUPERFICIE, 99, Vector2(12, 5), 8, BORDE, 1))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p.add_child(fila)
	fila.add_child(Icono.crear(icono, 18))
	fila.add_child(etiqueta(texto, tam, TINTA, 800))
	return p


## Control de pestañas tipo segmento; llama a `al_elegir(i)`.
static func segmentos(titulos: Array, al_elegir: Callable) -> PanelContainer:
	var caja_ := PanelContainer.new()
	caja_.theme_type_variation = "Segmentos"
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 4)
	caja_.add_child(fila)
	var grupo := ButtonGroup.new()
	for i in titulos.size():
		var b := Button.new()
		b.text = titulos[i]
		b.theme_type_variation = "Segmento"
		b.toggle_mode = true
		b.button_group = grupo
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.button_pressed = i == 0
		b.pressed.connect(al_elegir.bind(i))
		fila.add_child(b)
	return caja_


## Fondo con degradado suave y dos manchas de color difuminadas.
static func fondo() -> Control:
	var capa := Control.new()
	capa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var base := ColorRect.new()
	base.color = FONDO
	base.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	capa.add_child(base)
	for mancha in [[Color(ACENTO, 0.13), Vector2(0.95, -0.05)], [Color(PALETA[2], 0.16), Vector2(-0.05, 1.05)]]:
		var g := Gradient.new()
		g.set_color(0, mancha[0])
		g.set_color(1, Color(mancha[0], 0.0))
		var tex := GradientTexture2D.new()
		tex.gradient = g
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(1.0, 0.5)
		tex.width = 256
		tex.height = 256
		var r := TextureRect.new()
		r.texture = tex
		r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		r.stretch_mode = TextureRect.STRETCH_SCALE
		r.mouse_filter = Control.MOUSE_FILTER_IGNORE
		r.anchor_left = mancha[1].x - 0.35
		r.anchor_right = mancha[1].x + 0.35
		r.anchor_top = mancha[1].y - 0.45
		r.anchor_bottom = mancha[1].y + 0.45
		capa.add_child(r)
	return capa


static func margen(m: int) -> MarginContainer:
	var c := MarginContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fijar_margen(c, m)
	return c


static func fijar_margen(c: MarginContainer, m: int) -> void:
	for lado in ["left", "top", "right", "bottom"]:
		c.add_theme_constant_override("margin_" + lado, m)


## Capa oscura a pantalla completa con un panel encima; devuelve [capa, margen, contenido, panel].
static func capa_modal(padre: Control) -> Array:
	var capa := Control.new()
	capa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.visible = false
	padre.add_child(capa)
	var sombra := ColorRect.new()
	sombra.color = Color(0.06, 0.07, 0.18, 0.45)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.add_child(sombra)
	var m := margen(36)
	capa.add_child(m)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", caja(SUPERFICIE, 24, Vector2(24, 20), 30))
	m.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	panel.add_child(v)
	return [capa, m, v, panel]


## Relleno interior de un panel creado con capa_modal (más chico en celulares).
static func relleno_modal(panel: PanelContainer, estrecho: bool) -> void:
	var s: StyleBoxFlat = panel.get_theme_stylebox("panel")
	s.content_margin_left = 16 if estrecho else 24
	s.content_margin_right = s.content_margin_left
	s.content_margin_top = 16 if estrecho else 20
	s.content_margin_bottom = s.content_margin_top


## En pantallas táctiles un panel o botón con MOUSE_FILTER_STOP impide desplazar
## la página si el dedo empieza encima. Esto los cambia a PASS para que el gesto
## llegue al ScrollContainer (la vista 3D se queda en STOP para poder girarla).
static func dejar_pasar_arrastre(nodo: Node) -> void:
	if nodo is SubViewportContainer:
		return
	if nodo is PanelContainer or nodo is Panel or nodo is BaseButton or nodo.get_class() == "Control":
		(nodo as Control).mouse_filter = Control.MOUSE_FILTER_PASS
	for hijo in nodo.get_children():
		dejar_pasar_arrastre(hijo)


## Aparición suave y escalonada (para listas de tarjetas).
static func aparecer(nodo: CanvasItem, retraso := 0.0) -> void:
	nodo.modulate.a = 0.0
	var tw := nodo.create_tween()
	tw.tween_interval(retraso)
	tw.tween_property(nodo, "modulate:a", 1.0, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


static func estrellas(n: int, maximo := 3) -> String:
	return "★".repeat(n) + "☆".repeat(maximo - n)


static func hex(color: Color) -> String:
	return "#" + color.to_html(false)
