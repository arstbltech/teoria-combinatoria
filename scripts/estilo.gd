class_name Estilo
extends RefCounted
## Colores, tema visual y pequeñas fábricas de controles para armar la interfaz.

const PALETA := [Color("c91a09"), Color("0055bf"), Color("f2cd37"), Color("237841"), Color("fe8a18")]
const NOMBRES := ["rojo", "azul", "amarillo", "verde", "naranja"]
const PLURALES := ["rojos", "azules", "amarillos", "verdes", "naranjas"]
const COLOR_PLACA := Color("fe8a18")
const COLOR_LADRILLO := Color("0055bf")
const COLOR_BASE := Color("3f8f34")
const COLOR_FONDO_3D := Color("d9ecf7")

const FONDO := Color("fbf5e6")
const TINTA := Color("2b2620")
const TINTA_SUAVE := Color("7a6f5c")
const ACENTO := Color("c91a09")
const BORDE := Color("e2d6bd")
const CREMA := Color("fff6d6")
const COLOR_OK := Color("237841")
const COLOR_ERROR := Color("c91a09")
const COLOR_AVISO := Color("8f6400")
const COLOR_ESTRELLA := Color("d99a00")


static func fuente(negrita := false) -> Font:
	return load("res://fonts/DejaVuSans-Bold.ttf" if negrita else "res://fonts/DejaVuSans.ttf")


static func crear_tema() -> Theme:
	var t := Theme.new()
	var negrita := fuente(true)
	t.default_font = fuente()
	t.default_font_size = 18

	t.set_color("font_color", "Label", TINTA)
	t.set_color("default_color", "RichTextLabel", TINTA)
	t.set_font("normal_font", "RichTextLabel", fuente())
	t.set_font("bold_font", "RichTextLabel", negrita)
	t.set_font("italics_font", "RichTextLabel", load("res://fonts/DejaVuSans-Oblique.ttf"))
	t.set_font("bold_italics_font", "RichTextLabel", negrita)
	t.set_constant("line_separation", "RichTextLabel", 4)

	t.set_font("font", "Button", negrita)
	t.set_stylebox("normal", "Button", caja(Color.WHITE, BORDE))
	t.set_stylebox("hover", "Button", caja(CREMA, Color("e8c547")))
	t.set_stylebox("pressed", "Button", caja(Color("f6d75a"), Color("c9a400")))
	t.set_stylebox("hover_pressed", "Button", caja(Color("f6d75a"), Color("c9a400")))
	t.set_stylebox("disabled", "Button", caja(Color("f3eee3"), Color("e8e0cf")))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for nombre in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(nombre, "Button", TINTA)
	t.set_color("font_disabled_color", "Button", Color("b3a98f"))

	t.set_stylebox("panel", "PanelContainer", caja(Color.WHITE, BORDE, 14, 14, 2))

	t.set_stylebox("panel", "TabContainer", caja(Color.WHITE, BORDE, 12, 14, 2))
	t.set_stylebox("tab_selected", "TabContainer", _pestana(Color.WHITE, BORDE))
	t.set_stylebox("tab_hovered", "TabContainer", _pestana(CREMA, BORDE))
	t.set_stylebox("tab_unselected", "TabContainer", _pestana(Color("f1e9d6"), Color("f1e9d6")))
	t.set_stylebox("tab_focus", "TabContainer", StyleBoxEmpty.new())
	t.set_font("font", "TabContainer", negrita)
	t.set_color("font_selected_color", "TabContainer", TINTA)
	t.set_color("font_hovered_color", "TabContainer", TINTA)
	t.set_color("font_unselected_color", "TabContainer", TINTA_SUAVE)

	t.set_stylebox("background", "ProgressBar", caja(Color("efe6d2"), Color("efe6d2"), 8, 0, 0))
	t.set_stylebox("fill", "ProgressBar", caja(COLOR_OK, COLOR_OK, 8, 0, 0))

	var riel := StyleBoxFlat.new()
	riel.bg_color = Color("efe6d2")
	riel.set_corner_radius_all(6)
	riel.set_content_margin_all(5)
	var agarre := StyleBoxFlat.new()
	agarre.bg_color = Color("c9bb9b")
	agarre.set_corner_radius_all(6)
	agarre.set_content_margin_all(5)
	for barra in ["VScrollBar", "HScrollBar"]:
		t.set_stylebox("scroll", barra, riel)
		t.set_stylebox("grabber", barra, agarre)
		t.set_stylebox("grabber_highlight", barra, agarre)
		t.set_stylebox("grabber_pressed", barra, agarre)
	return t


## Caja redondeada con borde inferior más grueso, como un ladrillo visto de frente.
static func caja(fondo_: Color, borde: Color, radio := 10, margen_ := 10, abajo := 4) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo_
	s.border_color = borde
	s.set_border_width_all(2 if abajo > 0 else 0)
	s.border_width_bottom = abajo
	s.set_corner_radius_all(radio)
	s.content_margin_left = margen_ + 4
	s.content_margin_right = margen_ + 4
	s.content_margin_top = margen_ * 0.6
	s.content_margin_bottom = margen_ * 0.6
	return s


static func _pestana(fondo_: Color, borde: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fondo_
	s.border_color = borde
	s.border_width_top = 2
	s.border_width_left = 2
	s.border_width_right = 2
	s.corner_radius_top_left = 10
	s.corner_radius_top_right = 10
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s


static func etiqueta(texto: String, tam := 18, color := TINTA, negrita := false) -> Label:
	var l := Label.new()
	l.text = texto
	l.add_theme_font_size_override("font_size", tam)
	l.add_theme_color_override("font_color", color)
	if negrita:
		l.add_theme_font_override("font", fuente(true))
	return l


static func rich(bbcode: String, tam := 18) -> RichTextLabel:
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


static func boton(texto: String, accion: Callable, tam := 18) -> Button:
	var b := Button.new()
	b.text = texto
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", tam)
	b.pressed.connect(accion)
	return b


## Botón del color de una pieza, con el texto en blanco o negro según el contraste.
static func pintar_boton(b: Button, color: Color) -> void:
	var texto := TINTA if color.get_luminance() > 0.5 else Color.WHITE
	var borde := color.darkened(0.3)
	b.add_theme_stylebox_override("normal", caja(color, borde))
	b.add_theme_stylebox_override("hover", caja(color.lightened(0.15), borde))
	b.add_theme_stylebox_override("pressed", caja(color.darkened(0.12), borde.darkened(0.2)))
	b.add_theme_stylebox_override("hover_pressed", caja(color.darkened(0.12), borde.darkened(0.2)))
	b.add_theme_stylebox_override("disabled", caja(color.lerp(Color.WHITE, 0.6), color.lerp(Color.WHITE, 0.45)))
	for nombre in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		b.add_theme_color_override(nombre, texto)


static func fondo() -> ColorRect:
	var f := ColorRect.new()
	f.color = FONDO
	f.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	f.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return f


static func margen(m: int) -> MarginContainer:
	var c := MarginContainer.new()
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for lado in ["left", "top", "right", "bottom"]:
		c.add_theme_constant_override("margin_" + lado, m)
	return c


## Capa oscura a pantalla completa con un panel centrado; devuelve [capa, contenido].
static func capa_modal(padre: Control, margen_ := 36) -> Array:
	var capa := Control.new()
	capa.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.visible = false
	padre.add_child(capa)
	var sombra := ColorRect.new()
	sombra.color = Color(0.1, 0.08, 0.05, 0.55)
	sombra.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	capa.add_child(sombra)
	var m := margen(margen_)
	capa.add_child(m)
	var panel := PanelContainer.new()
	m.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	panel.add_child(v)
	return [capa, v]


static func estrellas(n: int, maximo := 3) -> String:
	return "★".repeat(n) + "☆".repeat(maximo - n)


static func hex(color: Color) -> String:
	return "#" + color.to_html(false)
