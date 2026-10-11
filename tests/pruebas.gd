extends SceneTree
## Pruebas automáticas: cada teorema contra la enumeración por fuerza bruta,
## los retos de los niveles y el generador de preguntas.
## Uso: godot --headless --path . -s res://tests/pruebas.gd

var pruebas := 0
var fallos := 0


func _initialize() -> void:
	var inicio := Time.get_ticks_msec()
	_probar_teoremas()
	_probar_dos_ladrillos()
	_probar_niveles()
	_probar_preguntas()
	print("%d pruebas, %d fallos (%d ms)" % [pruebas, fallos, Time.get_ticks_msec() - inicio])
	quit(1 if fallos > 0 else 0)


func _igual(obtenido: Variant, esperado: Variant, nombre: String) -> void:
	pruebas += 1
	if obtenido != esperado:
		fallos += 1
		printerr("FALLO %s: se obtuvo %s y se esperaba %s" % [nombre, obtenido, esperado])


func _contar(base: Dictionary) -> int:
	return Enumerador.contar_torres(Enumerador.reglas(base))


func _probar_teoremas() -> void:
	for n in range(0, 7):
		for k in range(1, 5):
			_igual(_contar({"n": n, "k": k}), Combinatoria.torres(n, k), "T1 n=%d k=%d" % [n, k])
			_igual(_contar({"n": n, "k": k, "sin_adyacentes": true}), Combinatoria.torres_sin_adyacentes(n, k), "T2 n=%d k=%d" % [n, k])
			_igual(_contar({"n": n, "k": k, "orden_importa": false}), Combinatoria.bolsas(n, k), "T6 r=%d k=%d" % [n, k])
			_igual(_contar({"n": n, "k": k, "orden_importa": false, "todos_colores": true}), Combinatoria.bolsas_con_todos(n, k), "T6 corolario r=%d k=%d" % [n, k])
			_igual(_contar({"n": n, "k": k, "todos_colores": true}), Combinatoria.torres_todos_colores(n, k), "T8 n=%d k=%d" % [n, k])
	for n in range(1, 7):
		for r in range(0, n + 2):
			_igual(_contar({"n": r, "k": n, "sin_repetir": true}), Combinatoria.variaciones(n, r), "T3 n=%d r=%d" % [n, r])
			_igual(_contar({"n": r, "k": n, "sin_repetir": true, "orden_importa": false}), Combinatoria.binomial(n, r), "T4 n=%d r=%d" % [n, r])
	for inventario in [[2, 1, 1], [3, 2, 0], [1, 1, 1, 1], [2, 2, 2], [4, 1], [0, 0, 0]]:
		_igual(_contar({"inventario": inventario}), Combinatoria.multinomial(inventario), "T5 %s" % [inventario])
	for n in range(0, 21):
		_igual(Enumerador.enumerar_pilas(n).size(), Combinatoria.pilas(n), "T7 recurrencia n=%d" % n)
		_igual(Combinatoria.pilas_cerrada(n), Combinatoria.pilas(n), "T7 forma cerrada n=%d" % n)
	_igual(Combinatoria.binomial(20, 10), 184756, "C(20, 10)")
	_igual(Combinatoria.factorial(10), 3628800, "10!")
	_igual(Combinatoria.fmt(102981504), "102 981 504", "formato de miles")
	_igual(Combinatoria.terminos_inclusion_exclusion(4, 3), "3⁴ − 3·2⁴ + 3·1⁴ − 0⁴", "texto de inclusión–exclusión")


@warning_ignore("integer_division")
func _probar_dos_ladrillos() -> void:
	_igual(Combinatoria.posiciones_dos_ladrillos(2, 4), 46, "Lema 9")
	_igual(Combinatoria.formas_dos_ladrillos(2, 4), 24, "Teorema 10")
	for a in range(1, 5):
		for b in range(1, 7):
			var formula := Combinatoria.formas_dos_ladrillos(a, b)
			_igual(Enumerador.contar_dos_ladrillos_independiente(a, b), formula, "dos ladrillos %d×%d, girando el modelo" % [a, b])
			_igual(Enumerador.clases_eilers(a, b).size(), formula, "dos ladrillos %d×%d, forma canónica" % [a, b])
	_igual(Enumerador.contar_torres_2x4(2), Combinatoria.torres_2x4(2), "T11 n=2")
	_igual(Enumerador.contar_torres_2x4(3), Combinatoria.torres_2x4(3), "T11 n=3")
	_igual(Combinatoria.torres_2x4(3), 1060, "T11 n=3 vale 1060")
	_igual(Combinatoria.torres_2x4(6), 102981504, "T11 n=6")
	# Mosaicos 2×2 salvo giros: las 4 celdas en orden circular; girar 90° = rotar la lista.
	for k in range(1, 5):
		var vistas := {}
		for t in Combinatoria.potencia(k, 4):
			var celdas := []
			var resto := t
			for i in 4:
				celdas.append(resto % k)
				resto = resto / k
			var mejor := ""
			for g in 4:
				var s := str(celdas.slice(g) + celdas.slice(0, g))
				if mejor == "" or s < mejor:
					mejor = s
			vistas[mejor] = true
		_igual(vistas.size(), Combinatoria.mosaicos_2x2(k), "mosaicos 2×2 con k=%d" % k)


func _probar_niveles() -> void:
	for i in Niveles.cantidad():
		var d := Niveles.obtener(i)
		var calculo := Niveles.calcular(d.lab, d.params, true)
		_igual(calculo.enumerado, calculo.valor, "nivel %d: fórmula = enumeración" % (i + 1))
		_igual(d.objetivo <= calculo.valor, true, "nivel %d: el objetivo es alcanzable" % (i + 1))
		if d.has("reglas"):
			_igual(_contar(d.reglas), calculo.valor, "nivel %d: reglas del constructor" % (i + 1))
		# Todo el rango del laboratorio, donde la enumeración es razonable.
		var specs: Array = Niveles.LAB[d.lab]
		var combinaciones: Array = [[]]
		for spec in specs:
			var nuevas := []
			for c in combinaciones:
				for v in range(spec[1], spec[2] + 1):
					nuevas.append(c + [v])
			combinaciones = nuevas
		for p in combinaciones:
			var r := Niveles.calcular(d.lab, p, true)
			if r.enumerado >= 0:
				_igual(r.enumerado, r.valor, "laboratorio %s %s" % [d.lab, p])


func _probar_preguntas() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for tema in Preguntas.TEMAS:
		for i in 300:
			var p := Preguntas.generar(tema, rng)
			var distintas := {}
			for o in p.opciones:
				distintas[o] = true
			var bien: bool = p.opciones.size() == 4 and distintas.size() == 4 and p.valor > 0 \
				and p.correcta >= 0 and p.opciones[p.correcta] == Combinatoria.fmt(p.valor) \
				and not "−" in "".join(PackedStringArray(p.opciones))
			_igual(bien, true, "pregunta de %s: %s %s" % [tema, p.texto, p.opciones])
	var lote := Preguntas.generar_lote(Preguntas.TEMAS, 10, rng)
	_igual(lote.size(), 10, "lote de 10 preguntas")
