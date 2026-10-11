extends Node
## Autoload «Juego»: progreso guardado, economía (monedas, objetos, logros),
## avisos emergentes y navegación entre pantallas.

signal monedas_cambiaron(total: int)

const DESAFIO := 99  # identificador del desafío final en el archivo de progreso

var nivel_actual := 0
var quiz := {"temas": [], "cantidad": 5, "nivel": -1, "titulo": ""}

var _ruta := "user://progreso.cfg"
var _cfg := ConfigFile.new()
var _avisos: VBoxContainer
var _revisando_logros := false


func _ready() -> void:
	var prueba := false
	for a in OS.get_cmdline_user_args():
		if a == "--prueba-humo" or a.begins_with("--capturas"):
			prueba = true
	if prueba:
		# Las pruebas no tocan el progreso real del jugador.
		_ruta = "user://progreso_prueba.cfg"
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_ruta))
	_cfg.load(_ruta)
	get_tree().root.theme = Estilo.crear_tema()
	get_tree().root.size_changed.connect(_ajustar_escala)
	_ajustar_escala()
	_crear_capa_avisos()
	if prueba:
		add_child(load("res://tests/humo.gd").new())


## Elige el tamaño base de la interfaz según la pantalla. En horizontal se
## diseña sobre 1280×720 (o algo menor en pantallas bajas); en un celular en
## vertical se usa su ancho real en píxeles independientes de la densidad, así
## el texto queda de un tamaño cómodo y las pantallas pasan a una columna.
func _ajustar_escala() -> void:
	var ventana := get_tree().root
	var tam := Vector2(ventana.size)
	if tam.x <= 0 or tam.y <= 0:
		return
	var escala := maxf(DisplayServer.screen_get_scale(), 1.0)
	if OS.has_feature("mobile"):
		# En Android la escala puede venir en 1; la densidad (160 ppp = 1×) es más fiable.
		escala = maxf(escala, DisplayServer.screen_get_dpi() / 160.0)
	var css := tam / escala
	var base: Vector2
	if css.x >= css.y:
		var alto := clampf(css.y, 480.0, 720.0)
		base = Vector2(alto * 16.0 / 9.0, alto)
	else:
		var ancho := clampf(css.x, 360.0, 600.0)
		base = Vector2(ancho, ancho * tam.y / tam.x)
	ventana.content_scale_size = Vector2i(base.round())


# --- Progreso de los niveles -----------------------------------------------------

func encontradas(nivel: int) -> Array:
	return _cfg.get_value(_seccion(nivel), "encontradas", [])


func guardar_encontradas(nivel: int, claves: Array) -> void:
	_cfg.set_value(_seccion(nivel), "encontradas", claves.duplicate())
	_guardar()


## true la primera vez que se registra esa configuración en ese nivel (paga monedas);
## false si ya se había pagado antes (por ejemplo, tras reiniciar el reto).
func pagar_configuracion(nivel: int, clave: String) -> bool:
	var pagadas: Array = _cfg.get_value(_seccion(nivel), "pagadas", [])
	if clave in pagadas:
		return false
	pagadas.append(clave)
	_cfg.set_value(_seccion(nivel), "pagadas", pagadas)
	_guardar()
	return true


## Marca la galería del nivel como completa; true sólo la primera vez.
func completar_galeria(nivel: int) -> bool:
	if _cfg.get_value(_seccion(nivel), "galeria_completa", false):
		return false
	_cfg.set_value(_seccion(nivel), "galeria_completa", true)
	_guardar()
	return true


func reto_completado(nivel: int) -> bool:
	return _cfg.get_value(_seccion(nivel), "reto", false)


func marcar_reto(nivel: int) -> void:
	_cfg.set_value(_seccion(nivel), "reto", true)
	_guardar()
	sumar_estadistica("retos")
	_revisar_cofres()


## Mejor resultado de preguntas: (aciertos, total).
func mejor_quiz(nivel: int) -> Vector2i:
	return Vector2i(
		_cfg.get_value(_seccion(nivel), "quiz_aciertos", 0),
		_cfg.get_value(_seccion(nivel), "quiz_total", 0))


func registrar_quiz(nivel: int, aciertos: int, total: int) -> void:
	var previo := mejor_quiz(nivel)
	if previo.y == 0 or aciertos * previo.y > previo.x * total:
		_cfg.set_value(_seccion(nivel), "quiz_aciertos", aciertos)
		_cfg.set_value(_seccion(nivel), "quiz_total", total)
		_guardar()
	revisar_logros()


## Nivel: ★ reto completado, ★ al menos 2/3 de las preguntas, ★ todas bien.
## Desafío final: ★ vencerlo, ★ con a lo más un error, ★ sin errores.
func estrellas(nivel: int) -> int:
	var q := mejor_quiz(nivel)
	if nivel == DESAFIO:
		if q.y == 0:
			return 0
		return 1 + int(q.y - q.x <= 1) + int(q.x == q.y)
	var e := int(reto_completado(nivel))
	if q.y > 0:
		e += int(q.x * 3 >= q.y * 2) + int(q.x == q.y)
	return e


func estrellas_totales() -> int:
	var total := estrellas(DESAFIO)
	for i in Niveles.cantidad():
		total += estrellas(i)
	return total


func mundo_desbloqueado(m: int) -> bool:
	return estrellas_totales() >= Mundos.obtener(m).requiere


func nivel_desbloqueado(nivel: int) -> bool:
	return mundo_desbloqueado(Mundos.de_nivel(nivel))


func desafio_desbloqueado() -> bool:
	return mundo_desbloqueado(Mundos.cantidad() - 1)


func historia_vista() -> bool:
	return _cfg.get_value("jugador", "historia_vista", false)


func marcar_historia_vista() -> void:
	_cfg.set_value("jugador", "historia_vista", true)
	_guardar()


# --- Economía ------------------------------------------------------------------

func monedas() -> int:
	return _cfg.get_value("jugador", "monedas", 0)


func sumar_monedas(n: int) -> void:
	if n <= 0:
		return
	_cfg.set_value("jugador", "monedas", monedas() + n)
	_cfg.set_value("estadisticas", "monedas_ganadas", estadistica("monedas_ganadas") + n)
	_guardar()
	monedas_cambiaron.emit(monedas())
	revisar_logros()


func gastar_monedas(n: int) -> bool:
	if monedas() < n:
		return false
	_cfg.set_value("jugador", "monedas", monedas() - n)
	_guardar()
	monedas_cambiaron.emit(monedas())
	return true


func objetos(id: String) -> int:
	return _cfg.get_value("objetos", id, 0)


func dar_objeto(id: String, n := 1) -> void:
	_cfg.set_value("objetos", id, objetos(id) + n)
	_guardar()


## Gasta un objeto del inventario; false si no quedaba ninguno.
func usar_objeto(id: String) -> bool:
	if objetos(id) <= 0:
		return false
	_cfg.set_value("objetos", id, objetos(id) - 1)
	_guardar()
	return true


func comprar(id: String) -> bool:
	var o := Premios.objeto(id)
	if o.is_empty() or not gastar_monedas(o.precio):
		return false
	dar_objeto(id)
	notificar("Compraste: %s" % o.nombre, o.icono)
	return true


func estadistica(nombre: String) -> int:
	match nombre:
		"estrellas":
			return estrellas_totales()
		"mundos":
			var n := 0
			for m in Mundos.cantidad():
				n += int(mundo_desbloqueado(m))
			return n
	return _cfg.get_value("estadisticas", nombre, 0)


func sumar_estadistica(nombre: String, n := 1) -> void:
	_cfg.set_value("estadisticas", nombre, estadistica(nombre) + n)
	_guardar()
	revisar_logros()


func maximo_estadistica(nombre: String, valor: int) -> void:
	if valor > estadistica(nombre):
		_cfg.set_value("estadisticas", nombre, valor)
		_guardar()
		revisar_logros()


func logro_obtenido(id: String) -> bool:
	return _cfg.get_value("logros", id, false)


## Desbloquea los logros cuya meta ya se alcanzó; cada uno da monedas de premio.
func revisar_logros() -> void:
	if _revisando_logros:
		return
	_revisando_logros = true
	var hubo_nuevo := true
	while hubo_nuevo:
		hubo_nuevo = false
		for l in Premios.LOGROS:
			if not logro_obtenido(l.id) and estadistica(l.stat) >= l.meta:
				_cfg.set_value("logros", l.id, true)
				_guardar()
				notificar("¡Logro desbloqueado! %s  +%d" % [l.nombre, Premios.MONEDAS_LOGRO], "trofeo", Estilo.COLOR_ESTRELLA)
				_cfg.set_value("jugador", "monedas", monedas() + Premios.MONEDAS_LOGRO)
				_cfg.set_value("estadisticas", "monedas_ganadas", estadistica("monedas_ganadas") + Premios.MONEDAS_LOGRO)
				_guardar()
				monedas_cambiaron.emit(monedas())
				hubo_nuevo = true
	var mundos_abiertos := estadistica("mundos")
	if mundos_abiertos > _cfg.get_value("jugador", "mundos_avisados", 1):
		_cfg.set_value("jugador", "mundos_avisados", mundos_abiertos)
		_guardar()
		notificar("¡Nuevo mundo desbloqueado: %s!" % Mundos.obtener(mundos_abiertos - 1).nombre, "cohete", Estilo.ACENTO)
	_revisando_logros = false


## Al completar todos los retos de un mundo se abre su cofre (una sola vez).
func _revisar_cofres() -> void:
	for m in Mundos.cantidad():
		var mundo := Mundos.obtener(m)
		if _cfg.get_value("cofres", str(m), false):
			continue
		var completo := true
		for n in mundo.niveles:
			completo = completo and reto_completado(n)
		if completo:
			_cfg.set_value("cofres", str(m), true)
			_guardar()
			notificar("¡Cofre de %s! +%d monedas" % [mundo.nombre, Premios.MONEDAS_COFRE], "cofre", Estilo.COLOR_ESTRELLA)
			sumar_estadistica("cofres")
			sumar_monedas(Premios.MONEDAS_COFRE)


func borrar_progreso() -> void:
	_cfg = ConfigFile.new()
	_guardar()
	monedas_cambiaron.emit(0)


func _seccion(nivel: int) -> String:
	return "nivel_%d" % nivel


func _guardar() -> void:
	_cfg.save(_ruta)


# --- Avisos emergentes -----------------------------------------------------------

func _crear_capa_avisos() -> void:
	var capa := CanvasLayer.new()
	capa.layer = 20
	add_child(capa)
	var raiz := Control.new()
	raiz.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	raiz.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.theme = get_tree().root.theme  # el tema no atraviesa el CanvasLayer
	capa.add_child(raiz)
	_avisos = VBoxContainer.new()
	_avisos.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_avisos.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_avisos.offset_top = 14
	_avisos.alignment = BoxContainer.ALIGNMENT_BEGIN
	_avisos.add_theme_constant_override("separation", 8)
	_avisos.mouse_filter = Control.MOUSE_FILTER_IGNORE
	raiz.add_child(_avisos)


## Muestra un aviso arriba de la pantalla durante unos segundos.
func notificar(texto: String, icono := "", color := Estilo.TINTA) -> void:
	if _avisos == null:
		return
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	panel.add_theme_stylebox_override("panel", Estilo.caja(Estilo.SUPERFICIE, 99, Vector2(16, 9), 18, Estilo.BORDE, 1))
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 8)
	fila.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(fila)
	if icono != "":
		fila.add_child(Icono.crear(icono, 20))
	var etiqueta := Estilo.etiqueta(texto, 15, color, 700)
	fila.add_child(etiqueta)
	_avisos.add_child(panel)
	while _avisos.get_child_count() > 3:
		_avisos.get_child(0).free()
	panel.modulate.a = 0.0
	var tw := panel.create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.25)
	tw.tween_interval(2.4)
	tw.tween_property(panel, "modulate:a", 0.0, 0.4)
	tw.tween_callback(panel.queue_free)


## Pastilla con las monedas del jugador; se actualiza (y late) cuando cambian.
func pastilla_monedas(tam := 15) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Estilo.caja(Estilo.SUPERFICIE, 99, Vector2(12, 5), 8, Estilo.BORDE, 1))
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var fila := HBoxContainer.new()
	fila.add_theme_constant_override("separation", 6)
	p.add_child(fila)
	fila.add_child(Icono.crear("moneda", 18))
	var l := Estilo.etiqueta(str(monedas()), tam, Estilo.TINTA, 800)
	fila.add_child(l)
	var actualizar := func(total: int) -> void:
		l.text = str(total)
		p.pivot_offset = p.size / 2
		var tw := p.create_tween()
		tw.tween_property(p, "scale", Vector2(1.15, 1.15), 0.08)
		tw.tween_property(p, "scale", Vector2.ONE, 0.18)
	monedas_cambiaron.connect(actualizar)
	p.tree_exiting.connect(func() -> void: monedas_cambiaron.disconnect(actualizar))
	return p


# --- Navegación ------------------------------------------------------------------

func ir_a_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func ir_a_nivel(i: int) -> void:
	nivel_actual = i
	get_tree().change_scene_to_file("res://scenes/nivel.tscn")


func ir_a_quiz(temas: Array, cantidad: int, nivel: int, titulo: String) -> void:
	quiz = {"temas": temas, "cantidad": cantidad, "nivel": nivel, "titulo": titulo}
	get_tree().change_scene_to_file("res://scenes/quiz.tscn")


func ir_a_premios() -> void:
	get_tree().change_scene_to_file("res://scenes/premios.tscn")
