extends Control
## Premios: la tienda (se gastan las monedas en objetos que ayudan en las
## preguntas) y la vitrina de logros.

var _margen: MarginContainer
var _columna: VBoxContainer
var _paginas: Array = []
var _tienda: VBoxContainer
var _logros: GridContainer


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
	var centro := HBoxContainer.new()
	centro.alignment = BoxContainer.ALIGNMENT_CENTER
	_margen.add_child(centro)
	_columna = VBoxContainer.new()
	_columna.add_theme_constant_override("separation", 16)
	_columna.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	centro.add_child(_columna)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	cab.add_child(Estilo.boton_icono("←", Juego.ir_a_menu))
	var titulo := Estilo.titulo("Premios", 28)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(titulo)
	cab.add_child(Juego.pastilla_monedas(16))
	_columna.add_child(cab)
	_columna.add_child(Estilo.segmentos(["Tienda", "Logros"], _mostrar_pagina))

	_tienda = VBoxContainer.new()
	_tienda.add_theme_constant_override("separation", 12)
	_columna.add_child(_tienda)
	_paginas.append(_tienda)
	_logros = GridContainer.new()
	_logros.add_theme_constant_override("h_separation", 12)
	_logros.add_theme_constant_override("v_separation", 12)
	_columna.add_child(_logros)
	_paginas.append(_logros)

	_llenar_tienda()
	_llenar_logros()
	_mostrar_pagina(0)
	Estilo.dejar_pasar_arrastre(self)
	Juego.monedas_cambiaron.connect(_al_cambiar_monedas)
	resized.connect(_disponer)
	_disponer()


func _exit_tree() -> void:
	if Juego.monedas_cambiaron.is_connected(_al_cambiar_monedas):
		Juego.monedas_cambiaron.disconnect(_al_cambiar_monedas)


func _disponer() -> void:
	var ancho := get_viewport_rect().size.x
	var estrecho := ancho < Estilo.ANCHO_ESTRECHO
	Estilo.fijar_margen(_margen, 14 if estrecho else 28)
	_columna.custom_minimum_size.x = clampf(ancho - 28.0, 300.0, 860.0) if estrecho else 860.0
	_logros.columns = 1 if estrecho else 2


func _mostrar_pagina(i: int) -> void:
	for j in _paginas.size():
		_paginas[j].visible = j == i


func _al_cambiar_monedas(_total: int) -> void:
	_llenar_tienda()
	_llenar_logros()


func _llenar_tienda() -> void:
	for h in _tienda.get_children():
		h.queue_free()
	var aviso := Estilo.rich("Usa tus monedas para conseguir ayudas en las rondas de preguntas. [color=%s]Los objetos se guardan hasta que los uses.[/color]" % Estilo.hex(Estilo.TINTA_SUAVE), 15)
	_tienda.add_child(aviso)
	for o in Premios.TIENDA:
		var tarjeta := PanelContainer.new()
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 16)
		tarjeta.add_child(fila)
		var icono := PanelContainer.new()
		icono.add_theme_stylebox_override("panel", Estilo.caja(Estilo.SUPERFICIE_2, 16, Vector2(12, 12)))
		icono.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		icono.add_child(Icono.crear(o.icono, 40))
		fila.add_child(icono)
		var textos := VBoxContainer.new()
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		textos.add_theme_constant_override("separation", 2)
		var nombre := HBoxContainer.new()
		nombre.add_theme_constant_override("separation", 8)
		nombre.add_child(Estilo.etiqueta(o.nombre, 18, Estilo.TINTA, 800, true))
		nombre.add_child(Estilo.chip("Tienes %d" % Juego.objetos(o.id), Estilo.COLOR_OK.darkened(0.15), Estilo.COLOR_OK_SUAVE, 12))
		textos.add_child(nombre)
		var descripcion := Estilo.etiqueta(o.descripcion, 14, Estilo.TINTA_SUAVE, 500)
		descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textos.add_child(descripcion)
		fila.add_child(textos)
		var comprar := Estilo.boton("        %d" % o.precio, Juego.comprar.bind(o.id), "Primario", 16)
		comprar.add_child(_icono_moneda())
		comprar.custom_minimum_size.x = 96
		comprar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		comprar.disabled = Juego.monedas() < o.precio
		comprar.tooltip_text = "Te faltan monedas" if comprar.disabled else "Comprar"
		fila.add_child(comprar)
		_tienda.add_child(tarjeta)
	Estilo.dejar_pasar_arrastre(_tienda)


func _icono_moneda() -> Icono:
	var i := Icono.crear("moneda", 20)
	i.position = Vector2(16, 12)
	return i


func _llenar_logros() -> void:
	for h in _logros.get_children():
		h.queue_free()
	for l in Premios.LOGROS:
		var obtenido := Juego.logro_obtenido(l.id)
		var tarjeta := PanelContainer.new()
		tarjeta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if not obtenido:
			tarjeta.add_theme_stylebox_override("panel", Estilo.caja(Estilo.SUPERFICIE_2, 20, Vector2(18, 14)))
		var fila := HBoxContainer.new()
		fila.add_theme_constant_override("separation", 14)
		tarjeta.add_child(fila)
		var fondo := PanelContainer.new()
		fondo.add_theme_stylebox_override("panel", Estilo.caja(Color("fff3d6") if obtenido else Color("e4e7ef"), 99, Vector2(10, 10)))
		fondo.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var icono := Icono.crear(l.icono, 34)
		icono.apagado = not obtenido
		fondo.add_child(icono)
		fila.add_child(fondo)
		var textos := VBoxContainer.new()
		textos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		textos.add_theme_constant_override("separation", 2)
		textos.add_child(Estilo.etiqueta(l.nombre, 16, Estilo.TINTA if obtenido else Estilo.TINTA_SUAVE, 800, true))
		var descripcion := Estilo.etiqueta(l.descripcion, 13, Estilo.TINTA_SUAVE, 500)
		descripcion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		textos.add_child(descripcion)
		var progreso := mini(Juego.estadistica(l.stat), l.meta)
		var estado := "✓ Obtenido · +%d monedas" % Premios.MONEDAS_LOGRO if obtenido else "%d / %d" % [progreso, l.meta]
		textos.add_child(Estilo.etiqueta(estado, 12, Estilo.COLOR_OK.darkened(0.15) if obtenido else Estilo.TINTA_SUAVE, 700))
		fila.add_child(textos)
		_logros.add_child(tarjeta)
	Estilo.dejar_pasar_arrastre(_logros)
