class_name VistaLadrillos
extends Node3D
## Escena 3D: ambiente del mundo (cielo, suelo y decoración), placa base, luces,
## cámara orbital y ladrillos con studs.
## Unidades: 1 = distancia entre studs; un ladrillo mide 1.2 de alto y una placa 0.4.

const ALTO_LADRILLO := 1.2
const ALTO_PLACA := 0.4
const RADIO_STUD := 0.3
const ALTO_STUD := 0.17
const HOLGURA := 0.04

var camara: Camera3D
var _env: Environment
var _sol: DirectionalLight3D
var _relleno: DirectionalLight3D
var _piezas: Node3D
var _base: Node3D
var _decoracion: Node3D
var _malla_stud: CylinderMesh
var _materiales := {}
var _material_sombra: StandardMaterial3D
var _yaw := 0.7
var _pitch := 0.45
var _dist := 12.0
var _zoom := 1.0
var _dist_suave := 12.0
var _objetivo := Vector3.ZERO
var _objetivo_suave := Vector3.ZERO


func _ready() -> void:
	var entorno := WorldEnvironment.new()
	_env = Environment.new()
	_env.background_mode = Environment.BG_COLOR
	_env.background_color = Estilo.COLOR_FONDO_3D
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = Color.WHITE
	_env.ambient_light_energy = 0.42
	_env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	_env.tonemap_exposure = 1.1
	entorno.environment = _env
	add_child(entorno)

	_sol = DirectionalLight3D.new()
	_sol.rotation_degrees = Vector3(-55, 35, 0)
	_sol.light_energy = 0.85
	# Sin sombras: en el renderer Compatibility una luz con sombra se dibuja en una
	# pasada aditiva aparte y, dentro de un SubViewport, satura los colores.
	# En su lugar cada pieza apoyada en la base lleva una sombra difusa (ver _sombra).
	_sol.shadow_enabled = false
	_sol.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(_sol)
	_relleno = DirectionalLight3D.new()
	_relleno.rotation_degrees = Vector3(-25, -145, 0)
	_relleno.light_energy = 0.3
	_relleno.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
	add_child(_relleno)

	camara = Camera3D.new()
	camara.fov = 38
	camara.far = 400
	camara.current = true
	add_child(camara)

	_malla_stud = CylinderMesh.new()
	_malla_stud.top_radius = RADIO_STUD
	_malla_stud.bottom_radius = RADIO_STUD
	_malla_stud.height = ALTO_STUD
	_malla_stud.radial_segments = 16
	_malla_stud.rings = 1

	var degradado := Gradient.new()
	degradado.set_color(0, Color(0.1, 0.12, 0.3, 0.3))
	degradado.set_color(1, Color(0.1, 0.12, 0.3, 0.0))
	var textura := GradientTexture2D.new()
	textura.gradient = degradado
	textura.fill = GradientTexture2D.FILL_SQUARE
	textura.fill_from = Vector2(0.5, 0.5)
	textura.fill_to = Vector2(1.0, 0.5)
	_material_sombra = StandardMaterial3D.new()
	_material_sombra.albedo_texture = textura
	_material_sombra.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material_sombra.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_decoracion = Node3D.new()
	add_child(_decoracion)
	_piezas = Node3D.new()
	add_child(_piezas)
	_colocar_camara()


## Placa base con studs; `desde` y `tam` en unidades de stud (x, z).
func preparar_base(desde: Vector2i, tam: Vector2i, color := Estilo.COLOR_BASE) -> void:
	if _base:
		_base.queue_free()
	_base = Node3D.new()
	add_child(_base)
	var mat := _material(color)
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


# --- Ambientes -------------------------------------------------------------------

## Prepara el mundo: cielo, luces, suelo, neblina, placa base y decoración.
## `zona` es el rectángulo (en studs) donde se construye, que queda libre.
func preparar_ambiente(mundo: Dictionary, desde: Vector2i, tam: Vector2i, zona: Rect2i) -> void:
	var cielo := ProceduralSkyMaterial.new()
	cielo.sky_top_color = mundo.cielo_arriba
	cielo.sky_horizon_color = mundo.cielo_horizonte
	cielo.ground_horizon_color = mundo.cielo_horizonte
	cielo.ground_bottom_color = mundo.suelo
	cielo.sky_curve = 0.12
	var sky := Sky.new()
	sky.sky_material = cielo
	_env.background_mode = Environment.BG_SKY
	_env.sky = sky
	_env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	_env.ambient_light_color = mundo.ambiente
	_env.ambient_light_energy = mundo.ambiente_energia
	# Neblina sólo a lo lejos, para fundir el suelo con el horizonte.
	_env.fog_enabled = true
	_env.fog_mode = Environment.FOG_MODE_DEPTH
	_env.fog_light_color = mundo.cielo_horizonte
	_env.fog_density = 1.0
	_env.fog_depth_begin = 24.0
	_env.fog_depth_end = 85.0
	_env.fog_depth_curve = 1.0
	_env.fog_sky_affect = 0.0
	_sol.light_color = mundo.luz
	_sol.light_energy = mundo.luz_energia

	for hijo in _decoracion.get_children():
		hijo.queue_free()
	var suelo := MeshInstance3D.new()
	var plano := PlaneMesh.new()
	plano.size = Vector2(320, 320)
	suelo.mesh = plano
	var mat_suelo := StandardMaterial3D.new()
	mat_suelo.albedo_color = mundo.suelo
	mat_suelo.roughness = 1.0
	suelo.material_override = mat_suelo
	suelo.position = Vector3(desde.x + tam.x / 2.0, -0.2, desde.y + tam.y / 2.0)
	_decoracion.add_child(suelo)
	preparar_base(desde, tam, mundo.base)

	var rng := RandomNumberGenerator.new()
	rng.seed = hash(mundo.nombre)
	match mundo.decoracion:
		"pradera":
			_pradera(desde, tam, zona, rng)
		"dunas":
			_dunas(desde, tam, zona, rng)
		"luna":
			_luna(desde, tam, zona, rng)


## Pieza decorativa (misma geometría que las del juego).
func _bloque(x: float, y: float, z: float, tam: Vector2i, alto: float, color: Color, studs := true, brillo := false) -> void:
	var pieza := _crear_pieza({"pos": Vector3(x, y, z), "tam": tam, "alto": alto, "color": color, "studs": studs})
	if brillo:
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		for hijo in pieza.get_children():
			hijo.material_override = m
	_decoracion.add_child(pieza)


## Celdas libres del borde de la placa (fuera de la zona de construcción y su margen).
## Con `detras`, sólo las del lado opuesto a la cámara, para que lo alto no tape.
func _celdas_borde(desde: Vector2i, tam: Vector2i, zona: Rect2i, lado: int, detras := false) -> Array:
	var libre := zona.grow(4 if detras else 2)
	var centro := Vector2(zona.get_center())
	var hacia_camara := Vector2(sin(_yaw), cos(_yaw))
	var celdas := []
	for x in range(desde.x, desde.x + tam.x - lado + 1):
		for z in range(desde.y, desde.y + tam.y - lado + 1):
			if Rect2i(x, z, lado, lado).intersects(libre):
				continue
			if detras and (Vector2(x + lado / 2.0, z + lado / 2.0) - centro).dot(hacia_camara) > -1.0:
				continue
			celdas.append(Vector2i(x, z))
	return celdas


func _sacar(celdas: Array, rng: RandomNumberGenerator, lado: int, ocupadas: Array) -> Vector2i:
	if celdas.is_empty():
		return Vector2i(-999, -999)
	for intento in 40:
		var c: Vector2i = celdas[rng.randi_range(0, celdas.size() - 1)]
		var r := Rect2i(c.x, c.y, lado, lado)
		var choca := false
		for o in ocupadas:
			choca = choca or r.intersects(o.grow(1))
		if not choca:
			ocupadas.append(r)
			return c
	return Vector2i(-999, -999)


func _pradera(desde: Vector2i, tam: Vector2i, zona: Rect2i, rng: RandomNumberGenerator) -> void:
	var ocupadas := []
	# Casa en la esquina del fondo.
	var casa := Vector2i(desde.x + 1, desde.y + 1)
	ocupadas.append(Rect2i(casa.x, casa.y, 4, 4))
	_bloque(casa.x, 0, casa.y, Vector2i(4, 4), ALTO_LADRILLO * 2, Color("f4f1ea"), false)
	_bloque(casa.x + 1, 0, casa.y + 4 - 0.02, Vector2i(1, 1), ALTO_LADRILLO * 1.4, Color("8b5a2b"), false)
	_bloque(casa.x - 0.25, ALTO_LADRILLO * 2, casa.y - 0.25, Vector2i(4, 4), ALTO_PLACA, Color("ef4136"))
	_bloque(casa.x + 0.75, ALTO_LADRILLO * 2 + ALTO_PLACA, casa.y + 0.75, Vector2i(2, 2), ALTO_LADRILLO * 0.6, Color("ef4136"))
	# Árboles.
	for i in 4:
		var c := _sacar(_celdas_borde(desde, tam, zona, 3, true), rng, 3, ocupadas)
		if c.x < -900:
			continue
		var tronco := Color("8b5a2b")
		_bloque(c.x + 1, 0, c.y + 1, Vector2i(1, 1), ALTO_LADRILLO, tronco, false)
		_bloque(c.x + 1, ALTO_LADRILLO, c.y + 1, Vector2i(1, 1), ALTO_LADRILLO, tronco, false)
		_bloque(c.x, ALTO_LADRILLO * 2, c.y, Vector2i(3, 3), ALTO_LADRILLO, Color("2e9e4f"), false)
		_bloque(c.x + 1, ALTO_LADRILLO * 3, c.y + 1, Vector2i(1, 1), ALTO_LADRILLO * 0.8, Color("3cb860"))
	# Flores y arbustos.
	var colores := [Color("ef4136"), Color("ffc531"), Color("ffffff"), Color("ff7eb6")]
	for i in 10:
		var c := _sacar(_celdas_borde(desde, tam, zona, 1), rng, 1, ocupadas)
		if c.x > -900:
			_bloque(c.x, 0, c.y, Vector2i(1, 1), ALTO_PLACA, colores[i % colores.size()])
	for i in 3:
		var c := _sacar(_celdas_borde(desde, tam, zona, 2, true), rng, 2, ocupadas)
		if c.x > -900:
			_bloque(c.x, 0, c.y, Vector2i(2, 2), ALTO_LADRILLO * 0.7, Color("37a95a"))
	# Nubes de ladrillos.
	for i in 5:
		var ang := rng.randf_range(-PI, PI * 0.2)
		var r := rng.randf_range(45, 70)
		var cx := cos(ang) * r
		var cz := sin(ang) * r
		var y := rng.randf_range(16, 24)
		_bloque(cx, y, cz, Vector2i(6, 3), ALTO_LADRILLO * 1.2, Color.WHITE, false, true)
		_bloque(cx + 1.5, y + 1.4, cz + 0.5, Vector2i(3, 2), ALTO_LADRILLO, Color.WHITE, false, true)


func _dunas(desde: Vector2i, tam: Vector2i, zona: Rect2i, rng: RandomNumberGenerator) -> void:
	var ocupadas := []
	# Pirámide escalonada en la esquina del fondo.
	var p := Vector2i(desde.x, desde.y)
	ocupadas.append(Rect2i(p.x, p.y, 5, 5))
	var arena := Color("e0b467")
	_bloque(p.x, 0, p.y, Vector2i(5, 5), ALTO_LADRILLO, arena, false)
	_bloque(p.x + 1, ALTO_LADRILLO, p.y + 1, Vector2i(3, 3), ALTO_LADRILLO, arena.darkened(0.05), false)
	_bloque(p.x + 2, ALTO_LADRILLO * 2, p.y + 2, Vector2i(1, 1), ALTO_LADRILLO, Color("ffc531"))
	# Cactus.
	var verde := Color("2f9e44")
	for i in 4:
		var c := _sacar(_celdas_borde(desde, tam, zona, 3, true), rng, 3, ocupadas)
		if c.x < -900:
			continue
		var x := c.x + 1
		var z := c.y + 1
		var alto := rng.randi_range(3, 4)
		for n in alto:
			_bloque(x, n * ALTO_LADRILLO, z, Vector2i(1, 1), ALTO_LADRILLO, verde, n == alto - 1)
		_bloque(x - 1, ALTO_LADRILLO, z, Vector2i(1, 1), ALTO_LADRILLO, verde, false)
		_bloque(x - 1, ALTO_LADRILLO * 2, z, Vector2i(1, 1), ALTO_LADRILLO, verde)
		_bloque(x + 1, ALTO_LADRILLO * 1.5, z, Vector2i(1, 1), ALTO_LADRILLO, verde)
	# Rocas.
	for i in 6:
		var c := _sacar(_celdas_borde(desde, tam, zona, 2), rng, 2, ocupadas)
		if c.x > -900:
			_bloque(c.x, 0, c.y, Vector2i(2, 2), ALTO_PLACA * 2, Color("b08d63"))
	# Sol.
	var sol := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 7
	esfera.height = 14
	sol.mesh = esfera
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("fff1b0")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sol.material_override = mat
	sol.position = Vector3(-60, 34, -80)
	_decoracion.add_child(sol)


func _luna(desde: Vector2i, tam: Vector2i, zona: Rect2i, rng: RandomNumberGenerator) -> void:
	var ocupadas := []
	# Cohete en la esquina del fondo.
	var c := Vector2i(desde.x + 1, desde.y + 1)
	ocupadas.append(Rect2i(c.x - 1, c.y - 1, 4, 4))
	for n in 4:
		_bloque(c.x, n * ALTO_LADRILLO, c.y, Vector2i(2, 2), ALTO_LADRILLO, Color("f2f4fb") if n != 2 else Color("1f6feb"), false)
	_bloque(c.x, 4 * ALTO_LADRILLO, c.y, Vector2i(2, 2), ALTO_LADRILLO, Color("ef4136"))
	_bloque(c.x + 0.5, 5 * ALTO_LADRILLO + ALTO_STUD, c.y + 0.5, Vector2i(1, 1), ALTO_LADRILLO * 0.8, Color("ef4136"))
	for aleta in [Vector2(-1, 0.5), Vector2(2, 0.5), Vector2(0.5, -1), Vector2(0.5, 2)]:
		_bloque(c.x + aleta.x, 0, c.y + aleta.y, Vector2i(1, 1), ALTO_LADRILLO * 0.8, Color("ef4136"), false)
	# Antena.
	var a := _sacar(_celdas_borde(desde, tam, zona, 3, true), rng, 3, ocupadas)
	if a.x > -900:
		for n in 3:
			_bloque(a.x + 1, n * ALTO_LADRILLO, a.y + 1, Vector2i(1, 1), ALTO_LADRILLO, Color("e6e9f2"), false)
		_bloque(a.x, 3 * ALTO_LADRILLO, a.y, Vector2i(3, 3), ALTO_PLACA, Color("cfd5e6"))
		_bloque(a.x + 1, 3 * ALTO_LADRILLO + ALTO_PLACA, a.y + 1, Vector2i(1, 1), ALTO_PLACA, Color("ff5a4e"), false, true)
	# Cráteres y luces.
	for i in 5:
		var k := _sacar(_celdas_borde(desde, tam, zona, 3), rng, 3, ocupadas)
		if k.x > -900:
			_bloque(k.x, 0, k.y, Vector2i(3, 3), ALTO_PLACA, Color("7c8297"), false)
			_bloque(k.x + 1, ALTO_PLACA * 0.5, k.y + 1, Vector2i(1, 1), ALTO_PLACA * 0.6, Color("5d6378"), false)
	for i in 8:
		var l := _sacar(_celdas_borde(desde, tam, zona, 1), rng, 1, ocupadas)
		if l.x > -900:
			_bloque(l.x, 0, l.y, Vector2i(1, 1), ALTO_PLACA, Color("5ee7ff"), false, true)
	# Estrellas en el cielo.
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var punto := BoxMesh.new()
	punto.size = Vector3(0.35, 0.35, 0.35)
	mm.mesh = punto
	mm.instance_count = 260
	for i in mm.instance_count:
		var dir := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.12, 1), rng.randf_range(-1, 1)).normalized()
		var esc := rng.randf_range(0.6, 1.6)
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * esc), dir * 120))
	var estrellas := MultiMeshInstance3D.new()
	estrellas.multimesh = mm
	var blanco := StandardMaterial3D.new()
	blanco.albedo_color = Color.WHITE
	blanco.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	blanco.disable_fog = true
	estrellas.material_override = blanco
	_decoracion.add_child(estrellas)
	# La Tierra a lo lejos.
	var tierra := MeshInstance3D.new()
	var esfera := SphereMesh.new()
	esfera.radius = 9
	esfera.height = 18
	tierra.mesh = esfera
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("3d7bff")
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.disable_fog = true
	tierra.material_override = mat
	tierra.position = Vector3(-55, 38, -85)
	_decoracion.add_child(tierra)


# --- Piezas del juego ------------------------------------------------------------

## Dibuja la lista de piezas. Cada pieza es un diccionario:
## {pos: Vector3 esquina inferior, tam: Vector2i, alto: float, color: Color,
##  fantasma: bool (transparente), studs: bool, margen: float, sombra: bool}.
## La pieza en la posición `animar` cae desde arriba.
func mostrar(lista: Array, animar := -1) -> void:
	for hijo in _piezas.get_children():
		hijo.queue_free()
	for d in lista:
		if not d.get("fantasma", false) and (d.pos.y < 0.01 or d.get("sombra", false)):
			_piezas.add_child(_sombra(d))
	for i in lista.size():
		var pieza := _crear_pieza(lista[i])
		_piezas.add_child(pieza)
		if i == animar:
			var destino := pieza.position
			pieza.position.y += 2.5
			var tw := pieza.create_tween()
			tw.tween_property(pieza, "position", destino, 0.35).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Sombra difusa sobre la placa base, un poco más grande que la huella de la pieza.
func _sombra(d: Dictionary) -> MeshInstance3D:
	var tam: Vector2i = d.tam
	var plano := PlaneMesh.new()
	plano.size = Vector2(tam.x + 1.4, tam.y + 1.4)
	var sombra := MeshInstance3D.new()
	sombra.mesh = plano
	sombra.material_override = _material_sombra
	sombra.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	sombra.position = Vector3(d.pos.x + tam.x / 2.0, 0.012, d.pos.z + tam.y / 2.0)
	return sombra


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
		m.roughness = 0.38
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
