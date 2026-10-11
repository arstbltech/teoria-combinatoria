class_name Premios
extends RefCounted
## Economía del juego: cuántas monedas da cada cosa, la tienda de objetos y los
## logros (premios) que se desbloquean jugando.

const VIDAS := 3                # corazones por ronda de preguntas

const MONEDAS_CONFIGURACION := 1  # cada construcción nueva
const MONEDAS_RETO := 20          # completar el reto de un nivel (una vez)
const MONEDAS_DORADA := 10        # bonus: encontrar la configuración dorada
const MONEDAS_ACIERTO := 5        # respuesta correcta
const MONEDAS_RACHA := 10         # respuesta correcta con racha de 3 o más (bonus ×2)
const RACHA_BONUS := 3
const MONEDAS_PERFECTO := 15      # ronda de preguntas sin fallar
const MONEDAS_JEFE := 30          # vencer al Caos Aleatorio
const MONEDAS_COFRE := 50         # completar todos los retos de un mundo
const MONEDAS_LOGRO := 15         # cada logro desbloqueado

const TIENDA := [
	{"id": "vida_extra", "nombre": "Vida extra", "icono": "corazon", "precio": 30,
		"descripcion": "Si pierdes tu último corazón en una ronda de preguntas, te salva y sigues jugando."},
	{"id": "comodin", "nombre": "Comodín 50/50", "icono": "comodin", "precio": 40,
		"descripcion": "Elimina dos respuestas incorrectas de una pregunta."},
	{"id": "pista", "nombre": "Pista", "icono": "pista", "precio": 20,
		"descripcion": "Muestra la fórmula general del tema de la pregunta."},
]

## Cada logro se cumple cuando la estadística `stat` llega a `meta`.
const LOGROS := [
	{"id": "primer_ladrillo", "nombre": "Primer ladrillo", "icono": "ladrillo", "stat": "configuraciones", "meta": 1,
		"descripcion": "Registra tu primera construcción."},
	{"id": "constructor", "nombre": "Constructor", "icono": "ladrillo", "stat": "retos", "meta": 3,
		"descripcion": "Completa el reto de 3 niveles."},
	{"id": "coleccionista", "nombre": "Coleccionista", "icono": "estrella", "stat": "galerias_completas", "meta": 1,
		"descripcion": "Encuentra todas las configuraciones de un nivel."},
	{"id": "buscador_oro", "nombre": "Buscador de oro", "icono": "moneda", "stat": "doradas", "meta": 3,
		"descripcion": "Encuentra 3 configuraciones doradas."},
	{"id": "racha_5", "nombre": "Imparable", "icono": "rayo", "stat": "racha_max", "meta": 5,
		"descripcion": "Responde 5 preguntas seguidas sin fallar."},
	{"id": "mente_brillante", "nombre": "Mente brillante", "icono": "pista", "stat": "quiz_perfectos", "meta": 1,
		"descripcion": "Responde perfecto una ronda de preguntas."},
	{"id": "ahorrador", "nombre": "Ahorrador", "icono": "moneda", "stat": "monedas_ganadas", "meta": 200,
		"descripcion": "Gana 200 monedas en total."},
	{"id": "explorador", "nombre": "Explorador", "icono": "cohete", "stat": "mundos", "meta": 3,
		"descripcion": "Desbloquea los tres mundos."},
	{"id": "cofre", "nombre": "Tesoro del mundo", "icono": "cofre", "stat": "cofres", "meta": 1,
		"descripcion": "Completa todos los retos de un mundo y abre su cofre."},
	{"id": "estrellado", "nombre": "Cielo estrellado", "icono": "estrella", "stat": "estrellas", "meta": 15,
		"descripcion": "Reúne 15 estrellas."},
	{"id": "jefe", "nombre": "Orden restaurado", "icono": "trofeo", "stat": "jefe_vencido", "meta": 1,
		"descripcion": "Vence al Caos Aleatorio en el desafío final."},
	{"id": "sin_rasgunos", "nombre": "Sin un rasguño", "icono": "corazon", "stat": "jefe_sin_danio", "meta": 1,
		"descripcion": "Vence al Caos Aleatorio sin perder ninguna vida."},
]

## Fórmula general de cada tema, para el objeto «Pista».
const PISTAS := {
	"producto": "Regla del producto: si una construcción se hace en pasos independientes con a, b, c… opciones, hay a·b·c… resultados. Con n niveles de k colores: kⁿ.",
	"adyacentes": "Producto con restricción: el primero tiene k opciones y cada uno de los siguientes k − 1 (no puede repetir al anterior): k·(k − 1)ⁿ⁻¹.",
	"variaciones": "Si el orden importa y no se repite: P(n, r) = n!/(n − r)!. Usar todas las piezas: n!.",
	"combinaciones": "Si el orden no importa: C(n, r) = n!/(r!·(n − r)!). Cada grupo aparece r! veces entre las listas ordenadas.",
	"multinomial": "Con repetidos idénticos: n!/(a₁!·a₂!⋯aₖ!), dividiendo entre las formas de reordenar cada grupo de iguales.",
	"bolsa": "Estrellas y barras: r objetos en k tipos con repetición, C(r + k − 1, k − 1). Con al menos uno de cada tipo: C(r − 1, k − 1).",
	"altura": "Recurrencia según la última pieza: hₙ = hₙ₋₁ + hₙ₋₃. Con j ladrillos fijos: C(n − 2j, j).",
	"sobreyectivas": "Inclusión–exclusión: Σ (−1)ʲ·C(k, j)·(k − j)ⁿ, quitando las que no usan algún color.",
	"burnside": "Lema de Burnside: número de formas distintas = promedio de configuraciones que deja fijas cada giro.",
}


static func objeto(id: String) -> Dictionary:
	for o in TIENDA:
		if o.id == id:
			return o
	return {}
