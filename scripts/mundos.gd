class_name Mundos
extends RefCounted
## La historia del juego y sus tres mundos (ambientes). Cada mundo agrupa tres
## niveles, tiene su propio cielo, suelo y decoración en 3D, y se desbloquea al
## reunir cierta cantidad de estrellas.

const HISTORIA := [
	"[b]Brickópolis[/b] era una ciudad hecha por completo de ladrillos. Una noche llegó el [b]Caos Aleatorio[/b] y revolvió todas sus piezas: torres, casas y antenas quedaron desarmadas.",
	"Tú eres el [b]Maestro Constructor[/b]. Para reconstruir cada zona no basta con armar una estructura: tienes que descubrir [b]todas las formas distintas[/b] de armarla, sin repetir ninguna. Ahí es donde entra la combinatoria.",
	"Recorre los tres mundos: la [b]Pradera Bloque[/b], las [b]Dunas Doradas[/b] y la [b]Base Lunar[/b]. Gana monedas por cada construcción nueva, busca las configuraciones doradas, supera las preguntas de los guardianes cuidando tus vidas y reúne estrellas para abrir el siguiente mundo.",
	"Al final te espera el Caos Aleatorio en persona. Sólo quien domine la Unidad III de combinatoria podrá devolverle el orden a Brickópolis.",
]

const MUNDOS := [
	{
		"nombre": "Pradera Bloque",
		"historia": "Las primeras casas de la pradera necesitan torres de colores. Aprende a contar con la regla del producto, las restricciones y las permutaciones.",
		"niveles": [0, 1, 2],
		"requiere": 0,
		"color": Color("1fae66"),
		"decoracion": "pradera",
		"cielo_arriba": Color("6fb6ff"),
		"cielo_horizonte": Color("d8efff"),
		"suelo": Color("6cc56b"),
		"base": Color("4caf50"),
		"luz": Color("fff6e5"),
		"luz_energia": 0.9,
		"ambiente": Color("eef6ff"),
		"ambiente_energia": 0.45,
	},
	{
		"nombre": "Dunas Doradas",
		"historia": "En el desierto los mercaderes venden sets y bolsas de piezas. Aquí lo importante es saber cuándo el orden cuenta y cuándo no.",
		"niveles": [3, 4, 5],
		"requiere": 2,
		"color": Color("f08a24"),
		"decoracion": "dunas",
		"cielo_arriba": Color("ffb36b"),
		"cielo_horizonte": Color("ffe6c4"),
		"suelo": Color("e8c88f"),
		"base": Color("d9b77a"),
		"luz": Color("ffe2b8"),
		"luz_energia": 0.95,
		"ambiente": Color("fff1e0"),
		"ambiente_energia": 0.42,
	},
	{
		"nombre": "Base Lunar",
		"historia": "En la Luna los ingenieros apilan placas para sus antenas y unen ladrillos girando en el espacio. Domina las recurrencias, la inclusión–exclusión y la simetría.",
		"niveles": [6, 7, 8],
		"requiere": 5,
		"color": Color("5b55f0"),
		"decoracion": "luna",
		"cielo_arriba": Color("05071a"),
		"cielo_horizonte": Color("1c2350"),
		"suelo": Color("5d6278"),
		"base": Color("8a90a3"),
		"luz": Color("e6ebff"),
		"luz_energia": 0.85,
		"ambiente": Color("9aa6ff"),
		"ambiente_energia": 0.32,
	},
]


static func cantidad() -> int:
	return MUNDOS.size()


static func obtener(m: int) -> Dictionary:
	return MUNDOS[m]


static func de_nivel(nivel: int) -> int:
	for m in MUNDOS.size():
		if nivel in MUNDOS[m].niveles:
			return m
	return 0
