class_name RoadKit
## Procedural road building blocks. Units are meters; north is -Z.
## Everything sits in thin layers above y=0 to avoid z-fighting:
## ground 0, asphalt 0.02, paint 0.04, text 0.05.

const ASPHALT := Color(0.24, 0.24, 0.26)
const SIDEWALK := Color(0.42, 0.4, 0.38)
const WHITE := Color(0.95, 0.95, 0.92)
const YELLOW := Color(0.98, 0.8, 0.2)
const RED := Color(0.85, 0.2, 0.18)
const GRASS := Color(0.36, 0.5, 0.3)

const LANE_W := 3.5
const LINE_W := 0.15

static var _materials := {}
static var _font: FontFile


static func material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var m := StandardMaterial3D.new()
		m.albedo_color = color
		m.roughness = 0.9
		_materials[color] = m
	return _materials[color]


## Axis-aligned box centered at pos. With collide=true it also gets a static collider.
static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color, collide := false) -> Node3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh.material = material(color)
	mi.mesh = mesh
	if not collide:
		mi.position = pos
		parent.add_child(mi)
		return mi
	var body := StaticBody3D.new()
	body.position = pos
	var shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	shape.shape = box_shape
	body.add_child(mi)
	body.add_child(shape)
	parent.add_child(body)
	return body


## Flat rectangle of asphalt (or another surface color) covering [min_xz, max_xz].
static func surface(parent: Node3D, min_xz: Vector2, max_xz: Vector2, color := ASPHALT, y := 0.02) -> void:
	var size := max_xz - min_xz
	var center := (min_xz + max_xz) / 2.0
	box(parent, Vector3(size.x, 0.02, size.y), Vector3(center.x, y, center.y), color)


## Flat convex polygon on the ground (e.g. a lane taper). Points in xz, any winding.
static func polygon(parent: Node3D, points: PackedVector2Array, color := ASPHALT, y := 0.025) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_normal(Vector3.UP)
	for i in range(1, points.size() - 1):
		for p in [points[0], points[i], points[i + 1]]:
			st.add_vertex(Vector3(p.x, y, p.y))
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	var mat := material(color).duplicate()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # winding-agnostic
	mi.material_override = mat
	parent.add_child(mi)


## Painted line between two ground points. dash > 0 draws dashes of that length with equal gaps.
static func line(parent: Node3D, from: Vector2, to: Vector2, color := WHITE, width := LINE_W, dash := 0.0) -> void:
	var dir := to - from
	var length := dir.length()
	if length < 0.01:
		return
	var unit := dir / length
	var angle := atan2(unit.x, unit.y)
	var pieces: Array[Vector2] = []  # (start, end) distances along the line
	if dash <= 0.0:
		pieces.append(Vector2(0, length))
	else:
		var d := 0.0
		while d < length:
			pieces.append(Vector2(d, minf(d + dash, length)))
			d += dash * 2.0
	for p in pieces:
		var mid := from + unit * (p.x + p.y) / 2.0
		var seg := box(parent, Vector3(width, 0.02, p.y - p.x), Vector3(mid.x, 0.04, mid.y), color)
		seg.rotation.y = angle


## Zebra crossing: stripes run along `along` axis ("x" means the crossing spans west-east).
static func zebra(parent: Node3D, min_xz: Vector2, max_xz: Vector2, along := "x") -> void:
	var stripe := 0.5
	if along == "x":
		var x := min_xz.x + stripe / 2.0
		while x < max_xz.x:
			line(parent, Vector2(x, min_xz.y), Vector2(x, max_xz.y), WHITE, stripe)
			x += stripe * 2.0
	else:
		var z := min_xz.y + stripe / 2.0
		while z < max_xz.y:
			line(parent, Vector2(min_xz.x, z), Vector2(max_xz.x, z), WHITE, stripe)
			z += stripe * 2.0


## Outlined rectangle (待轉區 / 停等區 style boxes).
static func outline(parent: Node3D, min_xz: Vector2, max_xz: Vector2, color := WHITE, width := LINE_W) -> void:
	line(parent, Vector2(min_xz.x, min_xz.y), Vector2(max_xz.x, min_xz.y), color, width)
	line(parent, Vector2(min_xz.x, max_xz.y), Vector2(max_xz.x, max_xz.y), color, width)
	line(parent, Vector2(min_xz.x, min_xz.y), Vector2(min_xz.x, max_xz.y), color, width)
	line(parent, Vector2(max_xz.x, min_xz.y), Vector2(max_xz.x, max_xz.y), color, width)


## Text painted on the road. heading_y is the travel direction of the reader (0 = northbound).
## Vertical text is written top-to-bottom = far-to-near, like Taiwanese road markings.
static func ground_text(parent: Node3D, text: String, pos: Vector2, color := YELLOW, heading_y := 0.0, pixel := 0.012) -> void:
	var label := Label3D.new()
	label.text = text
	label.font = font()
	label.font_size = 160
	label.pixel_size = pixel
	label.modulate = color
	label.outline_size = 0
	label.shaded = true
	label.double_sided = false
	label.position = Vector3(pos.x, 0.05, pos.y)
	label.rotation = Vector3(-PI / 2.0, heading_y, 0)
	parent.add_child(label)


static func font() -> FontFile:
	if _font == null:
		_font = load("res://assets/fonts/NotoSansTC-Black.otf")
	return _font
