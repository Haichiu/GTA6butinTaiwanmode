extends LevelBase
## Level 7 — 後龍死亡彎 (after the 台61 西濱 scooter lane near 龍港, see docs/laws.md).
## Cars get a straight expressway. Scooters are split off onto a side lane that, after a long
## straight, throws a sudden 180° hairpin, runs back the way you came, and hairpins again —
## with gravel on the bends. The expressway is right there, and the GPS says go straight.

const CAR_W := 7.0  # expressway: 2 lanes each way, x in [-7, 7]
const LANE_W := 3.5
const LANE_X := 11.25  # scooter lane centerline (heading north)
# The detour ("棒棒糖"): the straight lane between BLOCK_START and BLOCK_END is closed off with
# posts. You turn right, run east, go round a 180° hairpin, run back west, and turn right onto
# the very same lane again — ~55 m of loop to cover ~25 m of straight road.
const BLOCK_START := -100.0
const BLOCK_END := -124.0
const TURN_R := 6.0  # the two 90° bends
const LOOP_X := 25.0  # hairpin center x
const Z_END := -260.0
const GRAVEL := Color(0.55, 0.5, 0.42)

var truck_hit := false


func _init() -> void:
	title = "後龍死亡彎"
	who = "大學生・週五 17:40"
	objective = "週五沒課，沿著西濱騎回家過週末。媽媽說今晚滷了一鍋肉。\n導航：「沿著西濱一直直走就到了。」"
	deadline = 70.0
	deadline_name = "滷肉上桌"
	place = "家"
	waiting_person = true
	ending = "媽媽：「回來啦！怎麼一身砂？」"
	late_ending = "媽媽：「滷肉都涼了……西濱又怎麼了？」"


func spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(LANE_X, 0.1, 40.0))


## Centerline of the detour as (center, radius, a0, a1) arcs and straight pieces, in riding order.
func _pieces() -> Array:
	var z_out := BLOCK_START - TURN_R  # z of the eastbound leg
	var z_back := BLOCK_END + TURN_R  # z of the westbound leg
	return [
		["arc", Vector2(LANE_X + TURN_R, BLOCK_START), TURN_R, PI, 1.5 * PI],  # north -> east
		["line", Vector2(LANE_X + TURN_R, z_out), Vector2(LOOP_X, z_out)],
		["arc", Vector2(LOOP_X, (z_out + z_back) / 2.0), (z_out - z_back) / 2.0, 0.5 * PI, -0.5 * PI],  # east -> west (hairpin)
		["line", Vector2(LOOP_X, z_back), Vector2(LANE_X + TURN_R, z_back)],
		["arc", Vector2(LANE_X + TURN_R, BLOCK_END), TURN_R, 0.5 * PI, PI],  # west -> north
	]


func build() -> void:
	# Expressway for cars.
	K.surface(self, Vector2(-CAR_W, Z_END), Vector2(CAR_W, 60.0))
	lines_ns([-6.7, -3.5, 0.0, 3.5, 6.7], ["edge", "dash", "yellow2", "dash", "edge"], 60.0, Z_END)
	sign_board("台61 西濱快速公路", Vector3(-CAR_W - 1.5, 0, 20.0), 0.0, Color(0.1, 0.45, 0.25), 3.0)
	# The scooter lane runs straight the whole way; the middle bit is simply closed.
	var lmin := LANE_X - LANE_W / 2.0
	var lmax := LANE_X + LANE_W / 2.0
	K.surface(self, Vector2(lmin, Z_END), Vector2(lmax, 60.0))
	for side in [-1.0, 1.0]:
		var off: float = side * (LANE_W / 2.0 - 0.3)
		K.line(self, Vector2(LANE_X + off, 60.0), Vector2(LANE_X + off, Z_END))
	# Closed stretch: chevrons and posts.
	var z := BLOCK_START - 2.0
	while z > BLOCK_END + 2.0:
		K.line(self, Vector2(lmin + 0.3, z), Vector2(lmax - 0.3, z - 1.5), K.YELLOW, 0.3)
		z -= 2.5
	# The outer posts of the two bends already cross the lane; a few more down the middle make it plain.
	K.line_posts(self, Vector2(LANE_X, BLOCK_START - 7.0), Vector2(LANE_X, BLOCK_END + 7.0), 2.5)
	# Detour surface, edge lines and posts on both edges.
	for piece in _pieces():
		if piece[0] == "arc":
			K.arc_surface(self, piece[1], piece[2] - LANE_W / 2.0, piece[2] + LANE_W / 2.0, piece[3], piece[4])
			for side in [-1.0, 1.0]:
				K.arc_line(self, piece[1], piece[2] + side * (LANE_W / 2.0 - 0.3), piece[3], piece[4])
				K.arc_posts(self, piece[1], piece[2] + side * (LANE_W / 2.0 + 0.25), piece[3], piece[4])
		else:
			var a: Vector2 = piece[1]
			var b: Vector2 = piece[2]
			K.surface(self, Vector2(minf(a.x, b.x), a.y - LANE_W / 2.0), Vector2(maxf(a.x, b.x), a.y + LANE_W / 2.0))
			for side in [-1.0, 1.0]:
				K.line(self, Vector2(a.x, a.y + side * (LANE_W / 2.0 - 0.3)), Vector2(b.x, b.y + side * (LANE_W / 2.0 - 0.3)))
				K.line_posts(self, Vector2(a.x, a.y + side * (LANE_W / 2.0 + 0.25)), Vector2(b.x, b.y + side * (LANE_W / 2.0 + 0.25)))
	# Gravel on the bends.
	var rng := RandomNumberGenerator.new()
	rng.seed = 61
	for piece in _pieces():
		if piece[0] != "arc":
			continue
		for i in 28:
			var p := K.on_arc(piece[1], piece[2] + rng.randf_range(-1.3, 1.3), lerpf(piece[3], piece[4], rng.randf()))
			K.box(self, Vector3(0.18, 0.05, 0.18), Vector3(p.x, 0.05, p.y), GRAVEL)
	K.ground_text(self, "機\n車", Vector2(LANE_X, 20.0), K.WHITE, 0.0, 0.008)
	K.ground_text(self, "慢", Vector2(LANE_X, BLOCK_START + 14.0), K.WHITE, 0.0, 0.012)
	sign_board("機車道\n改道", Vector3(lmax + 1.2, 0, BLOCK_START + 25.0), 0.0, Color(0.9, 0.75, 0.1), 2.2)
	# Divider between expressway and scooter lane, with a gap right before the detour.
	K.rail(self, Vector2(8.3, 60.0), Vector2(8.3, BLOCK_START + 8.0))
	K.rail(self, Vector2(8.3, BLOCK_END - 2.0), Vector2(8.3, Z_END))
	buildings_ns(LOOP_X + 16.0, Z_END, -150.0, -1)
	_add_rules()


func _add_rules() -> void:
	ViolationZone.make(self, Vector2(-CAR_W, Z_END), Vector2(CAR_W + 0.6, 60.0), "expressway_scooter", "oncoming_truck,car_speeding",
		"機車騎上快速公路 4,000。明明直直走就到了，機車道卻要你出去繞一圈棒棒糖。")
	# Gravel: the front wheel washes out on the bends.
	for piece in _pieces():
		if piece[0] != "arc":
			continue
		var c: Vector2 = piece[1]
		var reach: float = piece[2] + LANE_W
		var area := Area3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.0 * reach, 3.0, 2.0 * reach)
		shape.shape = box
		area.add_child(shape)
		area.position = Vector3(c.x, 1.5, c.y)
		area.body_entered.connect(func(b: Node3D) -> void:
			if b is Scooter:
				(b as Scooter).grip = 0.5)
		area.body_exited.connect(func(b: Node3D) -> void:
			if b is Scooter:
				(b as Scooter).grip = 1.0)
		add_child(area)
	goal(Vector2(LANE_X - LANE_W / 2.0, -235.0), Vector2(LANE_X + LANE_W / 2.0, -225.0))
	gps = [Vector3(4.0, 0, -230.0)]
	on_enter(Vector2(LANE_X + 2.0, BLOCK_START - 8.0), Vector2(LANE_X + 8.0, BLOCK_START), func() -> void:
		gps = [Vector3(LOOP_X + 4.0, 0, (BLOCK_START + BLOCK_END) / 2.0), Vector3(LANE_X, 0, BLOCK_END - 8.0), Vector3(LANE_X, 0, -230.0)]
		_gps_index = 0
		toast("導航：……前面不是直直的嗎？"))
	traffic([Vector3(1.75, 0, 80.0), Vector3(1.75, 0, Z_END)] as Array[Vector3], 20.0, 3.5)
	traffic([Vector3(5.25, 0, 80.0), Vector3(5.25, 0, Z_END)] as Array[Vector3], 18.0, 5.0, Callable(), 1.5)
	traffic([Vector3(-3.5, 0, Z_END), Vector3(-3.5, 0, 80.0)] as Array[Vector3], 20.0, 4.0)


func after_spawn() -> void:
	scooter.hit_rail.connect(func(impact: float) -> void:
		if impact > 6.0:
			fail("自摔。撞倒一排棒棒糖，路邊的機車零件又多了你的。"))
	if not Game.ambient:
		return
	# Right after the detour: a jam of scooters crawling along the lane.
	for i in 6:
		var start_z := BLOCK_END - 10.0 - i * 4.5
		var rider := NpcVehicle.make_custom(self, _jam_scooter(i), AABB(Vector3(-0.35, 0, -0.9), Vector3(0.7, 1.8, 1.8)),
			[Vector3(LANE_X + (0.6 if i % 2 == 0 else -0.6), 0, start_z), Vector3(LANE_X, 0, -190.0)] as Array[Vector3], 2.2)
		rider.free_at_end = true  # the jam clears near the end
		rider.target = scooter
		rider.trigger_distance = 28.0
		rider.yields = false
		rider.touched.connect(func() -> void: toast("前面在塞車……（按喇叭也沒用）", 2.0))


func _jam_scooter(i: int) -> Node3D:
	var root := Node3D.new()
	var colors := [Color(0.9, 0.3, 0.3), Color(0.3, 0.5, 0.9), Color(0.95, 0.95, 0.95), Color(0.3, 0.7, 0.4)]
	K.box(root, Vector3(0.45, 0.5, 1.6), Vector3(0, 0.45, 0), colors[i % colors.size()])
	K.box(root, Vector3(0.45, 0.6, 0.3), Vector3(0, 1.1, -0.1), Color(0.25, 0.25, 0.3))
	K.box(root, Vector3(0.3, 0.3, 0.3), Vector3(0, 1.55, -0.1), Color(0.95, 0.85, 0.3))
	return root
