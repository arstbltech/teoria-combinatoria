extends Control
## Pantalla de un nivel: constructor 3D, reto, teoría y comprobación de la fórmula.

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
	_construir_ui()
	_preparar_escena()
	_cargar_progreso()
	_actualizar()
	vista.saltar_camara()
	_calcular_lab()


# --- Construcción de la interfaz ---------------------------------------------

func _construir_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(Estilo.fondo())
	var margen := Estilo.margen(14)
	add_child(margen)
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 14)
	margen.add_child(fila)

	var izq := VBoxContainer.new()
	izq.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	izq.size_flags_stretch_ratio = 1.65
	izq.add_theme_constant_override("separation", 8)
	fila.add_child(izq)

	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 12)
	izq.add_child(cab)
	cab.add_child(Estilo.boton("← Menú", Juego.ir_a_menu))
	var titulo := Estilo.etiqueta("Nivel %d · %s" % [id + 1, datos.titulo], 24, Estilo.TINTA, true)
	titulo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	titulo.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	cab.add_child(titulo)
	cab.add_child(Estilo.etiqueta(datos.concepto, 16, Estilo.ACENTO, true))

	var marco := PanelContainer.new()
	marco.size_flags_vertical = Control.SIZE_EXPAND_FILL
	marco.add_theme_stylebox_override("panel", Estilo.caja(Estilo.COLOR_FONDO_3D, Estilo.BORDE, 6, 0, 2))
	izq.add_child(marco)
	var capa_vista := Control.new()
	capa_vista.clip_contents = true
	marco.add_child(capa_vista)
	var svc := SubViewportContainer.new()
	svc.stretch = true
	svc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	svc.gui_input.connect(_al_tocar_vista)
	capa_vista.add_child(svc)
	var sv := SubViewport.new()
	sv.own_world_3d = true
	sv.msaa_3d = Viewport.MSAA_4X
	svc.add_child(sv)
	vista = VistaLadrillos.new()
	sv.add_child(vista)
	var ayuda := Estilo.etiqueta("Arrastra para girar la vista · rueda para acercar", 13, Estilo.TINTA_SUAVE)
	ayuda.position = Vector2(12, 8)
	capa_vista.add_child(ayuda)
	lbl_anuncio = Estilo.etiqueta("", 36, Estilo.COLOR_OK, true)
	lbl_anuncio.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	lbl_anuncio.offset_top = 40
	lbl_anuncio.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_anuncio.add_theme_constant_override("outline_size", 10)
	lbl_anuncio.add_theme_color_override("font_outline_color", Color.WHITE)
	lbl_anuncio.modulate.a = 0.0
	capa_vista.add_child(lbl_anuncio)

	lbl_estado = Estilo.rich("", 17)
	izq.add_child(lbl_estado)
	var controles := HFlowContainer.new()
	controles.add_theme_constant_override("h_separation", 8)
	controles.add_theme_constant_override("v_separation", 8)
	izq.add_child(controles)
	_crear_controles(controles)
	lbl_mensaje = Estilo.etiqueta(" ", 17, Estilo.COLOR_AVISO, true)
	lbl_mensaje.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	izq.add_child(lbl_mensaje)

	var pestanas := TabContainer.new()
	pestanas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pestanas.custom_minimum_size = Vector2(400, 0)
	pestanas.get_tab_bar().focus_mode = Control.FOCUS_NONE
	fila.add_child(pestanas)
	pestanas.add_child(_pestana_reto())
	pestanas.add_child(_envolver_scroll(Estilo.rich(datos.teoria, 16)))
	pestanas.add_child(_pestana_comprobar())
	pestanas.set_tab_title(0, "Reto")
	pestanas.set_tab_title(1, "Teoría")
	pestanas.set_tab_title(2, "Comprobar")

	_crear_galeria()


func _envolver_scroll(contenido: Control) -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.focus_mode = Control.FOCUS_NONE
	contenido.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(contenido)
	return scroll


func _pestana_reto() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.add_child(Estilo.rich(datos.enunciado, 18))
	lbl_contador = Estilo.etiqueta("", 22, Estilo.TINTA, true)
	lbl_contador.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(lbl_contador)
	barra = ProgressBar.new()
	barra.show_percentage = false
	barra.custom_minimum_size = Vector2(0, 16)
	barra.max_value = total
	v.add_child(barra)

	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", Estilo.caja(Estilo.CREMA, Color("eed58a"), 12, 12, 2))
	var calculo := Niveles.calcular(datos.lab, datos.params)
	tarjeta.add_child(Estilo.rich("[b]¿Por qué %s?[/b]\n%s\n[color=%s]La demostración está en la pestaña Teoría.[/color]" % [
		Combinatoria.fmt(total), calculo.formula, Estilo.hex(Estilo.TINTA_SUAVE)], 17))
	v.add_child(tarjeta)

	var botones := HFlowContainer.new()
	botones.add_theme_constant_override("h_separation", 8)
	botones.add_theme_constant_override("v_separation", 8)
	botones.add_child(Estilo.boton("Ver galería", _abrir_galeria))
	var preguntas := Estilo.boton("Preguntas del nivel →", _ir_a_preguntas)
	Estilo.pintar_boton(preguntas, Estilo.PALETA[2])
	botones.add_child(preguntas)
	botones.add_child(Estilo.boton("Reiniciar reto", _reiniciar))
	v.add_child(botones)
	v.add_child(Estilo.rich("[color=%s]%s[/color]" % [Estilo.hex(Estilo.TINTA_SUAVE), _texto_atajos()], 15))
	return _envolver_scroll(v)


func _texto_atajos() -> String:
	match modo:
		"altura":
			return "Teclas: 1 = placa · 2 = ladrillo · Retroceso quita la última pieza."
		"eilers":
			return "Teclas: flechas o WASD mueven el ladrillo azul · R lo gira · G muestra su gemela girada · Enter registra."
	return "Teclas: 1 a %d ponen una pieza · Retroceso quita la última." % reglas.k


func _pestana_comprobar() -> Control:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 12)
	v.add_child(Estilo.rich("Cambia los parámetros y compara la [b]fórmula[/b] con una [b]enumeración por fuerza bruta[/b]: la computadora genera todas las configuraciones, aplica la definición y cuenta las distintas.", 16))
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 8)
	var specs: Array = Niveles.LAB[datos.lab]
	for i in specs.size():
		var spec: Array = specs[i]
		var nombre := Estilo.etiqueta(spec[0], 17)
		nombre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(nombre)
		var paso := HBoxContainer.new()
		paso.add_child(Estilo.boton("−", _cambiar_parametro.bind(i, -1), 20))
		var valor := Estilo.etiqueta(str(datos.params[i]), 20, Estilo.TINTA, true)
		valor.custom_minimum_size = Vector2(44, 0)
		valor.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		paso.add_child(valor)
		paso.add_child(Estilo.boton("+", _cambiar_parametro.bind(i, 1), 20))
		grid.add_child(paso)
		valores_lab.append(int(datos.params[i]))
		etiquetas_lab.append(valor)
	v.add_child(grid)
	var tarjeta := PanelContainer.new()
	tarjeta.add_theme_stylebox_override("panel", Estilo.caja(Estilo.CREMA, Color("eed58a"), 12, 12, 2))
	lab_res = Estilo.rich("", 17)
	tarjeta.add_child(lab_res)
	v.add_child(tarjeta)
	v.add_child(Estilo.rich("[color=%s][b]Cómo se enumera:[/b] %s[/color]" % [Estilo.hex(Estilo.TINTA_SUAVE), Niveles.METODO[datos.lab]], 15))
	return _envolver_scroll(v)


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
			var placa := Estilo.boton("+ Placa (altura 1)", _agregar.bind(0))
			Estilo.pintar_boton(placa, Estilo.COLOR_PLACA)
			caja.add_child(placa)
			var alto := Estilo.boton("+ Ladrillo (altura 3)", _agregar.bind(1))
			Estilo.pintar_boton(alto, Estilo.COLOR_LADRILLO)
			caja.add_child(alto)
		"eilers":
			for flecha in [["←", Vector2i(-1, 0)], ["→", Vector2i(1, 0)], ["↑", Vector2i(0, -1)], ["↓", Vector2i(0, 1)]]:
				caja.add_child(Estilo.boton(flecha[0], _mover.bind(flecha[1]), 22))
			caja.add_child(Estilo.boton("↻ Girar (R)", _girar))
			btn_gemela = Estilo.boton("Ver gemela ρ (G)", _alternar_gemela)
			btn_gemela.toggle_mode = true
			caja.add_child(btn_gemela)
			var registrar := Estilo.boton("✓ Registrar (Enter)", _registrar)
			Estilo.pintar_boton(registrar, Estilo.COLOR_OK)
			caja.add_child(registrar)
			return
	caja.add_child(Estilo.boton("Quitar la última", _quitar))
	caja.add_child(Estilo.boton("Vaciar", _vaciar))


func _crear_galeria() -> void:
	var modal := Estilo.capa_modal(self)
	capa_galeria = modal[0]
	var v: VBoxContainer = modal[1]
	var cab := HBoxContainer.new()
	cab.add_theme_constant_override("separation", 10)
	lbl_galeria = Estilo.etiqueta("", 24, Estilo.TINTA, true)
	lbl_galeria.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cab.add_child(lbl_galeria)
	var rev := Estilo.boton("Revelar todas", _alternar_revelar)
	rev.toggle_mode = true
	cab.add_child(rev)
	cab.add_child(Estilo.boton("Cerrar ✕", _cerrar_galeria))
	v.add_child(cab)
	var explicacion := "El enumerador generó [b]todas[/b] las configuraciones aplicando la definición del reto, no la fórmula. Las que ya encontraste tienen ✓."
	if modo == "eilers":
		explicacion += " Cada casilla es una construcción distinta (una órbita) vista desde arriba: rojo = ladrillo de abajo, azul = el de arriba."
	v.add_child(Estilo.rich("[color=%s]%s[/color]" % [Estilo.hex(Estilo.TINTA_SUAVE), explicacion], 15))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	grid_galeria = GridContainer.new()
	grid_galeria.columns = 9
	grid_galeria.add_theme_constant_override("h_separation", 10)
	grid_galeria.add_theme_constant_override("v_separation", 10)
	scroll.add_child(grid_galeria)


func _preparar_escena() -> void:
	match modo:
		"torre", "altura":
			vista.preparar_base(Vector2i(-5, -5), Vector2i(12, 12))
		"fila":
			vista.preparar_base(Vector2i(-3, -4), Vector2i(reglas.n * 3 + 4, 10))
		"eilers":
			vista.preparar_base(Vector2i(-6, -5), Vector2i(14, 14))


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
	_mensaje(" ", Estilo.COLOR_AVISO)
	_actualizar(true)
	if _esta_completa():
		_registrar()


func _quitar() -> void:
	if seq.is_empty():
		return
	seq.pop_back()
	_mensaje(" ", Estilo.COLOR_AVISO)
	_actualizar()


func _vaciar() -> void:
	seq.clear()
	_mensaje(" ", Estilo.COLOR_AVISO)
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
	var completo_ahora := orden.size() >= objetivo and not Juego.reto_completado(id)
	if completo_ahora:
		Juego.marcar_reto(id)
	var texto := "¡Nueva! Llevas %d de %d." % [orden.size(), total]
	if orden.size() == total:
		texto = "¡Las encontraste todas: exactamente %d, como predice la fórmula! Sigue con las preguntas del nivel." % total
		_anunciar("¡%d de %d! ★" % [total, total])
	elif completo_ahora:
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
	_mensaje(" ", Estilo.COLOR_AVISO)
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
	_mensaje(" ", Estilo.COLOR_AVISO)
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
	Juego.ir_a_quiz(datos.temas, 3, id, "Nivel %d · %s" % [id + 1, datos.titulo])


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
			piezas.append({"pos": Vector3(0, meta, 0), "tam": Vector2i(2, 2), "alto": 0.05, "color": Estilo.COLOR_OK, "fantasma": true, "studs": false, "margen": 0.45})
			vista.enfocar(Vector3(1, meta * 0.5, 1), 8.0 + meta * 1.2)
		"eilers":
			var a := ladrillo.x
			var b := ladrillo.y
			piezas.append({"pos": Vector3.ZERO, "tam": Vector2i(a, b), "alto": alto_ladrillo, "color": Estilo.PALETA[0]})
			piezas.append({"pos": Vector3(pos.x, alto_ladrillo, pos.y), "tam": Enumerador.dims(pos.z, a, b), "alto": alto_ladrillo, "color": Estilo.PALETA[1]})
			if ver_gemela:
				var g := Enumerador.girar_180(pos, a, b)
				piezas.append({"pos": Vector3(g.x, alto_ladrillo, g.y), "tam": Enumerador.dims(g.z, a, b), "alto": alto_ladrillo, "color": Estilo.PALETA[2], "fantasma": true, "margen": 0.03})
			vista.enfocar(Vector3(a / 2.0, alto_ladrillo, b / 2.0), 15.0)
	vista.mostrar(piezas, animada if animar else -1)
	_actualizar_textos()


func _actualizar_textos() -> void:
	lbl_contador.text = "Encontradas: %d de %d" % [orden.size(), total]
	if objetivo < total:
		lbl_contador.text += "\nObjetivo: al menos %d" % objetivo
	barra.value = orden.size()
	lbl_estado.text = _describir_estado()
	var inventario: Array = reglas.get("inventario", [])
	for c in botones_pieza.size():
		var texto: String = "+ " + Estilo.NOMBRES[c].capitalize()
		if not inventario.is_empty():
			texto += " (quedan %d)" % (int(inventario[c]) - seq.count(c))
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
			return "[b]Torre[/b] (de abajo arriba): %s   [color=%s](%d de %d)[/color]" % [", ".join(partes), suave, seq.size(), reglas.n]
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
				return "[b]Bolsa:[/b] %s   [color=%s](%d de %d)[/color]\nEstrellas y barras: [b]%s[/b]" % [contenido, suave, seq.size(), reglas.n, "|".join(estrellas)]
			var partes := PackedStringArray()
			for c in ordenada:
				partes.append(_cuadro(c))
			return "[b]Selección:[/b] {%s}   [color=%s](%d de %d)[/color]" % [", ".join(partes), suave, seq.size(), reglas.n]
		"altura":
			var nombres := PackedStringArray()
			for t in seq:
				nombres.append("placa" if t == 0 else "ladrillo")
			var detalle := ("  (" + " + ".join(nombres) + ")") if not nombres.is_empty() else ""
			return "[b]Altura:[/b] %d de %d%s" % [Enumerador.altura(seq), datos.altura, detalle]
		"eilers":
			var g := Enumerador.girar_180(pos, ladrillo.x, ladrillo.y)
			var texto := "[b]Ladrillo azul:[/b] x = %s, y = %s, %s." % [Combinatoria.fmt(pos.x), Combinatoria.fmt(pos.y), "paralelo" if pos.z == 0 else "perpendicular"]
			if g == pos:
				texto += "  [color=%s]El giro ρ la deja igual: es un punto fijo.[/color]" % Estilo.hex(Estilo.COLOR_OK)
			else:
				texto += "  Su gemela ρ(p): x = %s, y = %s." % [Combinatoria.fmt(g.x), Combinatoria.fmt(g.y)]
			return texto
	return ""


func _mensaje(texto: String, color: Color) -> void:
	lbl_mensaje.text = texto
	lbl_mensaje.add_theme_color_override("font_color", color)


func _anunciar(texto: String) -> void:
	lbl_anuncio.text = texto
	lbl_anuncio.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(1.4)
	tw.tween_property(lbl_anuncio, "modulate:a", 0.0, 0.6)


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
		grid_galeria.add_child(mini)
	lbl_galeria.text = "Galería: %d de %d encontradas" % [orden.size(), todas.size()]
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
	var movimiento := event as InputEventMouseMotion
	if movimiento and movimiento.button_mask & (MOUSE_BUTTON_MASK_LEFT | MOUSE_BUTTON_MASK_RIGHT):
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
