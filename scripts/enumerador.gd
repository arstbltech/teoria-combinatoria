class_name Enumerador
extends RefCounted
## Enumeración por fuerza bruta: genera las configuraciones aplicando la
## definición de cada reto (no la fórmula) y cuenta las distintas. Sirve para
## comprobar los teoremas y para dibujar la galería. Las mismas reglas deciden
## si el constructor acepta una pieza.

const ALTO_PIEZA := [1, 3]  # altura de una placa y de un ladrillo, medida en placas


## Reglas de un reto de torres o filas, con valores por defecto.
## Con inventario (cantidad disponible de cada color) se usan todas las piezas.
static func reglas(base: Dictionary) -> Dictionary:
	var r := {
		"n": 3,
		"k": 2,
		"sin_repetir": false,
		"sin_adyacentes": false,
		"todos_colores": false,
		"orden_importa": true,
		"inventario": [],
	}
	r.merge(base, true)
	var inventario: Array = r.inventario
	if not inventario.is_empty():
		var suma := 0
		for c in inventario:
			suma += int(c)
		r.n = suma
		r.k = inventario.size()
	return r


## 0 si la pieza `color` se puede poner encima de `seq`; si no, el número de la regla que falla.
static func _regla_que_falla(seq: Array, color: int, r: Dictionary) -> int:
	if seq.size() >= r.n:
		return 1
	if r.sin_repetir and color in seq:
		return 2
	var inventario: Array = r.inventario
	if not inventario.is_empty() and seq.count(color) >= int(inventario[color]):
		return 3
	if r.sin_adyacentes and not seq.is_empty() and seq[-1] == color:
		return 4
	return 0


static func puede_agregar(seq: Array, color: int, r: Dictionary) -> bool:
	return _regla_que_falla(seq, color, r) == 0


## Explicación para el jugador de por qué no se acepta la pieza ("" si se acepta).
static func motivo_para_no_agregar(seq: Array, color: int, r: Dictionary) -> String:
	match _regla_que_falla(seq, color, r):
		1:
			return "Ya están las %d piezas. Quita una para probar otra combinación." % r.n
		2:
			return "Cada pieza es única y esa ya está puesta."
		3:
			return "Ya no te quedan ladrillos %s." % Estilo.PLURALES[color]
		4:
			return "No puede ir pegado a otro ladrillo %s." % Estilo.NOMBRES[color]
	return ""


static func completa(seq: Array, r: Dictionary) -> bool:
	if seq.size() != r.n:
		return false
	if r.todos_colores:
		for c in r.k:
			if not c in seq:
				return false
	return true


## Explicación de por qué una configuración aún no cuenta ("" si está completa).
static func motivo_incompleta(seq: Array, r: Dictionary) -> String:
	if seq.size() < r.n:
		return "Faltan %d piezas." % (r.n - seq.size())
	if r.todos_colores:
		for c in r.k:
			if not c in seq:
				return "Esa torre no usa todos los colores: falta el %s." % Estilo.NOMBRES[c]
	return ""


## Representante canónico: si el orden no importa, la lista ordenada.
static func canonica(seq: Array, r: Dictionary) -> Array:
	var c := seq.duplicate()
	if not r.orden_importa:
		c.sort()
	return c


static func clave(seq: Array, r: Dictionary) -> String:
	return clave_simple(canonica(seq, r))


static func clave_simple(seq: Array) -> String:
	var partes := PackedStringArray()
	for c in seq:
		partes.append(str(c))
	return "-".join(partes)


# --- Torres y filas -----------------------------------------------------------

## Todas las configuraciones distintas que cumplen las reglas, en forma canónica.
static func enumerar_torres(r: Dictionary) -> Array:
	var vistas := {}
	var lista := []
	_extender([], r, vistas, lista)
	return lista


static func contar_torres(r: Dictionary) -> int:
	return enumerar_torres(r).size()


static func _extender(seq: Array, r: Dictionary, vistas: Dictionary, lista: Array) -> void:
	if seq.size() == r.n:
		if completa(seq, r):
			var c := canonica(seq, r)
			var k := clave_simple(c)
			if not vistas.has(k):
				vistas[k] = true
				lista.append(c)
		return
	for color in r.k:
		if puede_agregar(seq, color, r):
			seq.append(color)
			_extender(seq, r, vistas, lista)
			seq.pop_back()


# --- Pilas de placas y ladrillos ---------------------------------------------

static func altura(seq: Array) -> int:
	var h := 0
	for t in seq:
		h += ALTO_PIEZA[t]
	return h


## Todas las sucesiones de placas (0) y ladrillos (1) que suman exactamente h.
static func enumerar_pilas(h: int) -> Array:
	var lista := []
	_apilar([], 0, h, lista)
	return lista


static func _apilar(seq: Array, suma: int, h: int, lista: Array) -> void:
	if suma == h:
		lista.append(seq.duplicate())
		return
	for t in 2:
		if suma + ALTO_PIEZA[t] <= h:
			seq.append(t)
			_apilar(seq, suma + ALTO_PIEZA[t], h, lista)
			seq.pop_back()


# --- Dos ladrillos a×b (problema de Eilers) ----------------------------------
# El ladrillo de abajo ocupa B = [0, a] × [0, b] en la rejilla de studs.
# El de arriba es p = (x, y, o): esquina mínima (x, y) y orientación o
# (0 = paralelo a B, 1 = perpendicular).

static func dims(o: int, a: int, b: int) -> Vector2i:
	return Vector2i(a, b) if o == 0 else Vector2i(b, a)


## ¿El ladrillo de arriba se solapa con B en área positiva (encaja en algún stud)?
static func se_solapa(p: Vector3i, a: int, b: int) -> bool:
	var d := dims(p.z, a, b)
	return p.x < a and p.x + d.x > 0 and p.y < b and p.y + d.y > 0


## Posición válida más cercana a p (cada eje por separado).
static func ajustar(p: Vector3i, a: int, b: int) -> Vector3i:
	var d := dims(p.z, a, b)
	return Vector3i(clampi(p.x, 1 - d.x, a - 1), clampi(p.y, 1 - d.y, b - 1), p.z)


## ρ: giro de 180° alrededor del centro de B, (u, v) ↦ (a − u, b − v).
static func girar_180(p: Vector3i, a: int, b: int) -> Vector3i:
	var d := dims(p.z, a, b)
	return Vector3i(a - p.x - d.x, b - p.y - d.y, p.z)


## Imágenes de p bajo los giros que dejan fijo a B: {e, ρ}, o los 4 giros si B es cuadrado.
static func orbita(p: Vector3i, a: int, b: int) -> Array:
	var imagenes := [p]
	if a == b:
		var q := p
		for i in 3:
			q = Vector3i(-q.y, q.x, 0)  # giro de 90°: (u, v) ↦ (a − v, u)
			imagenes.append(q)
	else:
		imagenes.append(girar_180(p, a, b))
	return imagenes


## Forma canónica: la menor posición de la órbita. Misma forma ⇔ misma construcción.
static func canonica_eilers(p: Vector3i, a: int, b: int) -> Vector3i:
	var menor := p
	for q in orbita(p, a, b):
		if q < menor:
			menor = q
	return menor


static func clave_eilers(p: Vector3i) -> String:
	return "%d,%d,%d" % [p.x, p.y, p.z]


## Un representante canónico por cada construcción distinta (órbita).
static func clases_eilers(a: int, b: int) -> Array:
	var vistas := {}
	var lista := []
	var m := maxi(a, b)
	for o in ([0] if a == b else [0, 1]):
		for y in range(-m, m + b):
			for x in range(-m, m + a):
				var p := Vector3i(x, y, o)
				if se_solapa(p, a, b):
					var c := canonica_eilers(p, a, b)
					if not vistas.has(c):
						vistas[c] = true
						lista.append(c)
	return lista


## Cuenta las construcciones sin suponer cuál es el grupo de simetrías: gira el
## modelo completo 0°, 90°, 180° y 270°, lo traslada para que el ladrillo de abajo
## empiece en el origen y se queda con la menor descripción. Dos posiciones son
## la misma construcción si sus descripciones coinciden.
static func contar_dos_ladrillos_independiente(a: int, b: int) -> int:
	var vistas := {}
	var m := maxi(a, b)
	var abajo := _celdas(Vector3i(0, 0, 0), a, b)
	for o in [0, 1]:
		for x in range(-m - 1, m + 2):
			for y in range(-m - 1, m + 2):
				var p := Vector3i(x, y, o)
				if se_solapa(p, a, b):
					vistas[_descripcion(abajo, _celdas(p, a, b))] = true
	return vistas.size()


static func _celdas(p: Vector3i, a: int, b: int) -> Array:
	var d := dims(p.z, a, b)
	var celdas := []
	for i in d.x:
		for j in d.y:
			celdas.append(Vector2i(p.x + i, p.y + j))
	return celdas


static func _descripcion(abajo: Array, arriba: Array) -> String:
	var mejor := ""
	var ab := abajo.duplicate()
	var ar := arriba.duplicate()
	for giro in 4:
		if giro > 0:
			ab = ab.map(func(c: Vector2i) -> Vector2i: return Vector2i(-c.y, c.x))
			ar = ar.map(func(c: Vector2i) -> Vector2i: return Vector2i(-c.y, c.x))
		var minimo := Vector2i(ab[0])
		for c in ab:
			minimo = Vector2i(mini(minimo.x, c.x), mini(minimo.y, c.y))
		var ab2 := ab.map(func(c: Vector2i) -> Vector2i: return c - minimo)
		var ar2 := ar.map(func(c: Vector2i) -> Vector2i: return c - minimo)
		ab2.sort()
		ar2.sort()
		var s := str(ab2) + "|" + str(ar2)
		if mejor == "" or s < mejor:
			mejor = s
	return mejor


## Torres de n ladrillos 2×4 (uno por nivel) por fuerza bruta: cada ladrillo se
## apoya en el anterior y cada torre se identifica con su giro de 180°.
static func contar_torres_2x4(n: int) -> int:
	var vistas := {}
	_apilar_2x4([Vector3i(0, 0, 0)], n, vistas)
	return vistas.size()


static func _solapan(p: Vector3i, q: Vector3i, a: int, b: int) -> bool:
	var dp := dims(p.z, a, b)
	var dq := dims(q.z, a, b)
	return p.x < q.x + dq.x and q.x < p.x + dp.x and p.y < q.y + dq.y and q.y < p.y + dp.y


static func _apilar_2x4(torre: Array, n: int, vistas: Dictionary) -> void:
	if torre.size() == n:
		var girada := torre.map(func(p: Vector3i) -> Vector3i: return girar_180(p, 2, 4))
		var k1 := str(torre)
		var k2 := str(girada)
		vistas[k1 if k1 < k2 else k2] = true
		return
	var ultimo: Vector3i = torre[-1]
	for o in [0, 1]:
		for x in range(ultimo.x - 4, ultimo.x + 5):
			for y in range(ultimo.y - 4, ultimo.y + 5):
				var p := Vector3i(x, y, o)
				if _solapan(p, ultimo, 2, 4):
					torre.append(p)
					_apilar_2x4(torre, n, vistas)
					torre.pop_back()
