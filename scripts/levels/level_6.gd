extends LevelBase
## Level 5 — 橋上分流 (after Geomeme's 橋樑車道設計: 橋下混流，橋上分流).
## On the bridge the main lanes become 禁行機車 and scooters are squeezed into a narrow strip
## next to the barrier — shared with slow cyclists. Overtaking means entering the main lanes.

const HALF := 7.0  # 2 lanes each way below the bridge
const BRIDGE_START := -30.0
const BRIDGE_END := -190.0
const STRIP_MIN := 7.3  # scooter strip on the bridge: x in [STRIP_MIN, STRIP_MAX]
const STRIP_MAX := 9.3
const WATER := Color(0.1, 0.24, 0.36)


func _init() -> void:
	title = "橋上分流"
	who = "下班族・18:40"
	objective = "巷口便當店的排骨便當剛買好，過橋就到家了。今晚想邊吃邊追劇。"
	deadline = 55.0
	deadline_name = "便當變涼"
	place = "家"
	waiting_person = false
	ending = "打開便當，排骨還是熱的。\n劇剛好開播。"
	late_ending = "便當涼了。\n劇也演完了。"


func spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(5.25, 0.1, 40.0))


func build() -> void:
	# River under the bridge.
	K.surface(self, Vector2(-200.0, BRIDGE_END + 10.0), Vector2(200.0, BRIDGE_START - 10.0), WATER, 0.01)
	# Road below the bridge (both ends) and the bridge deck.
	K.surface(self, Vector2(-HALF, BRIDGE_START), Vector2(HALF, 60.0))
	K.surface(self, Vector2(-HALF, -300.0), Vector2(HALF, BRIDGE_END))
	K.surface(self, Vector2(-HALF, BRIDGE_END), Vector2(STRIP_MAX + 0.3, BRIDGE_START))
	# Tapers: the road widens into the scooter strip before the bridge and narrows after it.
	var taper := 25.0
	K.polygon(self, PackedVector2Array([Vector2(HALF, BRIDGE_START + taper), Vector2(STRIP_MAX + 0.3, BRIDGE_START),
		Vector2(HALF, BRIDGE_START)]))
	K.polygon(self, PackedVector2Array([Vector2(HALF, BRIDGE_END), Vector2(STRIP_MAX + 0.3, BRIDGE_END),
		Vector2(HALF, BRIDGE_END - taper)]))
	var xs := [-6.7, -3.5, 0.0, 3.5, 6.7]
	lines_ns(xs, ["edge", "dash", "yellow2", "dash", "edge"], 60.0, BRIDGE_START + taper)
	lines_ns(xs, ["edge", "dash", "yellow2", "dash", "edge"], BRIDGE_END - taper, -300.0)
	lines_ns([-6.7, -3.5, 0.0, 3.5], ["edge", "dash", "yellow2", "dash"], BRIDGE_START + taper, BRIDGE_START)
	lines_ns([-6.7, -3.5, 0.0, 3.5], ["edge", "dash", "yellow2", "dash"], BRIDGE_END, BRIDGE_END - taper)
	# Outer edge follows the tapers; the divider line splits off the strip where it opens up.
	K.line(self, Vector2(HALF - 0.3, BRIDGE_START + taper), Vector2(STRIP_MAX, BRIDGE_START))
	K.line(self, Vector2(STRIP_MAX, BRIDGE_END), Vector2(HALF - 0.3, BRIDGE_END - taper))
	K.line(self, Vector2(HALF - 0.3, BRIDGE_START + taper), Vector2(7.1, BRIDGE_START), K.YELLOW, 0.3)
	K.line(self, Vector2(7.1, BRIDGE_END), Vector2(HALF - 0.3, BRIDGE_END - taper), K.YELLOW, 0.3)
	lines_ns([-6.7, -3.5, 0.0, 3.5], ["edge", "dash", "yellow2", "dash"], BRIDGE_START, BRIDGE_END)
	# Yellow-black hatched divider between the main lanes and the scooter strip.
	K.line(self, Vector2(7.1, BRIDGE_START), Vector2(7.1, BRIDGE_END), K.YELLOW, 0.3)
	var z := BRIDGE_START - 1.0
	while z > BRIDGE_END:
		K.box(self, Vector3(0.3, 0.03, 0.8), Vector3(7.1, 0.05, z), Color(0.1, 0.1, 0.1))
		z -= 2.0
	for zz in [-60.0, -120.0, -175.0]:
		for lane_x in [1.75, 5.25]:
			K.ground_text(self, "禁\n行\n機\n車", Vector2(lane_x, zz), K.YELLOW)
		K.ground_text(self, "機\n車", Vector2(8.3, zz + 20.0), K.WHITE, 0.0, 0.006)
	# Barriers along both bridge edges.
	for bx in [-HALF - 0.3, STRIP_MAX + 0.45]:
		K.box(self, Vector3(0.3, 1.1, BRIDGE_START - BRIDGE_END), Vector3(bx, 0.55, (BRIDGE_START + BRIDGE_END) / 2.0), Color(0.7, 0.7, 0.72), true)
	sign_board("前方無人行道\n請繞行對向人行道", Vector3(STRIP_MAX + 1.0, 0, BRIDGE_START + 8.0), 0.0, Color(0.8, 0.15, 0.15), 2.0)
	sign_board("機車 ↗", Vector3(HALF + 1.2, 0, 20.0), 0.0, Color(0.15, 0.35, 0.75), 2.2)
	# Guide line and arrows steering scooters from the right lane into the strip.
	for gz in [12.0, -2.0]:
		K.ground_text(self, "機\n車\n↗", Vector2(5.25, gz), K.WHITE, 0.0, 0.007)
	sign_board("我家", Vector3(HALF + 1.5, 0, -280.0), -PI / 2.0, Color(0.6, 0.4, 0.2), 2.5)
	for sx in [-1, 1]:
		K.surface(self, Vector2(minf(sx * HALF, sx * (HALF + 4.0)), 0.0), Vector2(maxf(sx * HALF, sx * (HALF + 4.0)), 60.0), K.SIDEWALK, 0.03)
		StreetDressing.ns_side(self, sx * HALF, 60.0, 0.0, sx, 4.0)
	buildings_ns(HALF + 12.0, 0.0, 60.0, -1)
	buildings_ns(-HALF - 12.0, 0.0, 60.0, 1)
	buildings_ns(HALF + 12.0, -300.0, BRIDGE_END - 15.0, -1)

	_add_rules()
	gps = [Vector3(8.3, 0, BRIDGE_START - 5.0), Vector3(8.3, 0, BRIDGE_END + 5.0), Vector3(5.25, 0, -285.0)]


func after_spawn() -> void:
	# Two cyclists pedalling along the strip at ~16 km/h. They start once you're close, and bumping
	# into one just blocks you (and earns a bell) — the level is about patience, not reflexes.
	for i in 2:
		var start_z := BRIDGE_START - 5.0 - i * 18.0
		var npc := NpcVehicle.make_custom(self, _cyclist(i), AABB(Vector3(-0.3, 0, -0.9), Vector3(0.6, 1.7, 1.8)),
			[Vector3(8.3, 0, start_z), Vector3(8.3, 0, BRIDGE_END - 40.0)] as Array[Vector3], 4.5)
		npc.target = scooter
		npc.add_to_group("traffic")  # other scooters queue behind the cyclists too
		npc.trigger_distance = 45.0
		npc.touched.connect(func() -> void:
			Game.sfx.play("bell")
			toast("腳踏車：叮叮！（橋上就這麼一條，你也只能跟著。）", 2.5))


func _cyclist(i: int) -> Node3D:
	var root := Node3D.new()
	var shirt: Color = [Color(0.9, 0.5, 0.1), Color(0.3, 0.4, 0.9)][i % 2]
	K.box(root, Vector3(0.08, 0.6, 1.5), Vector3(0, 0.45, 0), Color(0.1, 0.1, 0.1))
	K.box(root, Vector3(0.5, 0.7, 0.35), Vector3(0, 1.25, -0.1), shirt)
	K.box(root, Vector3(0.1, 0.1, 0.1), Vector3(0, 1.1, -0.85), Color(1, 0.1, 0.1))  # tail light (visual faces +Z)
	K.box(root, Vector3(0.25, 0.25, 0.25), Vector3(0, 1.65, -0.15), Color(0.95, 0.8, 0.65))
	return root


func _add_rules() -> void:
	ViolationZone.make(self, Vector2(0.3, BRIDGE_END), Vector2(6.9, BRIDGE_START), "lane_ban", "ped_red,ambulance_tailgate",
		"超一台腳踏車 600，比行人闖紅燈（500）還貴；跟在救護車屁股後面狂飆也才 900。", Vector3.FORWARD)
	ViolationZone.make(self, Vector2(-HALF, -300.0), Vector2(-0.3, 60.0), "wrong_way")
	goal(Vector2(0.3, -290.0), Vector2(HALF, -280.0))
	# Cars fly past in the lanes you're not allowed in.
	traffic([Vector3(5.25, 0, 60.0), Vector3(5.25, 0, -300.0)] as Array[Vector3], 14.0, 3.0)
	traffic([Vector3(1.75, 0, 60.0), Vector3(1.75, 0, -300.0)] as Array[Vector3], 15.0, 4.5, Callable(), 1.5)
	traffic([Vector3(-5.25, 0, -300.0), Vector3(-5.25, 0, 60.0)] as Array[Vector3], 13.0, 4.0)
	# Scooters funnel into the strip with you (and queue behind the cyclists); pedestrians on land.
	traffic([Vector3(5.25, 0, 60.0), Vector3(5.25, 0, 10.0), Vector3(8.3, 0, BRIDGE_START - 2.0), Vector3(8.3, 0, BRIDGE_END + 2.0),
		Vector3(5.25, 0, BRIDGE_END - 25.0), Vector3(5.25, 0, -300.0)] as Array[Vector3], 8.0, 4.0, Callable(), 3.0, Vector3.INF, Callable(), "scooter")
	traffic([Vector3(-8.0, 0, -300.0), Vector3(-8.0, 0, 60.0)] as Array[Vector3], 11.0, 3.0, Callable(), 0.0, Vector3.INF, Callable(), "scooter")
	for sx in [-1, 1]:
		pedestrians_ns(sx * (HALF + 2.2), 60.0, 2.0, 3)
