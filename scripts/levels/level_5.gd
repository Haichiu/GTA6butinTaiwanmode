extends LevelBase
## Level 5 — 橋上分流 (after Geomeme's 橋樑車道設計: 橋下混流，橋上分流).
## On the bridge the main lanes become 禁行機車 and scooters are squeezed into a narrow strip
## next to the barrier — shared with slow cyclists. Overtaking means entering the main lanes.

const HALF := 7.0  # 2 lanes each way below the bridge
const BRIDGE_START := -30.0
const BRIDGE_END := -230.0
const STRIP_MIN := 7.3  # scooter strip on the bridge: x in [STRIP_MIN, STRIP_MAX]
const STRIP_MAX := 9.3
const WATER := Color(0.1, 0.24, 0.36)


func _init() -> void:
	title = "橋上分流"
	objective = "過橋去上班。橋上機車只能騎最右邊那一小條。"


func spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(5.25, 0.1, 40.0))


func build() -> void:
	# River under the bridge.
	K.surface(self, Vector2(-200.0, BRIDGE_END + 10.0), Vector2(200.0, BRIDGE_START - 10.0), WATER, 0.01)
	# Road below the bridge (both ends) and the bridge deck.
	K.surface(self, Vector2(-HALF, BRIDGE_START), Vector2(HALF, 60.0))
	K.surface(self, Vector2(-HALF, -300.0), Vector2(HALF, BRIDGE_END))
	K.surface(self, Vector2(-HALF, BRIDGE_END), Vector2(STRIP_MAX + 0.3, BRIDGE_START))
	# Short taper so riders can move over into the strip before the bridge starts.
	K.surface(self, Vector2(HALF, BRIDGE_START), Vector2(STRIP_MAX + 0.3, BRIDGE_START + 25.0))
	var xs := [-6.7, -3.5, 0.0, 3.5, 6.7]
	lines_ns(xs, ["edge", "dash", "yellow2", "dash", "edge"], 60.0, BRIDGE_START)
	lines_ns(xs, ["edge", "dash", "yellow2", "dash", "edge"], BRIDGE_END, -300.0)
	lines_ns([-6.7, -3.5, 0.0, 3.5], ["edge", "dash", "yellow2", "dash"], BRIDGE_START, BRIDGE_END)
	# Yellow-black hatched divider between the main lanes and the scooter strip.
	K.line(self, Vector2(7.1, BRIDGE_START), Vector2(7.1, BRIDGE_END), K.YELLOW, 0.3)
	var z := BRIDGE_START - 1.0
	while z > BRIDGE_END:
		K.box(self, Vector3(0.3, 0.03, 0.8), Vector3(7.1, 0.05, z), Color(0.1, 0.1, 0.1))
		z -= 2.0
	for zz in [-60.0, -130.0, -200.0]:
		for lane_x in [1.75, 5.25]:
			K.ground_text(self, "禁\n行\n機\n車", Vector2(lane_x, zz), K.YELLOW)
		K.ground_text(self, "機\n車", Vector2(8.3, zz + 20.0), K.WHITE, 0.0, 0.006)
	# Barriers along both bridge edges.
	for bx in [-HALF - 0.3, STRIP_MAX + 0.45]:
		K.box(self, Vector3(0.3, 1.1, BRIDGE_START - BRIDGE_END), Vector3(bx, 0.55, (BRIDGE_START + BRIDGE_END) / 2.0), Color(0.7, 0.7, 0.72), true)
	sign_board("前方無人行道\n請繞行對向人行道", Vector3(STRIP_MAX + 1.0, 0, BRIDGE_START + 8.0), 0.0, Color(0.8, 0.15, 0.15), 2.0)
	sign_board("公司", Vector3(HALF + 1.5, 0, -280.0), -PI / 2.0, Color(0.3, 0.3, 0.35), 2.5)
	buildings_ns(HALF + 12.0, 0.0, 60.0, -1)
	buildings_ns(-HALF - 12.0, 0.0, 60.0, 1)
	buildings_ns(HALF + 12.0, -300.0, BRIDGE_END - 15.0, -1)

	_add_rules()
	gps = [Vector3(5.25, 0, -285.0)]


func after_spawn() -> void:
	# Two cyclists pedalling along the strip at ~13 km/h. Hitting one ends the run.
	for i in 2:
		var start_z := BRIDGE_START - 10.0 - i * 25.0
		var npc := NpcVehicle.make_custom(self, _cyclist(i), AABB(Vector3(-0.3, 0, -0.9), Vector3(0.6, 1.7, 1.8)),
			[Vector3(8.3, 0, start_z), Vector3(8.3, 0, BRIDGE_END - 40.0)] as Array[Vector3], 3.6)
		npc.touched.connect(func() -> void: fail("撞到腳踏車了。"))


func _cyclist(i: int) -> Node3D:
	var root := Node3D.new()
	var shirt: Color = [Color(0.9, 0.5, 0.1), Color(0.3, 0.4, 0.9)][i % 2]
	K.box(root, Vector3(0.08, 0.6, 1.5), Vector3(0, 0.45, 0), Color(0.1, 0.1, 0.1))
	K.box(root, Vector3(0.4, 0.6, 0.3), Vector3(0, 1.2, -0.1), shirt)
	K.box(root, Vector3(0.25, 0.25, 0.25), Vector3(0, 1.65, -0.15), Color(0.95, 0.8, 0.65))
	return root


func _add_rules() -> void:
	ViolationZone.make(self, Vector2(0.3, BRIDGE_END), Vector2(6.9, BRIDGE_START), "lane_ban", "oncoming_truck",
		"橋上超車閃進汽車道罰 600；聯結車跨雙黃線逆向，只開跨雙黃線的話罰 1,400。", Vector3.FORWARD)
	ViolationZone.make(self, Vector2(-HALF, -300.0), Vector2(-0.3, 60.0), "wrong_way")
	goal(Vector2(0.3, -290.0), Vector2(HALF, -280.0))
