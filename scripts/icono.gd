class_name Icono
extends Control
## Íconos vectoriales dibujados en código (moneda, corazón, estrella, trofeo…),
## nítidos a cualquier tamaño y sin depender de fuentes con emojis.

var tipo := "moneda"
var apagado := false:
	set(valor):
		apagado = valor
		queue_redraw()


static func crear(tipo_: String, lado := 20.0) -> Icono:
	var i := Icono.new()
	i.tipo = tipo_
	i.custom_minimum_size = Vector2(lado, lado)
	i.mouse_filter = Control.MOUSE_FILTER_IGNORE
	i.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return i


func _color(c: Color) -> Color:
	if not apagado:
		return c
	var g := c.get_luminance() * 0.5 + 0.45
	return Color(g, g, g * 1.03)


func _draw() -> void:
	var s := minf(size.x, size.y)
	var o := (size - Vector2(s, s)) / 2
	var c := o + Vector2(s, s) / 2
	match tipo:
		"moneda":
			draw_circle(c, s * 0.5, _color(Color("e09a00")))
			draw_circle(c, s * 0.42, _color(Color("ffc531")))
			draw_arc(c, s * 0.28, 0, TAU, 24, _color(Color("e8a400")), maxf(1.0, s * 0.06))
			draw_colored_polygon(Icono._estrella(c, s * 0.17, s * 0.08), _color(Color("e8a400")))
			draw_circle(c + Vector2(-s * 0.2, -s * 0.2), s * 0.07, Color(1, 1, 1, 0.6 if not apagado else 0.3))
		"corazon":
			var rojo := _color(Color("ef4136"))
			draw_circle(o + Vector2(s * 0.3, s * 0.36), s * 0.24, rojo)
			draw_circle(o + Vector2(s * 0.7, s * 0.36), s * 0.24, rojo)
			draw_colored_polygon(PackedVector2Array([
				o + Vector2(s * 0.08, s * 0.44), o + Vector2(s * 0.92, s * 0.44), o + Vector2(s * 0.5, s * 0.92)]), rojo)
			draw_circle(o + Vector2(s * 0.27, s * 0.3), s * 0.07, Color(1, 1, 1, 0.55 if not apagado else 0.3))
		"estrella":
			draw_colored_polygon(_estrella(c, s * 0.5, s * 0.22), _color(Color("f5a524")))
		"trofeo":
			var oro := _color(Color("f5b300"))
			draw_colored_polygon(PackedVector2Array([
				o + Vector2(s * 0.22, s * 0.1), o + Vector2(s * 0.78, s * 0.1),
				o + Vector2(s * 0.7, s * 0.45), o + Vector2(s * 0.5, s * 0.58), o + Vector2(s * 0.3, s * 0.45)]), oro)
			draw_arc(o + Vector2(s * 0.2, s * 0.27), s * 0.13, PI * 0.5, PI * 1.5, 12, oro, s * 0.07)
			draw_arc(o + Vector2(s * 0.8, s * 0.27), s * 0.13, -PI * 0.5, PI * 0.5, 12, oro, s * 0.07)
			draw_rect(Rect2(o + Vector2(s * 0.44, s * 0.56), Vector2(s * 0.12, s * 0.18)), oro)
			draw_rect(Rect2(o + Vector2(s * 0.28, s * 0.74), Vector2(s * 0.44, s * 0.14)), _color(Color("d48c00")))
		"rayo":
			draw_colored_polygon(PackedVector2Array([
				o + Vector2(s * 0.58, s * 0.04), o + Vector2(s * 0.2, s * 0.56), o + Vector2(s * 0.46, s * 0.56),
				o + Vector2(s * 0.38, s * 0.96), o + Vector2(s * 0.8, s * 0.4), o + Vector2(s * 0.54, s * 0.4)]), _color(Color("ffc531")))
		"ladrillo":
			var azul := _color(Color("1f6feb"))
			draw_rect(Rect2(o + Vector2(s * 0.22, s * 0.2), Vector2(s * 0.18, s * 0.16)), azul)
			draw_rect(Rect2(o + Vector2(s * 0.6, s * 0.2), Vector2(s * 0.18, s * 0.16)), azul)
			draw_rect(Rect2(o + Vector2(s * 0.08, s * 0.34), Vector2(s * 0.84, s * 0.5)), azul)
			draw_rect(Rect2(o + Vector2(s * 0.08, s * 0.72), Vector2(s * 0.84, s * 0.12)), _color(Color("1857c0")))
		"candado":
			var gris := Color("8a90a6")
			draw_arc(c + Vector2(0, -s * 0.06), s * 0.22, PI, TAU, 16, gris, s * 0.09)
			draw_rect(Rect2(o + Vector2(s * 0.18, s * 0.42), Vector2(s * 0.64, s * 0.5)), gris)
			draw_circle(c + Vector2(0, s * 0.18), s * 0.07, Color.WHITE)
		"cofre":
			draw_rect(Rect2(o + Vector2(s * 0.08, s * 0.4), Vector2(s * 0.84, s * 0.5)), _color(Color("b5651d")))
			draw_rect(Rect2(o + Vector2(s * 0.08, s * 0.18), Vector2(s * 0.84, s * 0.26)), _color(Color("d07a2a")))
			draw_rect(Rect2(o + Vector2(s * 0.08, s * 0.4), Vector2(s * 0.84, s * 0.07)), _color(Color("f5b300")))
			draw_rect(Rect2(o + Vector2(s * 0.42, s * 0.36), Vector2(s * 0.16, s * 0.18)), _color(Color("f5b300")))
		"pista":
			draw_circle(c + Vector2(0, -s * 0.1), s * 0.3, _color(Color("ffc531")))
			draw_rect(Rect2(o + Vector2(s * 0.38, s * 0.62), Vector2(s * 0.24, s * 0.2)), _color(Color("8a90a6")))
			draw_rect(Rect2(o + Vector2(s * 0.42, s * 0.84), Vector2(s * 0.16, s * 0.08)), _color(Color("6b7186")))
		"comodin":
			draw_circle(c, s * 0.5, _color(Color("5b55f0")))
			draw_string(Estilo.fuente(900), o + Vector2(0, s * 0.64), "½", HORIZONTAL_ALIGNMENT_CENTER, s, int(s * 0.6), Color.WHITE)
		"cohete":
			var blanco := _color(Color("f2f4fb"))
			draw_colored_polygon(PackedVector2Array([o + Vector2(s * 0.5, s * 0.04), o + Vector2(s * 0.68, s * 0.3), o + Vector2(s * 0.32, s * 0.3)]), _color(Color("ef4136")))
			draw_rect(Rect2(o + Vector2(s * 0.32, s * 0.3), Vector2(s * 0.36, s * 0.46)), blanco)
			draw_circle(c + Vector2(0, -s * 0.04), s * 0.08, _color(Color("1f6feb")))
			draw_colored_polygon(PackedVector2Array([o + Vector2(s * 0.32, s * 0.56), o + Vector2(s * 0.14, s * 0.8), o + Vector2(s * 0.32, s * 0.76)]), _color(Color("ef4136")))
			draw_colored_polygon(PackedVector2Array([o + Vector2(s * 0.68, s * 0.56), o + Vector2(s * 0.86, s * 0.8), o + Vector2(s * 0.68, s * 0.76)]), _color(Color("ef4136")))
			draw_colored_polygon(PackedVector2Array([o + Vector2(s * 0.4, s * 0.76), o + Vector2(s * 0.6, s * 0.76), o + Vector2(s * 0.5, s * 0.98)]), _color(Color("ffc531")))


static func _estrella(c: Vector2, r_ext: float, r_int: float) -> PackedVector2Array:
	var puntos := PackedVector2Array()
	for i in 10:
		var r := r_ext if i % 2 == 0 else r_int
		var ang := -PI / 2 + i * PI / 5
		puntos.append(c + Vector2(cos(ang), sin(ang)) * r)
	return puntos
