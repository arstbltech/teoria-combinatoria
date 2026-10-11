class_name Combinatoria
extends RefCounted
## Fórmulas cerradas de los teoremas del juego. Las demostraciones están en la
## pestaña «Teoría» de cada nivel y en docs/FUNDAMENTACION.md.
## Se trabaja con enteros de 64 bits; los parámetros del juego son pequeños.

const _SUPER := ["⁰", "¹", "²", "³", "⁴", "⁵", "⁶", "⁷", "⁸", "⁹"]


static func factorial(n: int) -> int:
	var r := 1
	for i in range(2, n + 1):
		r *= i
	return r


static func potencia(base: int, exponente: int) -> int:
	var r := 1
	for i in exponente:
		r *= base
	return r


## C(n, r) de forma multiplicativa: tras el paso i, res = C(n − r + i, i), que es entero.
@warning_ignore("integer_division")
static func binomial(n: int, r: int) -> int:
	if n < 0 or r < 0 or r > n:
		return 0
	r = mini(r, n - r)
	var res := 1
	for i in range(1, r + 1):
		res = res * (n - r + i) / i
	return res


## Teorema 1: torres de n ladrillos con k colores.
static func torres(n: int, k: int) -> int:
	return potencia(k, n)


## Teorema 2: torres sin dos ladrillos vecinos del mismo color.
static func torres_sin_adyacentes(n: int, k: int) -> int:
	if n == 0:
		return 1
	return k * potencia(k - 1, n - 1)


## Teorema 3: torres de r piezas distintas elegidas entre n.
static func variaciones(n: int, r: int) -> int:
	if r < 0 or r > n:
		return 0
	var res := 1
	for i in range(n - r + 1, n + 1):
		res *= i
	return res


## Teorema 5: n!/(a₁!·a₂!···aₖ!), calculado como producto de binomiales.
@warning_ignore("integer_division")
static func multinomial(cantidades: Array) -> int:
	var n := 0
	var res := 1
	for a in cantidades:
		for i in range(1, int(a) + 1):
			n += 1
			res = res * n / i
	return res


## Teorema 6: bolsas (multiconjuntos) de r ladrillos con k colores.
static func bolsas(r: int, k: int) -> int:
	if k == 0:
		return 1 if r == 0 else 0
	return binomial(r + k - 1, k - 1)


## Corolario del teorema 6: bolsas con al menos un ladrillo de cada color.
static func bolsas_con_todos(r: int, k: int) -> int:
	if k == 0:
		return 1 if r == 0 else 0
	return binomial(r - 1, k - 1)


## Teorema 7: pilas de altura n con placas (altura 1) y ladrillos (altura 3).
static func pilas(n: int) -> int:
	if n < 0:
		return 0
	var h: Array[int] = [1, 1, 1]
	for i in range(3, n + 1):
		h.append(h[i - 1] + h[i - 3])
	return h[n]


## Teorema 7, forma cerrada: suma sobre el número j de ladrillos.
@warning_ignore("integer_division")
static func pilas_cerrada(n: int) -> int:
	var s := 0
	for j in range(0, n / 3 + 1):
		s += binomial(n - 2 * j, j)
	return s


## Teorema 8: torres que usan los k colores (inclusión–exclusión).
static func torres_todos_colores(n: int, k: int) -> int:
	var s := 0
	for j in range(0, k + 1):
		var termino := binomial(k, j) * potencia(k - j, n)
		s += termino if j % 2 == 0 else -termino
	return s


## Texto de la suma de inclusión–exclusión, por ejemplo "3⁴ − 3·2⁴ + 3·1⁴ − 0⁴".
static func terminos_inclusion_exclusion(n: int, k: int) -> String:
	var texto := ""
	for j in range(0, k + 1):
		var coef := binomial(k, j)
		var termino := ("%d·" % coef if coef != 1 else "") + str(k - j) + sup(n)
		if j == 0:
			texto = termino
		else:
			texto += (" − " if j % 2 == 1 else " + ") + termino
	return texto


## Lema 9: posiciones del ladrillo de arriba sobre otro a×b (sin contar giros).
static func posiciones_dos_ladrillos(a: int, b: int) -> int:
	if a == b:
		return (2 * a - 1) * (2 * a - 1)
	return (2 * a - 1) * (2 * b - 1) + (a + b - 1) * (a + b - 1)


## Posiciones que el giro de 180° deja fijas: las centradas sobre el ladrillo de abajo.
## La perpendicular centrada sólo cae en la rejilla si a y b tienen la misma paridad.
static func fijos_giro(a: int, b: int) -> int:
	if a == b:
		return 1
	return 2 if (a - b) % 2 == 0 else 1


## Teorema 10 (Burnside): construcciones distintas con dos ladrillos a×b.
## Si el ladrillo es cuadrado el grupo tiene 4 giros y cada giro no trivial fija 1 posición.
@warning_ignore("integer_division")
static func formas_dos_ladrillos(a: int, b: int) -> int:
	var x := posiciones_dos_ladrillos(a, b)
	if a == b:
		return (x + 3) / 4
	return (x + fijos_giro(a, b)) / 2


## Teorema 11: torres de n ladrillos 2×4, uno por nivel.
@warning_ignore("integer_division")
static func torres_2x4(n: int) -> int:
	if n <= 0:
		return 0
	return (potencia(46, n - 1) + potencia(2, n - 1)) / 2


## Mosaicos 2×2 de placas 1×1 con k colores, salvo giros (Burnside con 4 giros).
@warning_ignore("integer_division")
static func mosaicos_2x2(k: int) -> int:
	return (potencia(k, 4) + potencia(k, 2) + 2 * k) / 4


static func fibonacci(n: int) -> int:
	var a := 0
	var b := 1
	for i in n:
		var t := a + b
		a = b
		b = t
	return a


## Número en superíndice: sup(12) = "¹²".
static func sup(n: int) -> String:
	var s := ""
	for c in str(n):
		s += "⁻" if c == "-" else _SUPER[int(c)]
	return s


## Separador de miles con espacio que no se corta: 102981504 → "102 981 504".
static func fmt(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	while s.length() > 3:
		out = " " + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("−" if n < 0 else "") + s + out
