class_name Miniatura
extends Control
## Dibujo 2D de una configuración para la galería. Las que el jugador aún no
## encontró se muestran como «?», salvo que se pida revelarlas.

var modo := "torre"
var datos: Variant = []
var encontrada := true
var revelar := false
var numero := 0
var ladrillo := Vector2i(2, 4)
var tam := Vector2(104, 124)
var dorada := false               # la configuración bonus, ya encontrada

var _caja := StyleBoxFlat.new()


func _ready() -> void:
	custom_minimum_size = tam


func _rect_redondeado(r: Rect2, color: Color, radio: float, borde := Color.TRANSPARENT, grosor := 0) -> void:
	_caja.bg_color = color
	_caja.set_corner_radius_all(int(radio))
	_caja.border_color = borde
	_caja.set_border_width_all(grosor)
	draw_style_box(_caja, r)


func _draw() -> void:
	var marco := Rect2(Vector2.ZERO, size)
	if encontrada and dorada:
		_rect_redondeado(marco, Color("fff6dc"), 16, Estilo.COLOR_ESTRELLA, 3)
	elif encontrada:
		_rect_redondeado(marco, Estilo.SUPERFICIE, 16, Color(Estilo.COLOR_OK, 0.55), 2)
	else:
		_rect_redondeado(marco, Estilo.SUPERFICIE_2, 16)
	var fuente := Estilo.fuente(600)
	draw_string(fuente, Vector2(10, 20), "%d" % numero, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Estilo.TINTA_SUAVE)
	if encontrada:
		draw_circle(Vector2(size.x - 16, 15), 9, Estilo.COLOR_ESTRELLA if dorada else Estilo.COLOR_OK)
		draw_string(Estilo.fuente(800), Vector2(size.x - 22, 20), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	elif not revelar:
		draw_string(Estilo.fuente(800, true), Vector2(0, size.y / 2 + 14), "?", HORIZONTAL_ALIGNMENT_CENTER, size.x, 38, Color("c5cad8"))
		return
	var alfa := 1.0 if encontrada else 0.4
	match modo:
		"torre":
			_torre(alfa)
		"fila":
			_fila(alfa)
		"altura":
			_pila(alfa)
		"eilers":
			_eilers(alfa)


func _color(c: int, alfa: float) -> Color:
	var col: Color = Estilo.PALETA[c]
	col.a = alfa
	return col


## Ladrillo visto de frente: cuerpo redondeado y studs encima.
func _ladrillo(r: Rect2, col: Color, studs := 2) -> void:
	var ancho_stud := r.size.x / studs * 0.5
	for s in studs:
		var cx := r.position.x + r.size.x * (s + 0.5) / studs
		_rect_redondeado(Rect2(cx - ancho_stud / 2, r.position.y - 4, ancho_stud, 6), col.darkened(0.08), 2)
	_rect_redondeado(r, col, 4)
	_rect_redondeado(Rect2(r.position.x, r.end.y - minf(4.0, r.size.y * 0.3), r.size.x, minf(4.0, r.size.y * 0.3)), col.darkened(0.15), 2)


func _torre(alfa: float) -> void:
	var seq: Array = datos
	var alto := minf(19.0, (size.y - 44.0) / maxi(seq.size(), 1))
	var ancho := 44.0
	var x := (size.x - ancho) / 2
	var y := size.y - 14.0
	for c in seq:
		y -= alto
		_ladrillo(Rect2(x, y, ancho, alto - 1), _color(c, alfa))


func _fila(alfa: float) -> void:
	var seq: Array = datos
	var n := maxi(seq.size(), 1)
	var lado := minf(26.0, (size.x - 16.0) / n - 4.0)
	var x := (size.x - (n * (lado + 4.0) - 4.0)) / 2
	var y := size.y / 2 + 4
	for c in seq:
		_ladrillo(Rect2(x, y, lado, lado * 0.8), _color(c, alfa))
		x += lado + 4.0


func _pila(alfa: float) -> void:
	var seq: Array = datos
	var u := minf(7.0, (size.y - 44.0) / maxi(Enumerador.altura(seq), 1))
	var ancho := 44.0
	var x := (size.x - ancho) / 2
	var y := size.y - 14.0
	for t in seq:
		var alto: float = u * Enumerador.ALTO_PIEZA[t]
		y -= alto
		var col := Estilo.COLOR_PLACA if t == 0 else Estilo.COLOR_LADRILLO
		col.a = alfa
		_ladrillo(Rect2(x, y, ancho, alto - 1), col)


## Vista desde arriba: rojo = ladrillo de abajo, azul = el de arriba.
func _eilers(alfa: float) -> void:
	var p: Vector3i = datos
	var a := ladrillo.x
	var b := ladrillo.y
	var m := maxi(a, b)
	var x0 := 1 - m
	var y0 := 1 - m
	var ancho_rejilla := a + 2 * m - 2
	var alto_rejilla := b + 2 * m - 2
	var esc := minf((size.x - 16.0) / ancho_rejilla, (size.y - 34.0) / alto_rejilla)
	var origen := Vector2(
		(size.x - esc * ancho_rejilla) / 2 - x0 * esc,
		24.0 + (size.y - 30.0 - esc * alto_rejilla) / 2 - y0 * esc)
	var rojo := _color(0, alfa)
	var azul := _color(1, 0.85 * alfa)
	_rect_redondeado(Rect2(origen, Vector2(a, b) * esc), rojo, 3)
	var d := Enumerador.dims(p.z, a, b)
	_rect_redondeado(Rect2(origen + Vector2(p.x, p.y) * esc, Vector2(d.x, d.y) * esc), azul, 3)
	for i in d.x:
		for j in d.y:
			draw_circle(origen + Vector2(p.x + i + 0.5, p.y + j + 0.5) * esc, esc * 0.28, azul.lightened(0.3))
