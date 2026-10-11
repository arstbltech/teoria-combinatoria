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


func _ready() -> void:
	custom_minimum_size = Vector2(112, 132)


func _draw() -> void:
	var marco := Rect2(Vector2.ZERO, size)
	draw_rect(marco, Color.WHITE if encontrada else Color("f4efe4"))
	draw_rect(marco, Estilo.COLOR_OK if encontrada else Estilo.BORDE, false, 2.0 if encontrada else 1.0)
	var fuente := get_theme_default_font()
	draw_string(fuente, Vector2(6, 17), "#%d" % numero, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Estilo.TINTA_SUAVE)
	if encontrada:
		draw_string(fuente, Vector2(size.x - 22, 18), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Estilo.COLOR_OK)
	elif not revelar:
		draw_string(fuente, Vector2(0, size.y / 2 + 16), "?", HORIZONTAL_ALIGNMENT_CENTER, size.x, 42, Color("d6ccb6"))
		return
	var alfa := 1.0 if encontrada else 0.45
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


## Ladrillo visto de frente: cuerpo y studs encima.
func _ladrillo(r: Rect2, col: Color, studs := 2) -> void:
	var ancho_stud := r.size.x / studs * 0.5
	for s in studs:
		var cx := r.position.x + r.size.x * (s + 0.5) / studs
		draw_rect(Rect2(cx - ancho_stud / 2, r.position.y - 4, ancho_stud, 4), col)
	draw_rect(r, col)
	draw_rect(r, col.darkened(0.35), false, 1.0)


func _torre(alfa: float) -> void:
	var seq: Array = datos
	var alto := minf(20.0, (size.y - 44.0) / maxi(seq.size(), 1))
	var ancho := 46.0
	var x := (size.x - ancho) / 2
	var y := size.y - 12.0
	for c in seq:
		y -= alto
		_ladrillo(Rect2(x, y, ancho, alto), _color(c, alfa))


func _fila(alfa: float) -> void:
	var seq: Array = datos
	var n := maxi(seq.size(), 1)
	var lado := minf(28.0, (size.x - 16.0) / n - 4.0)
	var x := (size.x - (n * (lado + 4.0) - 4.0)) / 2
	var y := size.y / 2 + 4
	for c in seq:
		_ladrillo(Rect2(x, y, lado, lado * 0.8), _color(c, alfa))
		x += lado + 4.0


func _pila(alfa: float) -> void:
	var seq: Array = datos
	var u := minf(7.0, (size.y - 44.0) / maxi(Enumerador.altura(seq), 1))
	var ancho := 46.0
	var x := (size.x - ancho) / 2
	var y := size.y - 12.0
	for t in seq:
		var alto: float = u * Enumerador.ALTO_PIEZA[t]
		y -= alto
		var col := Estilo.COLOR_PLACA if t == 0 else Estilo.COLOR_LADRILLO
		col.a = alfa
		_ladrillo(Rect2(x, y, ancho, alto), col)


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
	var azul := _color(1, 0.8 * alfa)
	var abajo := Rect2(origen, Vector2(a, b) * esc)
	draw_rect(abajo, rojo)
	draw_rect(abajo, rojo.darkened(0.35), false, 1.0)
	var d := Enumerador.dims(p.z, a, b)
	var arriba := Rect2(origen + Vector2(p.x, p.y) * esc, Vector2(d.x, d.y) * esc)
	draw_rect(arriba, azul)
	draw_rect(arriba, azul.darkened(0.4), false, 1.5)
	for i in d.x:
		for j in d.y:
			draw_circle(origen + Vector2(p.x + i + 0.5, p.y + j + 0.5) * esc, esc * 0.28, azul.lightened(0.3))
