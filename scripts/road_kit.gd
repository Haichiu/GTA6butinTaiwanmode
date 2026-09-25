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
## Triangles are emitted clockwise as seen from above (Godot's front face), so the surface is lit
## exactly like the box-based asphalt around it instead of rendering as a dark back face.
static func polygon(parent: Node3D, points: PackedVector2Array, color := ASPHALT, y := 0.03) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(1, points.size() - 1):
		var a := Vector3(points[0].x, y, points[0].y)
		var b := Vector3(points[i].x, y, points[i].y)
		var c := Vector3(points[i + 1].x, y, points[i + 1].y)
		if (b - a).cross(c - a).y > 0.0:
			var t := b
			b = c
			c = t
		for v in [a, b, c]:
			st.set_normal(Vector3.UP)
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = material(color)
	parent.add_child(mi)


## Point on a circle in the ground plane (angle 0 = +x, PI/2 = +z).
static func on_arc(center: Vector2, radius: float, angle: float) -> Vector2:
	return center + Vector2(cos(angle), sin(angle)) * radius


## Curved road surface: a ring sector between radii r_in..r_out from angle a0 to a1.
static func arc_surface(parent: Node3D, center: Vector2, r_in: float, r_out: float, a0: float, a1: float, color := ASPHALT) -> void:
	var steps := maxi(4, ceili(absf(a1 - a0) * r_out / 1.5))
	for i in steps:
		var t0 := lerpf(a0, a1, float(i) / steps)
		var t1 := lerpf(a0, a1, float(i + 1) / steps)
		polygon(parent, PackedVector2Array([on_arc(center, r_in, t0), on_arc(center, r_out, t0),
			on_arc(center, r_out, t1), on_arc(center, r_in, t1)]), color)


## Painted line along an arc (chords short enough to look curved).
static func arc_line(parent: Node3D, center: Vector2, radius: float, a0: float, a1: float, color := WHITE, width := LINE_W) -> void:
	var steps := maxi(4, ceili(absf(a1 - a0) * radius / 1.0))
	for i in steps:
		line(parent, on_arc(center, radius, lerpf(a0, a1, float(i) / steps)),
			on_arc(center, radius, lerpf(a0, a1, float(i + 1) / steps)), color, width)


## Guardrail along an arc: short solid segments you can crash into.
static func arc_rail(parent: Node3D, center: Vector2, radius: float, a0: float, a1: float) -> void:
	var steps := maxi(4, ceili(absf(a1 - a0) * radius / 1.2))
	for i in steps:
		var p0 := on_arc(center, radius, lerpf(a0, a1, float(i) / steps))
		var p1 := on_arc(center, radius, lerpf(a0, a1, float(i + 1) / steps))
		rail(parent, p0, p1)


## Delineator post (a.k.a. 「棒棒糖」): thin pole with a round reflector disc on top.
## Solid, and in the "guardrail" group so hitting one fast counts as a crash.
static func post(parent: Node3D, pos: Vector2) -> void:
	var body := StaticBody3D.new()
	body.position = Vector3(pos.x, 0, pos.y)
	body.add_to_group("guardrail")
	box(body, Vector3(0.08, 0.95, 0.08), Vector3(0, 0.475, 0), WHITE)
	var disc := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.16
	cyl.bottom_radius = 0.16
	cyl.height = 0.03
	cyl.material = material(RED)
	disc.mesh = cyl
	disc.rotation.x = PI / 2.0
	disc.position = Vector3(0, 1.05, 0)
	body.add_child(disc)
	var dot := MeshInstance3D.new()
	var inner := CylinderMesh.new()
	inner.top_radius = 0.07
	inner.bottom_radius = 0.07
	inner.height = 0.035
	inner.material = material(WHITE)
	dot.mesh = inner
	dot.rotation.x = PI / 2.0
	dot.position = Vector3(0, 1.05, 0)
	body.add_child(dot)
	var shape := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(0.2, 1.2, 0.2)
	shape.shape = b
	shape.position.y = 0.6
	body.add_child(shape)
	parent.add_child(body)


## Posts along an arc / a straight line, `spacing` meters apart.
static func arc_posts(parent: Node3D, center: Vector2, radius: float, a0: float, a1: float, spacing := 1.6) -> void:
	var steps := maxi(2, ceili(absf(a1 - a0) * radius / spacing))
	for i in steps + 1:
		post(parent, on_arc(center, radius, lerpf(a0, a1, float(i) / steps)))


static func line_posts(parent: Node3D, from: Vector2, to: Vector2, spacing := 1.6) -> void:
	var steps := maxi(1, ceili(from.distance_to(to) / spacing))
	for i in steps + 1:
		post(parent, from.lerp(to, float(i) / steps))


## Straight guardrail segment with collision.
static func rail(parent: Node3D, from: Vector2, to: Vector2) -> void:
	var d := to - from
	var mid := (from + to) / 2.0
	var r := box(parent, Vector3(0.25, 0.9, d.length() + 0.05), Vector3(mid.x, 0.45, mid.y), Color(0.75, 0.75, 0.78), true)
	r.rotation.y = atan2(d.x, d.y)
	r.add_to_group("guardrail")


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
