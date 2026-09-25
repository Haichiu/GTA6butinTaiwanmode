extends LevelBase
## Level 7 — 後龍死亡彎 (after the 台61 西濱 scooter lane near 龍港, see docs/laws.md).
## Cars get a straight expressway. Scooters are split off onto a side lane that, after a long
## straight, throws a sudden 180° hairpin, runs back the way you came, and hairpins again —
## with gravel on the bends. The expressway is right there, and the GPS says go straight.

const CAR_W := 7.0  # expressway: 2 lanes each way, x in [-7, 7]
const LANE_W := 3.5
const L0_X := 11.25  # scooter lane centerline before the hairpins (heading north)
const H1 := Vector2(17.0, -120.0)  # first hairpin center (right turn, north -> south)
const H2 := Vector2(28.5, -80.0)  # second hairpin center (left turn, south -> north)
const R := 5.75  # lane centerline radius on both hairpins
const L1_X := 22.75  # the short stretch back south
const L2_X := 34.25  # scooter lane after the hairpins (heading north)
const Z_END := -340.0
const GRAVEL := Color(0.55, 0.5, 0.42)


func _init() -> void:
	title = "後龍死亡彎"
	who = "大學生・週五 17:40"
	objective = "週五沒課，沿著西濱騎回家過週末。媽媽說今晚滷了一鍋肉。\n導航：「沿著西濱一直直走就到了。」"
	deadline = 60.0
	deadline_name = "滷肉上桌"
	place = "家"
	waiting_person = true
	ending = "媽媽：「回來啦！怎麼一身砂？」"
	late_ending = "媽媽：「滷肉都涼了……西濱又怎麼了？」"


func spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(L0_X, 0.1, 40.0))


func build() -> void:
	# Expressway for cars.
	K.surface(self, Vector2(-CAR_W, Z_END), Vector2(CAR_W, 60.0))
	lines_ns([-6.7, -3.5, 0.0, 3.5, 6.7], ["edge", "dash", "yellow2", "dash", "edge"], 60.0, Z_END)
	sign_board("台61 西濱快速公路", Vector3(-CAR_W - 1.5, 0, 20.0), 0.0, Color(0.1, 0.45, 0.25), 3.0)
	# Scooter lane: straight, then the hairpins.
	var l0_min := L0_X - LANE_W / 2.0
	var l0_max := L0_X + LANE_W / 2.0
	K.surface(self, Vector2(l0_min, H1.y), Vector2(l0_max, 60.0))
	K.arc_surface(self, H1, R - LANE_W / 2.0, R + LANE_W / 2.0, PI, TAU)
	K.surface(self, Vector2(L1_X - LANE_W / 2.0, H1.y), Vector2(L1_X + LANE_W / 2.0, H2.y))
	K.arc_surface(self, H2, R - LANE_W / 2.0, R + LANE_W / 2.0, PI, 0.0)
	K.surface(self, Vector2(L2_X - LANE_W / 2.0, Z_END), Vector2(L2_X + LANE_W / 2.0, H2.y))
	# Edge lines along the whole scooter route.
	for side in [-1.0, 1.0]:
		var off: float = side * (LANE_W / 2.0 - 0.3)
		K.line(self, Vector2(L0_X + off, 60.0), Vector2(L0_X + off, H1.y))
		K.arc_line(self, H1, R - off, PI, TAU)
		K.line(self, Vector2(L1_X - off, H1.y), Vector2(L1_X - off, H2.y))
		K.arc_line(self, H2, R - off, PI, 0.0)
		K.line(self, Vector2(L2_X + off, H2.y), Vector2(L2_X + off, Z_END))
	for z in [30.0, -40.0]:
		K.ground_text(self, "機\n車", Vector2(L0_X, z), K.WHITE, 0.0, 0.008)
	K.ground_text(self, "慢", Vector2(L0_X, -95.0), K.WHITE, 0.0, 0.012)
	# Divider between the expressway and the scooter lane, with a gap right before the bends.
	K.rail(self, Vector2(8.3, 60.0), Vector2(8.3, -95.0))
	# Guardrails on the outside of both hairpins and along the stretch back.
	K.arc_rail(self, H1, R + LANE_W / 2.0 + 0.3, PI + 0.15, TAU)
	K.arc_rail(self, H2, R + LANE_W / 2.0 + 0.3, PI, 0.0)
	K.rail(self, Vector2(L1_X + LANE_W / 2.0 + 0.3, H1.y), Vector2(L1_X + LANE_W / 2.0 + 0.3, H2.y))
	# Gravel and puddles on the bends.
	var rng := RandomNumberGenerator.new()
	rng.seed = 61  # same gravel every run
	for h in [H1, H2]:
		for i in 40:
			# H1 bends through the north half of its circle (PI..TAU), H2 through the south half (0..PI).
			var a := rng.randf_range(0.2, PI - 0.2) + (PI if h == H1 else 0.0)
			var p := K.on_arc(h, rng.randf_range(R - 1.4, R + 1.4), a)
			K.box(self, Vector3(0.18, 0.05, 0.18), Vector3(p.x, 0.05, p.y), GRAVEL)
	var puddle := K.box(self, Vector3(2.2, 0.02, 1.4), Vector3(H1.x, 0.045, H1.y - R), Color(0.3, 0.45, 0.6))
	puddle.rotation.y = 0.3
	sign_board("機車道\n前方急彎", Vector3(l0_max + 1.2, 0, -70.0), 0.0, Color(0.9, 0.75, 0.1), 2.2)
	buildings_ns(L2_X + 16.0, Z_END, -150.0, -1)
	_add_rules()


func _add_rules() -> void:
	ViolationZone.make(self, Vector2(-CAR_W, Z_END), Vector2(CAR_W + 0.6, 60.0), "expressway_scooter", "oncoming_truck,car_speeding",
		"機車騎上快速公路 4,000。汽車在這裡一路直走；機車被分流到旁邊，直線接 180 度髮夾彎——網友說 MotoGP 都不敢這樣設計。")
	# Gravel: the front wheel washes out on both bends.
	for h in [H1, H2]:
		var zmin: float = h.y - R - LANE_W if h == H1 else h.y
		var zmax: float = h.y if h == H1 else h.y + R + LANE_W
		var area := Area3D.new()
		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.0 * (R + LANE_W), 3.0, zmax - zmin)
		shape.shape = box
		area.add_child(shape)
		area.position = Vector3(h.x, 1.5, (zmin + zmax) / 2.0)
		area.body_entered.connect(func(b: Node3D) -> void:
			if b is Scooter:
				(b as Scooter).grip = 0.5)
		area.body_exited.connect(func(b: Node3D) -> void:
			if b is Scooter:
				(b as Scooter).grip = 1.0)
		add_child(area)
	goal(Vector2(L2_X - LANE_W / 2.0, -300.0), Vector2(L2_X + LANE_W / 2.0, -290.0))
	gps = [Vector3(4.0, 0, -300.0)]
	on_enter(Vector2(L0_X - 3.0, H1.y - 8.0), Vector2(H1.x + 8.0, H1.y), func() -> void:
		gps = [Vector3(L1_X, 0, H2.y), Vector3(L2_X, 0, H2.y - 10.0), Vector3(L2_X, 0, -295.0)]
		_gps_index = 0
		toast("導航：……怎麼開始往回走了？"))
	traffic([Vector3(1.75, 0, 80.0), Vector3(1.75, 0, Z_END)] as Array[Vector3], 20.0, 3.5)
	traffic([Vector3(5.25, 0, 80.0), Vector3(5.25, 0, Z_END)] as Array[Vector3], 18.0, 5.0, Callable(), 1.5)
	traffic([Vector3(-3.5, 0, Z_END), Vector3(-3.5, 0, 80.0)] as Array[Vector3], 20.0, 4.0)


func after_spawn() -> void:
	scooter.hit_rail.connect(func(impact: float) -> void:
		if impact > 6.0:
			fail("自摔。路邊一地的機車零件，現在又多了你的。"))
