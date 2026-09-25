class_name StreetDressing
## Taiwanese street furniture along a north–south sidewalk: curb paint, trees, power poles with
## wires, rows of parked scooters, and vertical shop signs on the building fronts.
## Purely visual except the parked scooters (you'd be on the sidewalk anyway).

const K = preload("res://scripts/road_kit.gd")
const SHOPS := ["牙醫", "補習班", "當舖", "檳榔", "機車行", "早餐", "中醫", "美髮", "藥局", "水電行",
	"便當", "卡拉ＯＫ", "眼鏡", "銀樓", "麵店", "五金"]
const SIGN_COLORS := [Color(0.85, 0.15, 0.15), Color(0.1, 0.35, 0.75), Color(0.95, 0.75, 0.1),
	Color(0.1, 0.55, 0.3), Color(0.55, 0.15, 0.6), Color(0.95, 0.45, 0.1)]
const SCOOTER_COLORS := [Color(0.9, 0.9, 0.92), Color(0.15, 0.15, 0.18), Color(0.8, 0.2, 0.2),
	Color(0.3, 0.5, 0.85), Color(0.95, 0.85, 0.3), Color(0.45, 0.7, 0.5)]


## Dress one side of a north–south road between z0 and z1.
## curb_x: road edge; side: +1 if the sidewalk lies east of the curb, -1 if west.
## walk: sidewalk width. skip: array of [z_from, z_to] ranges to keep clear (junctions).
static func ns_side(parent: Node3D, curb_x: float, z0: float, z1: float, side: int, walk := 4.0, skip := [], seed := 0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([curb_x, z0, z1, seed])
	var zmin := minf(z0, z1)
	var zmax := maxf(z0, z1)
	var clear := func(z: float, margin := 3.0) -> bool:
		for r in skip:
			if z > minf(r[0], r[1]) - margin and z < maxf(r[0], r[1]) + margin:
				return false
		return true
	# Red curb (no stopping) near junctions, yellow elsewhere.
	var paint_x := curb_x + side * 0.1
	var z := zmin
	while z < zmax:
		var next := minf(z + 6.0, zmax)
		var mid := (z + next) / 2.0
		if clear.call(mid, 0.0):
			var near_junction: bool = not clear.call(mid, 15.0)
			K.line(parent, Vector2(paint_x, z), Vector2(paint_x, next), K.RED if near_junction else K.YELLOW, 0.15)
		z = next
	# Trees and power poles along the outer edge of the sidewalk, wires between the poles.
	var pole_x := curb_x + side * 0.6
	var last_pole := Vector3.INF
	z = zmin + 5.0
	while z < zmax - 3.0:
		if clear.call(z):
			_pole(parent, Vector3(pole_x, 0, z))
			var top := Vector3(pole_x, 7.2, z)
			if last_pole != Vector3.INF:
				_wire(parent, last_pole, top)
				_wire(parent, last_pole + Vector3(side * 0.5, -0.5, 0), top + Vector3(side * 0.5, -0.5, 0))
			last_pole = top
		else:
			last_pole = Vector3.INF
		z += 28.0
	z = zmin + 14.0
	while z < zmax - 3.0:
		if clear.call(z):
			_tree(parent, Vector3(curb_x + side * 1.4, 0, z), rng.randf_range(0.85, 1.2))
		z += 28.0
	# Parked scooters in rows near the building line.
	var row_x := curb_x + side * (walk - 0.9)
	z = zmin + 3.0
	while z < zmax - 3.0:
		var run := rng.randi_range(4, 9)
		for i in run:
			var zz := z + i * 0.85
			if zz > zmax - 2.0 or not clear.call(zz):
				break
			_parked_scooter(parent, Vector3(row_x, 0, zz), side, SCOOTER_COLORS[rng.randi() % SCOOTER_COLORS.size()])
		z += run * 0.85 + rng.randf_range(6.0, 14.0)
	# Vertical shop signs sticking out from the building fronts.
	var sign_x := curb_x + side * (walk + 1.2)
	z = zmin + 6.0
	while z < zmax - 4.0:
		if clear.call(z):
			_shop_sign(parent, Vector3(sign_x, 0, z), side, SHOPS[rng.randi() % SHOPS.size()],
				SIGN_COLORS[rng.randi() % SIGN_COLORS.size()], rng.randf_range(3.5, 6.0))
		z += rng.randf_range(7.0, 13.0)


static func _pole(parent: Node3D, pos: Vector3) -> void:
	var grey := Color(0.62, 0.62, 0.6)
	K.box(parent, Vector3(0.25, 7.5, 0.25), pos + Vector3(0, 3.75, 0), grey)
	K.box(parent, Vector3(1.4, 0.12, 0.12), pos + Vector3(0, 7.2, 0), grey)
	K.box(parent, Vector3(0.5, 0.7, 0.5), pos + Vector3(0, 6.2, 0.25), Color(0.4, 0.42, 0.4))  # transformer


static func _wire(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var mid := (a + b) / 2.0 + Vector3(0, -0.4, 0)  # a little sag
	for seg in [[a, mid], [mid, b]]:
		var d: Vector3 = seg[1] - seg[0]
		var mi := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.03, 0.03, d.length())
		m.material = K.material(Color(0.1, 0.1, 0.1))
		mi.mesh = m
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(mi)
		mi.global_position = (seg[0] + seg[1]) / 2.0
		if d.length() > 0.01:
			mi.look_at(seg[1], Vector3.UP)


static func _tree(parent: Node3D, pos: Vector3, s: float) -> void:
	K.box(parent, Vector3(0.3, 2.6, 0.3) * s, pos + Vector3(0, 1.3 * s, 0), Color(0.4, 0.28, 0.18))
	var crown := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.6 * s
	sphere.height = 2.8 * s
	sphere.material = K.material(Color(0.25, 0.5, 0.25))
	crown.mesh = sphere
	crown.position = pos + Vector3(0, 3.4 * s, 0)
	parent.add_child(crown)


## A parked scooter, nose toward the building (the usual way they're lined up).
static func _parked_scooter(parent: Node3D, pos: Vector3, side: int, color: Color) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = PI / 2.0 * side
	K.box(root, Vector3(0.45, 0.55, 1.5), Vector3(0, 0.45, 0), color)
	K.box(root, Vector3(0.5, 0.12, 0.6), Vector3(0, 0.8, 0.25), Color(0.1, 0.1, 0.1))
	K.box(root, Vector3(0.55, 0.06, 0.06), Vector3(0, 1.0, -0.6), Color(0.1, 0.1, 0.1))
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(0.5, 1.0, 1.6)
	shape.shape = b
	shape.position.y = 0.5
	body.add_child(shape)
	root.add_child(body)
	parent.add_child(root)


static func _shop_sign(parent: Node3D, pos: Vector3, side: int, text: String, color: Color, height: float) -> void:
	var chars := text.length()
	var h := chars * 0.55 + 0.4
	var sign := Node3D.new()
	sign.position = pos + Vector3(0, height, 0)
	parent.add_child(sign)
	K.box(sign, Vector3(0.12, h, 0.75), Vector3(0, h / 2.0, 0), color)
	for face in [-1, 1]:
		var label := Label3D.new()
		label.text = "\n".join(text.split(""))
		label.font = K.font()
		label.font_size = 96
		label.pixel_size = 0.005
		label.modulate = Color.WHITE
		label.position = Vector3(face * 0.07, h / 2.0, 0)
		label.rotation.y = PI / 2.0 * face
		sign.add_child(label)
