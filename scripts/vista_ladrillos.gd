class_name VistaLadrillos
extends Node3D
## Escena 3D: placa base, luz, cámara orbital y ladrillos con studs.
## Unidades: 1 = distancia entre studs; un ladrillo mide 1.2 de alto y una placa 0.4.

const ALTO_LADRILLO := 1.2
const ALTO_PLACA := 0.4
const RADIO_STUD := 0.3
const ALTO_STUD := 0.17
const HOLGURA := 0.04

var camara: Camera3D
var _piezas: Node3D
var _base: Node3D
var _malla_stud: CylinderMesh
var _materiales := {}
var _yaw := 0.7
var _pitch := 0.55
var _dist := 12.0
var _zoom := 1.0
var _dist_suave := 12.0
var _objetivo := Vector3.ZERO
var _objetivo_suave := Vector3.ZERO


func _ready() -> void:
	var entorno := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Estilo.COLOR_FONDO_3D
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.1
	entorno.environment = env
	add_child(entorno)

	var sol := DirectionalLight3D.new()
	sol.rotation_degrees = Vector3(-55, 35, 0)
	sol.light_energy = 0.95
	# Sin sombras: en el renderer Compatibility una luz con sombra se dibuja en una
	# pasada aditiva aparte y, dentro de un SubViewport, satura los colores.
	sol.shadow_enabled = false
	add_child(sol)

	camara = Camera3D.new()
	camara.fov = 38
	camara.current = true
	add_child(camara)

	_malla_stud = CylinderMesh.new()
	_malla_stud.top_radius = RADIO_STUD
	_malla_stud.bottom_radius = RADIO_STUD
	_malla_stud.height = ALTO_STUD
	_malla_stud.radial_segments = 20
	_malla_stud.rings = 1

	_piezas = Node3D.new()
	add_child(_piezas)
	_colocar_camara()


## Placa base verde con studs; `desde` y `tam` en unidades de stud (x, z).
func preparar_base(desde: Vector2i, tam: Vector2i) -> void:
	if _base:
		_base.queue_free()
	_base = Node3D.new()
	add_child(_base)
	var mat := _material(Estilo.COLOR_BASE)
	var placa := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(tam.x, ALTO_PLACA * 0.5, tam.y)
	placa.mesh = caja
	placa.material_override = mat
	placa.position = Vector3(desde.x + tam.x / 2.0, -ALTO_PLACA * 0.25, desde.y + tam.y / 2.0)
	_base.add_child(placa)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _malla_stud
	mm.instance_count = tam.x * tam.y
	var i := 0
	for x in tam.x:
		for z in tam.y:
			mm.set_instance_transform(i, Transform3D(Basis(), Vector3(desde.x + x + 0.5, ALTO_STUD * 0.5 - 0.02, desde.y + z + 0.5)))
			i += 1
	var studs := MultiMeshInstance3D.new()
	studs.multimesh = mm
	studs.material_override = mat
	_base.add_child(studs)


## Dibuja la lista de piezas. Cada pieza es un diccionario:
## {pos: Vector3 esquina inferior, tam: Vector2i, alto: float, color: Color,
##  fantasma: bool (transparente), studs: bool, margen: float}.
## La pieza en la posición `animar` cae desde arriba.
func mostrar(lista: Array, animar := -1) -> void:
	for hijo in _piezas.get_children():
		hijo.queue_free()
	for i in lista.size():
		var pieza := _crear_pieza(lista[i])
		_piezas.add_child(pieza)
		if i == animar:
			var destino := pieza.position
			pieza.position.y += 2.5
			var tw := pieza.create_tween()
			tw.tween_property(pieza, "position", destino, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


func _crear_pieza(d: Dictionary) -> Node3D:
	var tam: Vector2i = d.tam
	var alto: float = d.alto
	var fantasma: bool = d.get("fantasma", false)
	var margen: float = d.get("margen", 0.0)
	var mat := _material(d.color, fantasma)
	var pieza := Node3D.new()
	pieza.position = d.pos
	var cuerpo := MeshInstance3D.new()
	var caja := BoxMesh.new()
	caja.size = Vector3(tam.x - HOLGURA + margen * 2.0, alto - HOLGURA * 0.5, tam.y - HOLGURA + margen * 2.0)
	cuerpo.mesh = caja
	cuerpo.material_override = mat
	cuerpo.position = Vector3(tam.x / 2.0, alto / 2.0, tam.y / 2.0)
	if fantasma:
		cuerpo.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pieza.add_child(cuerpo)
	if d.get("studs", true):
		for i in tam.x:
			for j in tam.y:
				var stud := MeshInstance3D.new()
				stud.mesh = _malla_stud
				stud.material_override = mat
				stud.position = Vector3(i + 0.5, alto + ALTO_STUD * 0.5 - 0.01, j + 0.5)
				if fantasma:
					stud.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				pieza.add_child(stud)
	return pieza


func _material(color: Color, fantasma := false) -> StandardMaterial3D:
	var clave := color.to_html() + ("f" if fantasma else "")
	if not _materiales.has(clave):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.32
		if fantasma:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color.a = 0.3
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_materiales[clave] = m
	return _materiales[clave]


# --- Cámara -------------------------------------------------------------------

func enfocar(objetivo: Vector3, distancia: float) -> void:
	_objetivo = objetivo
	_dist = distancia


## Coloca la cámara en su destino sin la transición suave.
func saltar_camara() -> void:
	_objetivo_suave = _objetivo
	_dist_suave = _dist * _zoom
	_colocar_camara()


func orbitar(relativo: Vector2) -> void:
	_yaw -= relativo.x * 0.008
	_pitch = clampf(_pitch + relativo.y * 0.006, 0.12, 1.4)


func acercar(factor: float) -> void:
	_zoom = clampf(_zoom * factor, 0.4, 2.5)


func _process(delta: float) -> void:
	var t := 1.0 - exp(-delta * 8.0)
	_objetivo_suave = _objetivo_suave.lerp(_objetivo, t)
	_dist_suave = lerpf(_dist_suave, _dist * _zoom, t)
	_colocar_camara()


func _colocar_camara() -> void:
	var dir := Vector3(cos(_pitch) * sin(_yaw), sin(_pitch), cos(_pitch) * cos(_yaw))
	camara.position = _objetivo_suave + dir * _dist_suave
	camara.look_at(_objetivo_suave, Vector3.UP)


## Convierte una dirección de pantalla (derecha = +x, arriba = −y) al eje de la
## rejilla (x, z) que más se le parece según desde dónde mira la cámara.
func direccion_rejilla(pantalla: Vector2i) -> Vector2i:
	var derecha := camara.global_transform.basis.x
	var adelante := -camara.global_transform.basis.z
	var v := derecha * pantalla.x - adelante * pantalla.y
	if absf(v.x) >= absf(v.z):
		return Vector2i(1 if v.x > 0 else -1, 0)
	return Vector2i(0, 1 if v.z > 0 else -1)
