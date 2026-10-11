class_name Niveles
extends RefCounted
## Datos de cada nivel: reto de construcción, teoría con demostración y
## parámetros del laboratorio «Comprobar» (fórmula frente a fuerza bruta).

## Más allá de esta cantidad de casos no se enumera (para que el navegador no se trabe).
const LIMITE_ENUMERACION := 40000

## Parámetros del laboratorio: [nombre, mínimo, máximo].
const LAB := {
	"producto": [["n · ladrillos", 0, 8], ["k · colores", 1, 5]],
	"adyacentes": [["n · ladrillos", 1, 8], ["k · colores", 1, 5]],
	"variaciones": [["n · piezas", 1, 7], ["r · altura", 0, 7]],
	"combinaciones": [["n · piezas", 1, 7], ["r · elegidas", 0, 7]],
	"multinomial": [["rojos", 0, 4], ["azules", 0, 4], ["amarillos", 0, 4]],
	"bolsa": [["r · ladrillos", 0, 8], ["k · colores", 1, 5]],
	"altura": [["n · altura", 0, 20]],
	"sobreyectivas": [["n · ladrillos", 0, 8], ["k · colores", 1, 5]],
	"burnside": [["a · ancho", 1, 4], ["b · largo", 1, 6]],
}

const METODO := {
	"producto": "se generan todas las sucesiones de n colores y se cuentan.",
	"adyacentes": "se generan las sucesiones de colores descartando las que tienen dos vecinos iguales.",
	"variaciones": "se generan las sucesiones de r piezas sin repetir ninguna.",
	"combinaciones": "se generan las sucesiones de r piezas sin repetir, se ordena cada una y se cuentan las distintas.",
	"multinomial": "se generan las sucesiones que usan exactamente los ladrillos disponibles.",
	"bolsa": "se generan las kʳ sucesiones de colores, se ordena cada una (una bolsa no tiene orden) y se cuentan las distintas.",
	"altura": "se generan todas las sucesiones de placas y ladrillos cuya altura suma n.",
	"sobreyectivas": "se generan las kⁿ torres y se conservan las que usan todos los colores.",
	"burnside": "se recorren todas las posiciones del ladrillo de arriba; para cada una se gira el modelo completo 0°, 90°, 180° y 270° y se guarda la menor descripción. No se usa la fórmula ni el grupo {e, ρ}.",
}

static var _cache: Array = []


static func todos() -> Array:
	if _cache.is_empty():
		_cache = _crear()
	return _cache


static func cantidad() -> int:
	return todos().size()


static func obtener(i: int) -> Dictionary:
	return todos()[i]


## Valor de la fórmula del laboratorio `tipo` con parámetros `p`, su texto y,
## si se pide y es razonable, el conteo por fuerza bruta (−1 si no se hizo).
static func calcular(tipo: String, p: Array, enumerar := false) -> Dictionary:
	var r := {"valor": 0, "formula": "", "enumerado": -1, "costo": 0, "reglas": {}}
	match tipo:
		"producto":
			var n: int = p[0]
			var k: int = p[1]
			r.valor = Combinatoria.torres(n, k)
			r.formula = "kⁿ = %d%s = %s" % [k, Combinatoria.sup(n), Combinatoria.fmt(r.valor)]
			r.costo = Combinatoria.potencia(k, n)
			r.reglas = {"n": n, "k": k}
		"adyacentes":
			var n: int = p[0]
			var k: int = p[1]
			r.valor = Combinatoria.torres_sin_adyacentes(n, k)
			r.formula = "k·(k − 1)ⁿ⁻¹ = %d·%d%s = %s" % [k, k - 1, Combinatoria.sup(n - 1), Combinatoria.fmt(r.valor)]
			r.costo = Combinatoria.potencia(k, n)
			r.reglas = {"n": n, "k": k, "sin_adyacentes": true}
		"variaciones":
			var n: int = p[0]
			var m: int = p[1]
			r.valor = Combinatoria.variaciones(n, m)
			if m <= n:
				r.formula = "n!/(n − r)! = %d!/%d! = %s" % [n, n - m, Combinatoria.fmt(r.valor)]
			else:
				r.formula = "r > n: no alcanzan las piezas, así que hay 0."
			r.costo = r.valor
			r.reglas = {"n": m, "k": n, "sin_repetir": true}
		"combinaciones":
			var n: int = p[0]
			var m: int = p[1]
			r.valor = Combinatoria.binomial(n, m)
			if m <= n:
				r.formula = "C(n, r) = n!/(r!·(n − r)!) = %d!/(%d!·%d!) = %s" % [n, m, n - m, Combinatoria.fmt(r.valor)]
			else:
				r.formula = "r > n: no hay subconjuntos de ese tamaño, así que hay 0."
			r.costo = Combinatoria.variaciones(n, m)
			r.reglas = {"n": m, "k": n, "sin_repetir": true, "orden_importa": false}
		"multinomial":
			var a: int = p[0]
			var b: int = p[1]
			var c: int = p[2]
			r.valor = Combinatoria.multinomial([a, b, c])
			r.formula = "(a + b + c)!/(a!·b!·c!) = %d!/(%d!·%d!·%d!) = %s" % [a + b + c, a, b, c, Combinatoria.fmt(r.valor)]
			r.costo = r.valor
			r.reglas = {"inventario": [a, b, c]}
		"bolsa":
			var m: int = p[0]
			var k: int = p[1]
			r.valor = Combinatoria.bolsas(m, k)
			r.formula = "C(r + k − 1, k − 1) = C(%d, %d) = %s" % [m + k - 1, k - 1, Combinatoria.fmt(r.valor)]
			r.costo = Combinatoria.potencia(k, m)
			r.reglas = {"n": m, "k": k, "orden_importa": false}
		"altura":
			var n: int = p[0]
			r.valor = Combinatoria.pilas(n)
			if n >= 3:
				r.formula = "hₙ = hₙ₋₁ + hₙ₋₃ = %s + %s = %s" % [
					Combinatoria.fmt(Combinatoria.pilas(n - 1)),
					Combinatoria.fmt(Combinatoria.pilas(n - 3)),
					Combinatoria.fmt(r.valor)]
			else:
				r.formula = "hₙ = 1: con n < 3 sólo caben placas."
			var terminos := PackedStringArray()
			var valores := PackedStringArray()
			for j in range(0, floori(n / 3.0) + 1):
				terminos.append("C(%d, %d)" % [n - 2 * j, j])
				valores.append(str(Combinatoria.binomial(n - 2 * j, j)))
			r.formula += "\nForma cerrada: %s = %s = %s" % [" + ".join(terminos), " + ".join(valores), Combinatoria.fmt(r.valor)]
			r.costo = r.valor
		"sobreyectivas":
			var n: int = p[0]
			var k: int = p[1]
			r.valor = Combinatoria.torres_todos_colores(n, k)
			r.formula = "Σ (−1)ʲ·C(k, j)·(k − j)ⁿ = %s = %s" % [Combinatoria.terminos_inclusion_exclusion(n, k), Combinatoria.fmt(r.valor)]
			r.costo = Combinatoria.potencia(k, n)
			r.reglas = {"n": n, "k": k, "todos_colores": true}
		"burnside":
			var a: int = p[0]
			var b: int = p[1]
			var x := Combinatoria.posiciones_dos_ladrillos(a, b)
			r.valor = Combinatoria.formas_dos_ladrillos(a, b)
			if a == b:
				r.formula = "Ladrillo cuadrado, 4 giros: (|X| + 1 + 1 + 1)/4 = (%d + 3)/4 = %s" % [x, Combinatoria.fmt(r.valor)]
			else:
				r.formula = "(|X| + |Fix ρ|)/2 = (%d + %d)/2 = %s" % [x, Combinatoria.fijos_giro(a, b), Combinatoria.fmt(r.valor)]
			r.costo = x
	if enumerar and r.costo <= LIMITE_ENUMERACION:
		match tipo:
			"altura":
				r.enumerado = Enumerador.enumerar_pilas(p[0]).size()
			"burnside":
				r.enumerado = Enumerador.contar_dos_ladrillos_independiente(p[0], p[1])
			_:
				r.enumerado = Enumerador.contar_torres(Enumerador.reglas(r.reglas))
	return r


static func _p(parrafos: Array) -> String:
	return "\n\n".join(PackedStringArray(parrafos))


static func _crear() -> Array:
	return [
		{
			"titulo": "Torres de colores",
			"concepto": "Regla del producto",
			"formula_corta": "kⁿ = 2³ = 8",
			"modo": "torre",
			"reglas": {"n": 3, "k": 2},
			"lab": "producto",
			"params": [3, 2],
			"objetivo": 8,
			"temas": ["producto"],
			"enunciado": "Arma todas las torres distintas de [b]3 ladrillos[/b] usando ladrillos [b]rojos[/b] y [b]azules[/b]. Cada torre se registra sola al poner el tercer ladrillo; si ya la tenías, el juego te avisa.",
			"teoria": _p([
				"[b]Modelo.[/b] Sea C el conjunto de colores, con |C| = k. Una torre de n ladrillos es una n-tupla (c₁, c₂, …, cₙ) ∈ Cⁿ, donde c₁ es el ladrillo de abajo. Dos torres son iguales cuando coinciden nivel por nivel.",
				"[b]Principios de conteo[/b] (A y B son conjuntos finitos):\n• [b]P1 (suma):[/b] si A ∩ B = ∅, entonces |A ∪ B| = |A| + |B|.\n• [b]P2 (producto):[/b] |A × B| = |A|·|B|.\n• [b]P3 (biyección):[/b] si existe una biyección f: A → B, entonces |A| = |B|.\n• [b]P4 (división):[/b] si f: A → B es sobreyectiva y cada fibra f⁻¹(b) tiene m elementos, entonces |A| = m·|B|. Se deduce de P1, porque A es la unión disjunta de sus fibras.",
				"[b]Teorema 1.[/b] Hay exactamente kⁿ torres de n ladrillos con k colores.",
				"[b]Demostración.[/b] Por inducción sobre n. Si n = 1 hay una torre por color: k. Si n > 1, la función (c₁, …, cₙ) ↦ ((c₁, …, cₙ₋₁), cₙ) es una biyección de Cⁿ en Cⁿ⁻¹ × C. Por P3, P2 y la hipótesis de inducción, |Cⁿ| = |Cⁿ⁻¹|·|C| = kⁿ⁻¹·k = kⁿ. ∎",
				"[b]En el juego.[/b] Con k = 2 y n = 3 hay 2³ = 8 torres. Cada torre que armas se guarda como la tupla (c₁, c₂, c₃); si ya estaba registrada no suma. Por eso el contador se detiene exactamente en 8. En la pestaña [i]Comprobar[/i] el juego genera todas las torres por fuerza bruta y verifica que salen kⁿ para otros valores de n y k.",
			]),
		},
		{
			"titulo": "Vecinos distintos",
			"concepto": "Producto con restricciones",
			"formula_corta": "k·(k − 1)ⁿ⁻¹ = 3·2² = 12",
			"modo": "torre",
			"reglas": {"n": 3, "k": 3, "sin_adyacentes": true},
			"lab": "adyacentes",
			"params": [3, 3],
			"objetivo": 12,
			"temas": ["adyacentes"],
			"enunciado": "Arma todas las torres de [b]3 ladrillos[/b] con [b]3 colores[/b] en las que [b]dos ladrillos pegados nunca sean del mismo color[/b].",
			"teoria": _p([
				"[b]Modelo.[/b] Aₙ = { (c₁, …, cₙ) ∈ Cⁿ : cᵢ ≠ cᵢ₊₁ para i = 1, …, n − 1 }: torres en las que dos ladrillos pegados nunca son del mismo color. Se usan los principios P1–P4 del nivel 1.",
				"[b]Teorema 2.[/b] Si k ≥ 2, entonces |Aₙ| = k·(k − 1)ⁿ⁻¹.",
				"[b]Demostración.[/b] Por inducción sobre n. Si n = 1, A₁ = C tiene k elementos. Si n ≥ 2, sea π: Aₙ → Aₙ₋₁ la función que quita el ladrillo de arriba. Está bien definida (quitar un ladrillo no crea vecinos iguales) y es sobreyectiva, porque como k ≥ 2 siempre hay un color distinto de cₙ₋₁ para poner encima. La fibra de (c₁, …, cₙ₋₁) está formada por las torres (c₁, …, cₙ₋₁, cₙ) con cₙ ∈ C ∖ {cₙ₋₁}: exactamente k − 1. Por P4, |Aₙ| = (k − 1)·|Aₙ₋₁| = (k − 1)·k·(k − 1)ⁿ⁻² = k·(k − 1)ⁿ⁻¹. ∎",
				"[b]Error típico.[/b] Responder (k − 1)ⁿ: el ladrillo de abajo no tiene vecino debajo, así que tiene k opciones, no k − 1.",
				"[b]En el juego.[/b] Con k = 3 y n = 3 hay 3·2² = 12 torres. El constructor no te deja poner un ladrillo sobre otro del mismo color: aplica literalmente la definición de Aₙ.",
			]),
		},
		{
			"titulo": "Piezas únicas",
			"concepto": "Permutaciones",
			"formula_corta": "n!/(n − r)! = 4!/2! = 12",
			"modo": "torre",
			"reglas": {"n": 2, "k": 4, "sin_repetir": true},
			"lab": "variaciones",
			"params": [4, 2],
			"objetivo": 12,
			"temas": ["variaciones"],
			"enunciado": "Tienes [b]4 piezas únicas[/b] (una de cada color). Arma todas las torres de [b]2 piezas[/b] sin repetir pieza. El orden importa: rojo sobre azul no es lo mismo que azul sobre rojo.",
			"teoria": _p([
				"[b]Modelo.[/b] B es un conjunto de n piezas distintas (cada color existe una sola vez). Una torre de r piezas sin repetir es una función inyectiva {1, …, r} → B: el nivel i recibe una pieza y ninguna pieza se usa dos veces.",
				"[b]Teorema 3.[/b] El número de torres de r piezas distintas elegidas entre n es P(n, r) = n·(n − 1)⋯(n − r + 1) = n!/(n − r)!. En particular, hay n! formas de apilar las n piezas.",
				"[b]Demostración.[/b] Por inducción sobre r. P(n, 1) = n. Si r ≥ 2, sea π la función que quita la pieza de arriba de una torre de r piezas. Es sobreyectiva sobre las torres de r − 1 piezas, y la fibra de cada una son las piezas que aún no se usaron: n − (r − 1). Por P4, P(n, r) = (n − r + 1)·P(n, r − 1), y desarrollando se obtiene el producto n·(n − 1)⋯(n − r + 1). ∎",
				"[b]En el juego.[/b] Con n = 4 piezas y torres de r = 2 hay 4·3 = 12. Si intentas usar dos veces la misma pieza, el constructor lo impide: la función debe ser inyectiva.",
			]),
		},
		{
			"titulo": "Elige tu set",
			"concepto": "Combinaciones",
			"formula_corta": "C(5, 3) = 10",
			"modo": "fila",
			"reglas": {"n": 3, "k": 5, "sin_repetir": true, "orden_importa": false},
			"lab": "combinaciones",
			"params": [5, 3],
			"objetivo": 10,
			"temas": ["combinaciones"],
			"enunciado": "Tienes [b]5 piezas únicas[/b]. Elige [b]3[/b] para un set. Ahora el orden [b]no[/b] importa: el juego ordena la fila por ti. Encuentra todas las selecciones distintas.",
			"teoria": _p([
				"[b]Modelo.[/b] Una selección de r piezas de B (|B| = n) es un subconjunto S ⊆ B con |S| = r. Aquí el orden no importa: {rojo, azul} = {azul, rojo}. Su número se escribe C(n, r).",
				"[b]Teorema 4.[/b] C(n, r) = n!/(r!·(n − r)!).",
				"[b]Demostración[/b] (doble conteo). Sea f la función que lleva cada torre de r piezas distintas al conjunto de piezas que usa. Es sobreyectiva, y la fibra de un conjunto S son todas las formas de apilar sus r piezas: r! (teorema 3 con n = r). Por P4, P(n, r) = r!·C(n, r), así que C(n, r) = n!/(r!·(n − r)!). ∎",
				"[b]En el juego.[/b] Las piezas se ponen en fila y el juego las ordena solas por color: ese orden fijo es el [i]representante canónico[/i] del conjunto, así que dos selecciones con las mismas piezas cuentan como una. Con n = 5 y r = 3 hay C(5, 3) = 10 selecciones, aunque hay P(5, 3) = 60 torres: cada selección corresponde a 3! = 6 torres.",
			]),
		},
		{
			"titulo": "Colores repetidos",
			"concepto": "Permutaciones con repetición",
			"formula_corta": "4!/(2!·1!·1!) = 12",
			"modo": "torre",
			"reglas": {"inventario": [2, 1, 1]},
			"lab": "multinomial",
			"params": [2, 1, 1],
			"objetivo": 12,
			"temas": ["multinomial"],
			"enunciado": "Tienes exactamente [b]2 ladrillos rojos, 1 azul y 1 amarillo[/b]. Arma todas las torres distintas que usan los 4.",
			"teoria": _p([
				"[b]Modelo.[/b] Tienes aᵢ ladrillos idénticos del color i (i = 1, …, k) y n = a₁ + ⋯ + aₖ. Una torre usa todos los ladrillos; dos ladrillos del mismo color son indistinguibles.",
				"[b]Teorema 5.[/b] El número de torres es n!/(a₁!·a₂!⋯aₖ!).",
				"[b]Demostración.[/b] Ponle una etiqueta a cada ladrillo del mismo color (rojo₁, rojo₂, …). Ahora hay n piezas distintas y n! torres (teorema 3). Sea f la función que borra las etiquetas: es sobreyectiva y la fibra de una torre son todas las maneras de repartir las etiquetas dentro de cada color, que son a₁!·a₂!⋯aₖ! (P2 y teorema 3). Por P4, n! = (a₁!⋯aₖ!)·(número de torres). ∎",
				"[b]Otra forma.[/b] Elige las posiciones de los ladrillos del color 1, luego las del color 2 entre las que quedan, y así sucesivamente: C(n, a₁)·C(n − a₁, a₂)⋯ = n!/(a₁!⋯aₖ!), porque el producto es telescópico.",
				"[b]En el juego.[/b] Con 2 rojos, 1 azul y 1 amarillo hay 4!/(2!·1!·1!) = 12 torres. Cada botón muestra cuántos ladrillos te quedan de cada color.",
			]),
		},
		{
			"titulo": "La bolsa de piezas",
			"concepto": "Combinaciones con repetición",
			"formula_corta": "C(r + k − 1, k − 1) = C(5, 2) = 10",
			"modo": "fila",
			"bolsa": true,
			"reglas": {"n": 3, "k": 3, "orden_importa": false},
			"lab": "bolsa",
			"params": [3, 3],
			"objetivo": 10,
			"temas": ["bolsa"],
			"enunciado": "Arma todas las [b]bolsas de 3 ladrillos[/b] con [b]3 colores[/b], repitiendo colores si quieres. En una bolsa sólo importa cuántos hay de cada color.",
			"teoria": _p([
				"[b]Modelo.[/b] Una bolsa de r ladrillos con k colores disponibles (de cada color hay todos los que quieras) es un multiconjunto: sólo importa cuántos ladrillos hay de cada color. Equivale a una solución de x₁ + x₂ + ⋯ + xₖ = r con cada xᵢ entero y xᵢ ≥ 0.",
				"[b]Teorema 6.[/b] Hay C(r + k − 1, k − 1) bolsas.",
				"[b]Demostración[/b] (estrellas y barras). A la bolsa (x₁, …, xₖ) le asignamos la palabra formada por x₁ estrellas, una barra, x₂ estrellas, una barra, …, xₖ estrellas. Por ejemplo, con k = 3 la bolsa {rojo, rojo, amarillo} da ★★||★. Es una palabra de r + k − 1 símbolos con exactamente k − 1 barras. La función inversa cuenta las estrellas entre barras consecutivas, así que es una biyección (P3). Una palabra así queda determinada por las posiciones de sus k − 1 barras entre r + k − 1 lugares: C(r + k − 1, k − 1) (teorema 4). ∎",
				"[b]Corolario.[/b] Si debe haber al menos un ladrillo de cada color, hay C(r − 1, k − 1) bolsas: con yᵢ = xᵢ − 1 ≥ 0 la ecuación pasa a ser y₁ + ⋯ + yₖ = r − k.",
				"[b]En el juego.[/b] Con r = 3 y k = 3 hay C(5, 2) = 10 bolsas. Debajo de la construcción ves la palabra de estrellas y barras de tu bolsa: es la biyección de la demostración funcionando.",
			]),
		},
		{
			"titulo": "Altura exacta",
			"concepto": "Recurrencias",
			"formula_corta": "hₙ = hₙ₋₁ + hₙ₋₃ → h₆ = 6",
			"modo": "altura",
			"altura": 6,
			"lab": "altura",
			"params": [6],
			"objetivo": 6,
			"temas": ["altura"],
			"enunciado": "Usa [b]placas[/b] (altura 1) y [b]ladrillos[/b] (altura 3) para formar todas las pilas de [b]altura exacta 6[/b]. El orden de abajo hacia arriba importa.",
			"teoria": _p([
				"[b]Modelo.[/b] En LEGO una placa mide un tercio de lo que mide un ladrillo. Medido en placas: placa = 1 y ladrillo = 3. Sea hₙ el número de pilas (sucesiones de placas y ladrillos, de abajo arriba) de altura exacta n.",
				"[b]Teorema 7.[/b] h₀ = h₁ = h₂ = 1 y hₙ = hₙ₋₁ + hₙ₋₃ para n ≥ 3. Además, hₙ = Σ C(n − 2j, j), sumando sobre j = 0, 1, …, ⌊n/3⌋.",
				"[b]Demostración de la recurrencia.[/b] Si n < 3 sólo caben placas y hay una sola pila. Si n ≥ 3, separa las pilas según la pieza de arriba (P1). Si es una placa, quitarla da una biyección con las pilas de altura n − 1; si es un ladrillo, con las de altura n − 3 (P3). Luego hₙ = hₙ₋₁ + hₙ₋₃. ∎",
				"[b]Demostración de la forma cerrada.[/b] Una pila con j ladrillos tiene n − 3j placas, es decir, n − 2j piezas en total. Queda determinada al elegir cuáles j de esas n − 2j posiciones son ladrillos: C(n − 2j, j) (teorema 4). Sumando sobre los valores posibles de j (P1) se obtiene la fórmula. ∎",
				"[b]Valores.[/b] 1, 1, 1, 2, 3, 4, 6, 9, 13, 19, 28, 41, 60, …",
				"[b]En el juego.[/b] Altura 6: h₆ = h₅ + h₃ = 4 + 2 = 6, y también C(6, 0) + C(4, 1) + C(2, 2) = 1 + 4 + 1 = 6. La marca verde transparente indica la altura que debes alcanzar.",
			]),
		},
		{
			"titulo": "Todos los colores",
			"concepto": "Inclusión–exclusión",
			"formula_corta": "3⁴ − 3·2⁴ + 3·1⁴ = 36",
			"modo": "torre",
			"reglas": {"n": 4, "k": 3, "todos_colores": true},
			"lab": "sobreyectivas",
			"params": [4, 3],
			"objetivo": 12,
			"temas": ["sobreyectivas"],
			"enunciado": "Arma torres de [b]4 ladrillos[/b] con [b]3 colores[/b] en las que aparezcan [b]los 3 colores[/b]. Hay 36; encuentra al menos 12.",
			"teoria": _p([
				"[b]Modelo.[/b] Torres de n ladrillos con k colores en las que cada color aparece al menos una vez. Equivale a contar las funciones sobreyectivas {1, …, n} → C.",
				"[b]Teorema 8.[/b] Su número es Σ (−1)ʲ·C(k, j)·(k − j)ⁿ, sumando sobre j = 0, 1, …, k.",
				"[b]Demostración.[/b] Sea Aᵢ el conjunto de torres que no usan el color i. Las torres buscadas son las que no están en ningún Aᵢ, y son kⁿ − |A₁ ∪ ⋯ ∪ Aₖ|. La intersección de j de esos conjuntos son las torres con los k − j colores restantes, que son (k − j)ⁿ (teorema 1), y hay C(k, j) intersecciones de ese tipo. Por el principio de inclusión–exclusión, |A₁ ∪ ⋯ ∪ Aₖ| = Σ (−1)ʲ⁺¹·C(k, j)·(k − j)ⁿ con j = 1, …, k. Restando de kⁿ se obtiene la fórmula. ∎",
				"[b]En el juego.[/b] Con n = 4 y k = 3: 3⁴ − 3·2⁴ + 3·1⁴ − 0⁴ = 81 − 48 + 3 = 36 torres. El reto pide encontrar al menos 12; en la galería puedes ver las 36.",
			]),
		},
		{
			"titulo": "Dos ladrillos 2×4",
			"concepto": "Lema de Burnside",
			"formula_corta": "(46 + 2)/2 = 24",
			"modo": "eilers",
			"lab": "burnside",
			"params": [2, 4],
			"objetivo": 24,
			"temas": ["burnside"],
			"enunciado": "Pon un ladrillo 2×4 sobre otro de todas las formas posibles. Muévelo con las flechas, gíralo con R y registra con Enter. Dos construcciones que son la misma girada cuentan una sola vez. ¿Puedes encontrar las 24?",
			"teoria": _p([
				"[b]Modelo.[/b] Los studs forman la rejilla ℤ². El ladrillo de abajo ocupa el rectángulo B = [lb]0, 2[rb] × [lb]0, 4[rb]. El de arriba es otro rectángulo 2×4 con vértices enteros, paralelo o perpendicular a B, que se solapa con B en área positiva (encaja en al menos un stud). Sea X el conjunto de esas posiciones.",
				"[b]Lema 9.[/b] |X| = 46.",
				"[b]Demostración.[/b] Paralelo: [lb]x, x + 2[rb] × [lb]y, y + 4[rb] se solapa con B si y sólo si −2 < x < 2 y −4 < y < 4, lo que da 3·7 = 21 posiciones. Perpendicular: [lb]x, x + 4[rb] × [lb]y, y + 2[rb] se solapa con B si y sólo si −4 < x < 2 y −2 < y < 4, es decir 5·5 = 25. Por P1, |X| = 21 + 25 = 46. Para ladrillos a×b con a ≠ b, el mismo razonamiento da (2a − 1)(2b − 1) + (a + b − 1)². ∎",
				"[b]Simetría.[/b] Dos construcciones son la misma si una es la otra girada alrededor de un eje vertical. Los reflejos no cuentan: un modelo y su imagen en un espejo son físicamente distintos. El giro debe llevar el ladrillo de abajo a sí mismo y B no es cuadrado, así que el grupo es G = {e, ρ}, con ρ(u, v) = (2 − u, 4 − v): el giro de 180° alrededor del centro (1, 2) de B.",
				"[b]Lema de Burnside.[/b] Si un grupo finito G actúa sobre un conjunto finito X, el número de órbitas es (1/|G|)·Σ |Fix(g)|, sumando sobre g ∈ G.",
				"[b]Demostración.[/b] Contamos de dos formas los pares (g, x) con g·x = x. Por elementos de G salen Σ |Fix(g)|. Por elementos de X salen Σ |Stab(x)| = Σ |G|/|Orb(x)|, por el teorema órbita–estabilizador. Cada órbita O aporta |O|·(|G|/|O|) = |G|, así que el total es |G|·(número de órbitas). ∎",
				"[b]Teorema 10.[/b] Hay exactamente 24 formas de unir dos ladrillos 2×4.",
				"[b]Demostración.[/b] e fija las 46 posiciones. ρ lleva un rectángulo de centro c a otro de la misma orientación con centro ρ(c); por tanto ρ(T) = T si y sólo si c = (1, 2). En X hay dos rectángulos con ese centro: [lb]0, 2[rb] × [lb]0, 4[rb] y [lb]−1, 3[rb] × [lb]1, 3[rb]. Por Burnside, el número de construcciones es (46 + 2)/2 = 24. ∎",
				"[b]Teorema 11.[/b] Hay (46ⁿ⁻¹ + 2ⁿ⁻¹)/2 torres de n ladrillos 2×4 con un ladrillo por nivel. Para n = 6 son 102 981 504.",
				"[b]Demostración.[/b] Cada ladrillo se apoya en el anterior de 46 formas y ladrillos de niveles distintos nunca chocan: por P2 hay 46ⁿ⁻¹ torres. ρ fija una torre si y sólo si todos sus ladrillos están centrados en (1, 2): 2 opciones por nivel, todas válidas porque cualquier par de ellas se solapa en [lb]0, 2[rb] × [lb]1, 3[rb]. Son 2ⁿ⁻¹ torres fijas y se aplica Burnside. ∎",
				"[b]Historia.[/b] En 1974 LEGO calculó que seis ladrillos 2×4 se combinan de 102 981 500 formas, contando sólo torres. Contando todas las construcciones posibles, Søren Eilers obtuvo en 2005, por computadora, 915 103 765. No se conoce una fórmula cerrada para el caso general.",
				"[b]En el juego.[/b] Cada posición p = (x, y, orientación) se reduce a su forma canónica: la menor entre p y ρ(p). Dos posiciones con la misma forma canónica están en la misma órbita, es decir, son la misma construcción. Por eso el contador llega a 24 y no a 46. Activa [i]Ver gemela[/i] para ver ρ(p) en transparente.",
			]),
		},
	]
