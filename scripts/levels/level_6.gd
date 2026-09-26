extends LevelBase
## Level 6 — 橋上分流 (after Geomeme's 橋樑車道設計: 橋下混流，橋上分流).
## On the bridge the main lanes become 禁行機車 and scooters are squeezed into a narrow strip
## next to the barrier — shared with slow cyclists.
## Setting: 台北橋 (台1甲), 三重 → 台北. The 機慢車道 is split from the car lanes by a raised
## island (交通局, 2025), so once you're on it there's no passing the bikes; the only way round
## them is to go up the car lanes, which are 禁行機車. At the 台北 end it drops down the ramp that
## the 機車瀑布 photos are taken from, over the 堤防.

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
	# Raised concrete island between the car lanes and the 機慢車道, the whole length of the bridge.
	K.box(self, Vector3(0.5, 0.8, BRIDGE_START - BRIDGE_END), Vector3(7.1, 0.4, (BRIDGE_START + BRIDGE_END) / 2.0),
		Color(0.78, 0.77, 0.74), true)
	var z := BRIDGE_START - 1.0
	while z > BRIDGE_END:
		K.box(self, Vector3(0.52, 0.2, 0.9), Vector3(7.1, 0.7, z), K.YELLOW)
		z -= 3.0
	_taipei_bridge()
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


## 淡水河 is wide here: water well beyond both sides, lamp posts along the bridge, the 堤防 wall
## and its 水門 at the 台北 end, 三重's towers behind you and 大稻埕's low roofs ahead.
func _taipei_bridge() -> void:
	K.surface(self, Vector2(-500.0, BRIDGE_END + 10.0), Vector2(500.0, BRIDGE_START - 10.0), WATER, 0.009)
	var z := BRIDGE_START - 8.0
	while z > BRIDGE_END + 4.0:
		for x in [-HALF - 0.3, STRIP_MAX + 0.45]:
			K.box(self, Vector3(0.15, 7.0, 0.15), Vector3(x, 3.5, z), Color(0.55, 0.58, 0.6))
			K.box(self, Vector3(1.4, 0.2, 0.3), Vector3(x - signf(x) * 0.6, 7.0, z), Color(0.55, 0.58, 0.6))
		z -= 20.0
	# 堤防: a tall grey wall across the whole view at the 台北 end; the road rides over it.
	for side in [-1.0, 1.0]:
		var inner := HALF + 1.0 if side < 0 else STRIP_MAX + 1.5
		K.box(self, Vector3(400.0, 6.0, 4.0), Vector3(side * (inner + 200.0), 3.0, BRIDGE_END - 12.0), Color(0.6, 0.6, 0.58), true)
	K.box(self, Vector3(6.0, 4.0, 4.4), Vector3(-40.0, 2.0, BRIDGE_END - 12.0), Color(0.3, 0.45, 0.6))  # 水門
	sign_board("水門", Vector3(-40.0, 4.5, BRIDGE_END - 9.5), 0.0, Color(0.2, 0.35, 0.6), 1.5)
	sign_board("台北橋", Vector3(STRIP_MAX + 1.4, 0, BRIDGE_START + 4.0), 0.0, Color(0.1, 0.45, 0.25), 2.8)
	sign_board("台1甲", Vector3(-HALF - 1.5, 0, 30.0), PI, Color(0.1, 0.45, 0.25), 2.2)
	# 三重 behind you: tall residential towers. 台北 ahead: 大稻埕's low old shophouses.
	for i in 6:
		K.box(self, Vector3(18.0, 60.0 + (i % 3) * 20.0, 18.0), Vector3(-80.0 + i * 32.0, 30.0 + (i % 3) * 10.0, 140.0 + (i % 2) * 30.0),
			Color(0.75, 0.73, 0.7))
	for i in 12:
		var x := (-1.0 if i % 2 == 0 else 1.0) * (30.0 + (i / 2) * 18.0)
		K.box(self, Vector3(12.0, 9.0, 14.0), Vector3(x, 4.5, BRIDGE_END - 40.0 - (i % 3) * 16.0), Color(0.72, 0.55, 0.45))


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
	ViolationZone.make(self, Vector2(0.3, BRIDGE_END), Vector2(6.8, BRIDGE_START), "lane_ban", "ped_red,ambulance_tailgate",
		"不想卡在腳踏車後面，改走汽車道上橋：600，比行人闖紅燈（500）還貴；跟在救護車屁股後面狂飆也才 900。", Vector3.FORWARD)
	ViolationZone.make(self, Vector2(-HALF, -300.0), Vector2(-0.3, 60.0), "wrong_way")
	goal(Vector2(0.3, -290.0), Vector2(HALF, -280.0))
	# Cars fly past in the lanes you're not allowed in.
	traffic([Vector3(5.25, 0, 60.0), Vector3(5.25, 0, -300.0)] as Array[Vector3], 14.0, 3.0)
	traffic([Vector3(1.75, 0, 60.0), Vector3(1.75, 0, -300.0)] as Array[Vector3], 15.0, 4.5, Callable(), 1.5)
	traffic([Vector3(-5.25, 0, -300.0), Vector3(-5.25, 0, 60.0)] as Array[Vector3], 13.0, 4.0)
	# Scooters funnel into the strip with you (and queue behind the cyclists); pedestrians on land.
	traffic([Vector3(5.25, 0, 60.0), Vector3(5.25, 0, 10.0), Vector3(8.3, 0, BRIDGE_START - 2.0), Vector3(8.3, 0, BRIDGE_END + 2.0),
		Vector3(5.25, 0, BRIDGE_END - 25.0), Vector3(5.25, 0, -300.0)] as Array[Vector3], 8.0, 1.6, Callable(), 3.0, Vector3.INF, Callable(), "scooter")
	traffic([Vector3(-8.0, 0, -300.0), Vector3(-8.0, 0, 60.0)] as Array[Vector3], 11.0, 3.0, Callable(), 0.0, Vector3.INF, Callable(), "scooter")
	for sx in [-1, 1]:
		pedestrians_ns(sx * (HALF + 2.2), 60.0, 2.0, 3)
