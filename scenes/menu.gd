extends Control
## Menú principal: niveles, desafío final y ayuda.

var _btn_borrar: Button
var _confirmar_borrado := false
var _capa_ayuda: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Estilo.fondo())
	var m := Estilo.margen(28)
	add_child(m)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 16)
	m.add_child(v)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 18)
	v.add_child(cab)
	var logo := TextureRect.new()
	logo.texture = load("res://icon.svg")
	logo.custom_minimum_size = Vector2(76, 76)
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	cab.add_child(logo)
	var titulos := VBoxContainer.new()
	titulos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulos.alignment = BoxContainer.ALIGNMENT_CENTER
	titulos.add_child(Estilo.etiqueta("Ladrillos Combinatorios", 42, Estilo.ACENTO, true))
	titulos.add_child(Estilo.etiqueta("Teoría combinatoria armando torres y construcciones con ladrillos", 18, Estilo.TINTA_SUAVE))
	cab.add_child(titulos)
	var ganadas := Juego.estrellas(Juego.DESAFIO)
	for i in Niveles.cantidad():
		ganadas += Juego.estrellas(i)
	cab.add_child(Estilo.etiqueta("★ %d / %d" % [ganadas, (Niveles.cantidad() + 1) * 3], 26, Estilo.COLOR_ESTRELLA, true))

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	for i in Niveles.cantidad():
		grid.add_child(_tarjeta(i))

	var pie := HBoxContainer.new()
	pie.add_theme_constant_override("separation", 12)
	v.add_child(pie)
	var desafio := Estilo.boton("★ Desafío final · 10 preguntas   %s" % Estilo.estrellas(Juego.estrellas(Juego.DESAFIO)), _desafio, 20)
	Estilo.pintar_boton(desafio, Estilo.PALETA[2])
	pie.add_child(desafio)
	pie.add_child(Estilo.boton("Cómo jugar", _mostrar_ayuda, 20))
	var espacio := Control.new()
	espacio.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pie.add_child(espacio)
	_btn_borrar = Estilo.boton("Borrar progreso", _borrar, 16)
	pie.add_child(_btn_borrar)

	_crear_ayuda()


func _tarjeta(i: int) -> Button:
	var d := Niveles.obtener(i)
	var color: Color = Estilo.PALETA[i % Estilo.PALETA.size()]
	var b := Button.new()
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(0, 138)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(Juego.ir_a_nivel.bind(i))

	var m := Estilo.margen(12)
	b.add_child(m)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	m.add_child(h)
	var insignia := PanelContainer.new()
	var estilo := StyleBoxFlat.new()
	estilo.bg_color = color
	estilo.set_corner_radius_all(10)
	estilo.border_width_bottom = 5
	estilo.border_color = color.darkened(0.3)
	insignia.add_theme_stylebox_override("panel", estilo)
	insignia.custom_minimum_size = Vector2(64, 64)
	insignia.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var numero := Estilo.etiqueta(str(i + 1), 28, Estilo.TINTA if color.get_luminance() > 0.5 else Color.WHITE, true)
	numero.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	numero.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	insignia.add_child(numero)
	h.add_child(insignia)
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.alignment = BoxContainer.ALIGNMENT_CENTER
	col.add_theme_constant_override("separation", 2)
	h.add_child(col)
	for etiqueta in [
		Estilo.etiqueta(d.titulo, 20, Estilo.TINTA, true),
		Estilo.etiqueta(d.concepto, 16, Estilo.TINTA_SUAVE),
		Estilo.etiqueta(d.formula_corta, 16, Estilo.ACENTO),
		Estilo.etiqueta(Estilo.estrellas(Juego.estrellas(i)), 20, Estilo.COLOR_ESTRELLA, true),
	]:
		etiqueta.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		col.add_child(etiqueta)
	_ignorar_raton(m)
	return b


## Los hijos de la tarjeta no deben quedarse con los clics del botón.
func _ignorar_raton(nodo: Node) -> void:
	if nodo is Control:
		nodo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for hijo in nodo.get_children():
		_ignorar_raton(hijo)


func _crear_ayuda() -> void:
	var modal := Estilo.capa_modal(self, 60)
	_capa_ayuda = modal[0]
	var v: VBoxContainer = modal[1]
	var cab := HBoxContainer.new()
	var titulo := Estilo.etiqueta("Cómo jugar", 26, Estilo.TINTA, true)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(titulo)
	cab.add_child(Estilo.boton("Cerrar ✕", func() -> void: _capa_ayuda.visible = false))
	v.add_child(cab)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	scroll.add_child(Estilo.rich("\n\n".join(PackedStringArray([
		"[b]¿De qué trata?[/b] Cada nivel es un teorema de combinatoria. Construyes configuraciones con ladrillos y el juego cuenta cuántas distintas encontraste. El total no se adivina: sale de una fórmula demostrada en la pestaña [i]Teoría[/i] y comprobada por fuerza bruta en la pestaña [i]Comprobar[/i].",
		"[b]Cómo se juega[/b]\n• Pon piezas con los botones de colores (o con las teclas 1 a 5) y quítalas con «Quitar la última» (o Retroceso).\n• Cuando la construcción está completa se registra sola. Si ya la tenías, el juego te avisa.\n• En el nivel de los ladrillos 2×4 mueves el ladrillo azul con las flechas, lo giras con R y registras con Enter.\n• Arrastra sobre la vista 3D para girar la cámara y usa la rueda para acercarte.\n• La galería muestra todas las configuraciones posibles; las que no has encontrado aparecen como «?».",
		"[b]Estrellas[/b] (3 por nivel)\n★ completar el reto · ★ acertar al menos 2 de 3 preguntas · ★ acertar las 3.\nEn el desafío final: 50 %, 80 % y 100 % de aciertos.",
		"[b]Cómo entra la combinatoria[/b]\n1. [b]El contador.[/b] El total de cada reto es el valor de la fórmula del teorema.\n2. [b]La forma canónica.[/b] Cada construcción se reduce a un representante: ordenar las piezas de un conjunto o elegir entre una posición y su giro de 180°. Así el juego reconoce las repeticiones, que es lo mismo que contar clases de equivalencia.\n3. [b]La enumeración.[/b] Para valores pequeños la computadora genera todas las configuraciones y verifica la fórmula.\n4. [b]Las preguntas.[/b] Se generan con números al azar y las respuestas incorrectas imitan errores típicos.",
	])), 17))


func _mostrar_ayuda() -> void:
	_capa_ayuda.visible = true


func _desafio() -> void:
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
	if tecla and tecla.pressed and tecla.keycode == KEY_ESCAPE and _capa_ayuda.visible:
		_capa_ayuda.visible = false
		get_viewport().set_input_as_handled()
