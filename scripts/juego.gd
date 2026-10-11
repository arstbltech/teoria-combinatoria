extends Node
## Autoload «Juego»: progreso guardado y navegación entre pantallas.

const DESAFIO := 99  # identificador del desafío final en el archivo de progreso

var nivel_actual := 0
var quiz := {"temas": [], "cantidad": 3, "nivel": -1, "titulo": ""}

var _ruta := "user://progreso.cfg"
var _cfg := ConfigFile.new()


func _ready() -> void:
	var prueba := false
	for a in OS.get_cmdline_user_args():
		if a == "--prueba-humo" or a.begins_with("--capturas"):
			prueba = true
	if prueba:
		# Las pruebas no tocan el progreso real del jugador.
		_ruta = "user://progreso_prueba.cfg"
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_ruta))
	_cfg.load(_ruta)
	get_tree().root.theme = Estilo.crear_tema()
	if prueba:
		add_child(load("res://tests/humo.gd").new())


# --- Progreso -----------------------------------------------------------------

func encontradas(nivel: int) -> Array:
	return _cfg.get_value(_seccion(nivel), "encontradas", [])


func guardar_encontradas(nivel: int, claves: Array) -> void:
	_cfg.set_value(_seccion(nivel), "encontradas", claves.duplicate())
	_guardar()


func reto_completado(nivel: int) -> bool:
	return _cfg.get_value(_seccion(nivel), "reto", false)


func marcar_reto(nivel: int) -> void:
	_cfg.set_value(_seccion(nivel), "reto", true)
	_guardar()


## Mejor resultado de preguntas: (aciertos, total).
func mejor_quiz(nivel: int) -> Vector2i:
	return Vector2i(
		_cfg.get_value(_seccion(nivel), "quiz_aciertos", 0),
		_cfg.get_value(_seccion(nivel), "quiz_total", 0))


func registrar_quiz(nivel: int, aciertos: int, total: int) -> void:
	var previo := mejor_quiz(nivel)
	if previo.y == 0 or aciertos * previo.y > previo.x * total:
		_cfg.set_value(_seccion(nivel), "quiz_aciertos", aciertos)
		_cfg.set_value(_seccion(nivel), "quiz_total", total)
		_guardar()


## Nivel: ★ reto completado, ★ al menos 2/3 de las preguntas, ★ todas bien.
## Desafío: ★ 50 %, ★ 80 %, ★ 100 %.
func estrellas(nivel: int) -> int:
	var q := mejor_quiz(nivel)
	if nivel == DESAFIO:
		if q.y == 0:
			return 0
		return int(q.x * 2 >= q.y) + int(q.x * 5 >= q.y * 4) + int(q.x == q.y)
	var e := int(reto_completado(nivel))
	if q.y > 0:
		e += int(q.x * 3 >= q.y * 2) + int(q.x == q.y)
	return e


func borrar_progreso() -> void:
	_cfg = ConfigFile.new()
	_guardar()


func _seccion(nivel: int) -> String:
	return "nivel_%d" % nivel


func _guardar() -> void:
	_cfg.save(_ruta)


# --- Navegación ---------------------------------------------------------------

func ir_a_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func ir_a_nivel(i: int) -> void:
	nivel_actual = i
	get_tree().change_scene_to_file("res://scenes/nivel.tscn")


func ir_a_quiz(temas: Array, cantidad: int, nivel: int, titulo: String) -> void:
	quiz = {"temas": temas, "cantidad": cantidad, "nivel": nivel, "titulo": titulo}
	get_tree().change_scene_to_file("res://scenes/quiz.tscn")
