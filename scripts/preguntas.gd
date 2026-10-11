class_name Preguntas
extends RefCounted
## Preguntas de opción múltiple con parámetros al azar. La respuesta correcta
## sale de las fórmulas de Combinatoria y las opciones incorrectas imitan errores
## típicos: usar P en vez de C, olvidar una restricción, olvidar la simetría…

const TEMAS := ["producto", "adyacentes", "variaciones", "combinaciones", "multinomial", "bolsa", "altura", "sobreyectivas", "burnside"]
const NOMBRE_TEMA := {
	"producto": "Regla del producto",
	"adyacentes": "Producto con restricciones",
	"variaciones": "Permutaciones",
	"combinaciones": "Combinaciones",
	"multinomial": "Permutaciones con repetición",
	"bolsa": "Combinaciones con repetición",
	"altura": "Recurrencias",
	"sobreyectivas": "Inclusión–exclusión",
	"burnside": "Lema de Burnside",
}
const PALABRAS := ["TORRE", "PALETA", "LADRILLO", "CASTILLO", "ESTRELLA"]
const LADRILLOS := [Vector2i(2, 4), Vector2i(2, 3), Vector2i(1, 2), Vector2i(1, 4), Vector2i(2, 6), Vector2i(1, 3), Vector2i(2, 2), Vector2i(1, 6)]


## `cantidad` preguntas repartiendo los temas de forma pareja y sin repetir enunciados.
static func generar_lote(temas: Array, cantidad: int, rng: RandomNumberGenerator) -> Array:
	var lista := []
	while lista.size() < cantidad:
		var mezcla := temas.duplicate()
		_barajar(mezcla, rng)
		lista.append_array(mezcla)
	lista.resize(cantidad)
	var vistos := {}
	var lote := []
	for tema in lista:
		var p := generar(tema, rng)
		var intentos := 0
		while vistos.has(p.texto) and intentos < 20:
			p = generar(tema, rng)
			intentos += 1
		vistos[p.texto] = true
		lote.append(p)
	return lote


## Pregunta lista para mostrar: {tema, texto, opciones (4 textos), correcta (índice), valor, explicacion}.
static func generar(tema: String, rng: RandomNumberGenerator) -> Dictionary:
	var q: Dictionary
	match tema:
		"producto":
			q = _producto(rng)
		"adyacentes":
			q = _adyacentes(rng)
		"variaciones":
			q = _variaciones(rng)
		"combinaciones":
			q = _combinaciones(rng)
		"multinomial":
			q = _multinomial(rng)
		"bolsa":
			q = _bolsa(rng)
		"altura":
			q = _altura(rng)
		"sobreyectivas":
			q = _sobreyectivas(rng)
		_:
			q = _burnside(rng)
	q.tema = NOMBRE_TEMA.get(tema, tema)
	q.pista = Premios.PISTAS.get(tema, "")
	return _armar(q, rng)


static func _armar(q: Dictionary, rng: RandomNumberGenerator) -> Dictionary:
	var correcta: int = q.correcta
	var opciones := [correcta]
	for d in q.distractores:
		if opciones.size() < 4 and d > 0 and not d in opciones:
			opciones.append(d)
	for d in [correcta * 2, correcta + 1, correcta + 2, correcta - 1, correcta * 3, correcta + 10]:
		if opciones.size() < 4 and d > 0 and not d in opciones:
			opciones.append(d)
	_barajar(opciones, rng)
	var textos := []
	for o in opciones:
		textos.append(Combinatoria.fmt(o))
	return {
		"tema": q.tema,
		"texto": q.texto,
		"opciones": textos,
		"correcta": opciones.find(correcta),
		"valor": correcta,
		"explicacion": q.explicacion,
		"pista": q.pista,
	}


static func _barajar(a: Array, rng: RandomNumberGenerator) -> void:
	for i in range(a.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = a[i]
		a[i] = a[j]
		a[j] = t


static func _f(n: int) -> String:
	return Combinatoria.fmt(n)


static func _s(n: int) -> String:
	return Combinatoria.sup(n)


# --- Generadores por tema -----------------------------------------------------

static func _producto(rng: RandomNumberGenerator) -> Dictionary:
	if rng.randi_range(0, 1) == 0:
		var k := rng.randi_range(2, 5)
		var n := rng.randi_range(2, 5)
		var v := Combinatoria.torres(n, k)
		return {
			"texto": "Tienes ladrillos 2×2 de [b]%d colores[/b] (todos los que quieras de cada color). ¿Cuántas torres distintas de [b]%d ladrillos[/b] puedes armar?" % [k, n],
			"correcta": v,
			"distractores": [Combinatoria.potencia(n, k), n * k, Combinatoria.bolsas(n, k), Combinatoria.potencia(k, n - 1)],
			"explicacion": "Regla del producto: cada uno de los %d niveles se elige entre %d colores, así que hay %d%s = %s torres." % [n, k, k, _s(n), _f(v)],
		}
	var cabezas := rng.randi_range(3, 6)
	var torsos := rng.randi_range(2, 5)
	var piernas := rng.randi_range(2, 4)
	var total := cabezas * torsos * piernas
	return {
		"texto": "Una minifigura se arma con una cabeza, un torso y unas piernas. Hay [b]%d cabezas[/b], [b]%d torsos[/b] y [b]%d piernas[/b] distintas. ¿Cuántas minifiguras diferentes se pueden armar?" % [cabezas, torsos, piernas],
		"correcta": total,
		"distractores": [cabezas + torsos + piernas, cabezas * torsos + piernas, Combinatoria.potencia(maxi(cabezas, maxi(torsos, piernas)), 3)],
		"explicacion": "Regla del producto: cada parte se elige de forma independiente, así que hay %d·%d·%d = %s minifiguras." % [cabezas, torsos, piernas, _f(total)],
	}


static func _adyacentes(rng: RandomNumberGenerator) -> Dictionary:
	var k := rng.randi_range(3, 4)
	var n := rng.randi_range(3, 6)
	var v := Combinatoria.torres_sin_adyacentes(n, k)
	return {
		"texto": "Con ladrillos de [b]%d colores[/b], ¿cuántas torres de [b]%d ladrillos[/b] puedes armar si [b]dos ladrillos pegados nunca pueden ser del mismo color[/b]?" % [k, n],
		"correcta": v,
		"distractores": [Combinatoria.potencia(k, n), Combinatoria.potencia(k - 1, n), k * Combinatoria.potencia(k - 1, n), Combinatoria.potencia(k, n) - k],
		"explicacion": "El ladrillo de abajo tiene %d opciones; cada uno de los otros %d sólo debe evitar el color del que tiene debajo, así que tiene %d: %d·%d%s = %s." % [k, n - 1, k - 1, k, k - 1, _s(n - 1), _f(v)],
	}


static func _variaciones(rng: RandomNumberGenerator) -> Dictionary:
	match rng.randi_range(0, 2):
		0:
			var n := rng.randi_range(4, 8)
			var r := rng.randi_range(2, 4)
			var v := Combinatoria.variaciones(n, r)
			var factores := PackedStringArray()
			for i in r:
				factores.append(str(n - i))
			return {
				"texto": "Tienes [b]%d ladrillos de colores distintos[/b] (uno de cada color). ¿Cuántas torres de [b]%d ladrillos[/b] puedes armar sin repetir ladrillo?" % [n, r],
				"correcta": v,
				"distractores": [Combinatoria.binomial(n, r), Combinatoria.potencia(n, r), Combinatoria.factorial(r), n * r],
				"explicacion": "El orden importa y no hay repetición: P(%d, %d) = %s = %s." % [n, r, "·".join(factores), _f(v)],
			}
		1:
			var n := rng.randi_range(4, 10)
			var v := Combinatoria.variaciones(n, 3)
			return {
				"texto": "En un concurso de construcción participan [b]%d equipos[/b]. ¿De cuántas formas se pueden repartir los premios de [b]oro, plata y bronce[/b]?" % n,
				"correcta": v,
				"distractores": [Combinatoria.binomial(n, 3), Combinatoria.potencia(n, 3), 3 * n],
				"explicacion": "Importa quién gana cada premio y nadie gana dos: %d·%d·%d = %s." % [n, n - 1, n - 2, _f(v)],
			}
	var m := rng.randi_range(3, 6)
	var total := Combinatoria.factorial(m)
	return {
		"texto": "¿De cuántas formas puedes apilar [b]%d ladrillos de colores distintos[/b] usando todos?" % m,
		"correcta": total,
		"distractores": [Combinatoria.potencia(m, m), m * (m - 1), Combinatoria.potencia(2, m), m * m],
		"explicacion": "Es una permutación de %d elementos: %d! = %s." % [m, m, _f(total)],
	}


static func _combinaciones(rng: RandomNumberGenerator) -> Dictionary:
	var n: int
	var r: int
	var texto: String
	if rng.randi_range(0, 1) == 0:
		n = rng.randi_range(5, 10)
		r = rng.randi_range(2, 4)
		texto = "Una caja trae [b]%d piezas especiales distintas[/b] y el modelo que vas a armar usa [b]%d[/b] de ellas. ¿Cuántas selecciones distintas de piezas hay? (El orden no importa.)" % [n, r]
	else:
		n = rng.randi_range(6, 12)
		r = rng.randi_range(2, 4)
		texto = "En una clase de [b]%d estudiantes[/b] se elige un equipo de [b]%d[/b] para construir una ciudad de ladrillos. ¿Cuántos equipos distintos se pueden formar?" % [n, r]
	var v := Combinatoria.binomial(n, r)
	var p := Combinatoria.variaciones(n, r)
	return {
		"texto": texto,
		"correcta": v,
		"distractores": [p, Combinatoria.potencia(n, r), Combinatoria.binomial(n + r - 1, r), Combinatoria.binomial(n, r - 1)],
		"explicacion": "El orden no importa: C(%d, %d) = %d!/(%d!·%d!) = %s. Si importara el orden serían P(%d, %d) = %s; cada grupo aparece %d! = %d veces entre ellas." % [n, r, n, r, n - r, _f(v), n, r, _f(p), r, Combinatoria.factorial(r)],
	}


@warning_ignore("integer_division")
static func _multinomial(rng: RandomNumberGenerator) -> Dictionary:
	if rng.randi_range(0, 1) == 0:
		var a := rng.randi_range(2, 3)
		var b := rng.randi_range(1, 3)
		var c := rng.randi_range(1, 2)
		var n := a + b + c
		var v := Combinatoria.multinomial([a, b, c])
		return {
			"texto": "¿Cuántas torres distintas puedes armar usando exactamente [b]%d ladrillos rojos, %d azules y %d amarillos[/b]? (Los ladrillos del mismo color son idénticos.)" % [a, b, c],
			"correcta": v,
			"distractores": [Combinatoria.factorial(n), Combinatoria.potencia(3, n), Combinatoria.factorial(n) / Combinatoria.factorial(a), Combinatoria.multinomial([a + b, c])],
			"explicacion": "Permutaciones con repetición: %d!/(%d!·%d!·%d!) = %s." % [n, a, b, c, _f(v)],
		}
	var palabra: String = PALABRAS[rng.randi_range(0, PALABRAS.size() - 1)]
	var cuenta := {}
	for letra in palabra:
		cuenta[letra] = cuenta.get(letra, 0) + 1
	var n := palabra.length()
	var v := Combinatoria.multinomial(cuenta.values())
	var repetidas := PackedStringArray()
	var factoriales := PackedStringArray()
	for letra in cuenta:
		if cuenta[letra] > 1:
			repetidas.append("la %s aparece %d veces" % [letra, cuenta[letra]])
			factoriales.append("%d!" % cuenta[letra])
	return {
		"texto": "Tienes ladrillos con letras que forman la palabra [b]%s[/b]. ¿Cuántas «palabras» distintas (con o sin sentido) puedes formar apilando [b]todos[/b] los ladrillos?" % palabra,
		"correcta": v,
		"distractores": [Combinatoria.factorial(n), Combinatoria.factorial(n) / 2, v * 2],
		"explicacion": "Hay %d letras, pero %s. Por eso hay %d!/%s = %s." % [n, ", ".join(repetidas), n, "·".join(factoriales), _f(v)],
	}


static func _bolsa(rng: RandomNumberGenerator) -> Dictionary:
	if rng.randi_range(0, 1) == 0:
		var r := rng.randi_range(3, 8)
		var k := rng.randi_range(2, 4)
		var v := Combinatoria.bolsas(r, k)
		return {
			"texto": "Vas a pedir una bolsa de [b]%d ladrillos[/b] eligiendo entre [b]%d colores[/b]. Puedes repetir colores y sólo importa cuántos ladrillos hay de cada color. ¿Cuántas bolsas distintas puedes pedir?" % [r, k],
			"correcta": v,
			"distractores": [Combinatoria.potencia(k, r), Combinatoria.binomial(r + k, k), Combinatoria.binomial(r + k - 1, k), Combinatoria.binomial(r, k - 1)],
			"explicacion": "Estrellas y barras: %d estrellas (los ladrillos) y %d barras (separan los colores), es decir, C(%d, %d) = %s." % [r, k - 1, r + k - 1, k - 1, _f(v)],
		}
	var k := rng.randi_range(2, 4)
	var r := rng.randi_range(k + 1, k + 6)
	var v := Combinatoria.bolsas_con_todos(r, k)
	return {
		"texto": "Pides una bolsa de [b]%d ladrillos[/b] con [b]%d colores[/b] disponibles y debe haber [b]al menos un ladrillo de cada color[/b]. ¿Cuántas bolsas distintas hay?" % [r, k],
		"correcta": v,
		"distractores": [Combinatoria.bolsas(r, k), Combinatoria.binomial(r, k), Combinatoria.potencia(k, r - k), Combinatoria.binomial(r, k - 1)],
		"explicacion": "Pon primero un ladrillo de cada color; quedan %d por repartir libremente entre %d colores: C(%d, %d) = %s." % [r - k, k, r - 1, k - 1, _f(v)],
	}


static func _altura(rng: RandomNumberGenerator) -> Dictionary:
	if rng.randi_range(0, 1) == 0:
		var n := rng.randi_range(5, 12)
		var v := Combinatoria.pilas(n)
		var valores := PackedStringArray()
		for i in n + 1:
			valores.append(str(Combinatoria.pilas(i)))
		return {
			"texto": "Las placas miden 1 y los ladrillos miden 3 (en alturas de placa). ¿Cuántas pilas distintas de [b]altura exacta %d[/b] puedes formar? (Importa el orden de abajo hacia arriba.)" % n,
			"correcta": v,
			"distractores": [Combinatoria.fibonacci(n + 1), Combinatoria.potencia(2, n - 1), Combinatoria.pilas(n - 1), Combinatoria.pilas(n) + Combinatoria.pilas(n - 2)],
			"explicacion": "Según la pieza de arriba, hₙ = hₙ₋₁ + hₙ₋₃, con h₀ = h₁ = h₂ = 1. Los valores de h₀ en adelante son %s; para altura %d hay %s pilas." % [", ".join(valores), n, _f(v)],
		}
	var n := rng.randi_range(8, 13)
	var j := rng.randi_range(1, 2)
	var v := Combinatoria.binomial(n - 2 * j, j)
	return {
		"texto": "Una pila de [b]altura exacta %d[/b] se arma con placas (altura 1) y [b]exactamente %d %s[/b] (altura 3). ¿Cuántas pilas distintas hay?" % [n, j, "ladrillos" if j > 1 else "ladrillo"],
		"correcta": v,
		"distractores": [Combinatoria.binomial(n, j), Combinatoria.binomial(n - j, j), Combinatoria.binomial(n - 3 * j, j), Combinatoria.pilas(n)],
		"explicacion": "Con %d %s quedan %d placas: %d piezas en total. Basta elegir qué posiciones ocupan los ladrillos: C(%d, %d) = %s." % [j, "ladrillos" if j > 1 else "ladrillo", n - 3 * j, n - 2 * j, n - 2 * j, j, _f(v)],
	}


static func _sobreyectivas(rng: RandomNumberGenerator) -> Dictionary:
	var k := rng.randi_range(2, 3)
	var n := rng.randi_range(k + 1, 6)
	var v := Combinatoria.torres_todos_colores(n, k)
	var texto: String
	if rng.randi_range(0, 1) == 0:
		texto = "¿Cuántas torres de [b]%d ladrillos[/b] con [b]%d colores[/b] disponibles usan [b]cada color al menos una vez[/b]?" % [n, k]
	else:
		texto = "Tienes [b]%d ladrillos distintos[/b] (numerados) y [b]%d cajas[/b] de colores distintos. ¿De cuántas formas puedes guardar los ladrillos [b]sin dejar ninguna caja vacía[/b]?" % [n, k]
	return {
		"texto": texto,
		"correcta": v,
		"distractores": [Combinatoria.potencia(k, n), Combinatoria.potencia(k, n) - k * Combinatoria.potencia(k - 1, n), Combinatoria.factorial(k) * Combinatoria.potencia(k, n - k), Combinatoria.binomial(n - 1, k - 1)],
		"explicacion": "Inclusión–exclusión: a las %d%s posibilidades se les quitan las que dejan fuera algún color: %s = %s." % [k, _s(n), Combinatoria.terminos_inclusion_exclusion(n, k), _f(v)],
	}


@warning_ignore("integer_division")
static func _burnside(rng: RandomNumberGenerator) -> Dictionary:
	match rng.randi_range(0, 2):
		0:
			var k := rng.randi_range(2, 4)
			var v := Combinatoria.mosaicos_2x2(k)
			var k4 := Combinatoria.potencia(k, 4)
			return {
				"texto": "Un mosaico de 2×2 se forma con 4 placas 1×1 y hay [b]%d colores[/b] de placa. Si dos mosaicos que se obtienen uno del otro [b]girando la base[/b] cuentan como el mismo, ¿cuántos mosaicos distintos hay?" % k,
				"correcta": v,
				"distractores": [k4, ceili(k4 / 4.0), (k4 + k * k) / 2, k4 - k],
				"explicacion": "Lema de Burnside con los giros de 0°, 90°, 180° y 270°, que dejan fijos %s, %d, %d y %d mosaicos: (%s + %d + %d + %d)/4 = %s." % [_f(k4), k, k * k, k, _f(k4), k, k * k, k, _f(v)],
			}
		1:
			var t: Vector2i = LADRILLOS[rng.randi_range(0, LADRILLOS.size() - 1)]
			var a := t.x
			var b := t.y
			var v := Combinatoria.formas_dos_ladrillos(a, b)
			var x := Combinatoria.posiciones_dos_ladrillos(a, b)
			var explicacion: String
			if a == b:
				explicacion = "Hay (2·%d − 1)² = %d posiciones. Como el ladrillo es cuadrado, los giros de 90°, 180° y 270° dejan fija sólo la posición centrada. Por Burnside: (%d + 1 + 1 + 1)/4 = %s." % [a, x, x, _f(v)]
			else:
				var fijos := Combinatoria.fijos_giro(a, b)
				explicacion = "Hay (2a − 1)(2b − 1) + (a + b − 1)² = %d + %d = %d posiciones. El giro de 180° deja %s (las centradas). Por Burnside: (%d + %d)/2 = %s." % [(2 * a - 1) * (2 * b - 1), (a + b - 1) * (a + b - 1), x, "fijas 2" if fijos == 2 else "fija sólo 1", x, fijos, _f(v)]
			return {
				"texto": "¿De cuántas formas distintas se pueden unir [b]dos ladrillos %d×%d[/b], uno encima del otro? Dos construcciones son la misma si una es la otra girada." % [a, b],
				"correcta": v,
				"distractores": [x, x / 2, (2 * a - 1) * (2 * b - 1), v * 2],
				"explicacion": explicacion,
			}
	var n := rng.randi_range(2, 4)
	var v := Combinatoria.torres_2x4(n)
	var p46 := Combinatoria.potencia(46, n - 1)
	return {
		"texto": "¿Cuántas torres distintas de [b]%d ladrillos 2×4[/b] (un ladrillo por nivel) existen? Dos torres son la misma si una es la otra girada." % n,
		"correcta": v,
		"distractores": [p46, Combinatoria.potencia(24, n - 1), p46 / 2, v + Combinatoria.potencia(2, n - 1)],
		"explicacion": "Cada ladrillo se apoya en el anterior de 46 formas: 46%s = %s. El giro de 180° fija las 2%s torres centradas. Por Burnside: (46%s + 2%s)/2 = %s." % [_s(n - 1), _f(p46), _s(n - 1), _s(n - 1), _s(n - 1), _f(v)],
	}
