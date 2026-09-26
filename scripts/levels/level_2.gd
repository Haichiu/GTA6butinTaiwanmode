extends LevelBase
## Level 2 — 我的車道呢？ (after Geomeme's 左轉道設計).
## At the intersection the scooter lane turns into a right-turn-only lane, and the only
## straight lane is 禁行機車. Scooters simply cannot go straight here. The legal way is a
## right turn and a loop around the block: street A east, side street B north, back street C west.
## Setting: 屏東市建國路 (台3線). TVBS: inner lanes 禁行機車, outer lane right-turn only; 公路局
## says turn right and 待轉 on the next street, and points to the three notices it put up within
## 100 m. Riders mostly never saw them.

const HALF := 10.5
const WALK := 4.0
const A_HALF := 7.0  # street A (z = 0), 2+2 lanes
const STOP := 11.5  # northbound stop line z
const B_X := 60.0  # side street B centerline, 1+1 lanes
const C_Z := -80.0  # back street C centerline, 1+1 lanes
const SMALL := 4.0  # half width of B and C


func _init() -> void:
	title = "我的車道呢？"
	who = "工程師・18:57"
	objective = "交友軟體聊了三個月，今天第一次見面。\n約在前面路口過去、萬年溪旁邊的咖啡店，七點。"
	deadline = 50.0
	deadline_name = "約定時間"
	place = "咖啡店"
	waiting_person = true
	ending = "你推開咖啡店的門，她剛好抬頭。\n「你也是騎車來的吧？頭髮好亂。」"
	late_ending = "她已經走了。\n桌上留著一杯沒動過的拿鐵。"


func spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(8.75, 0.1, 70.0))


func build() -> void:
	# Surfaces.
	K.surface(self, Vector2(-HALF, -200.0), Vector2(HALF, 80.0))
	K.surface(self, Vector2(-40.0, -A_HALF), Vector2(B_X + SMALL, A_HALF))
	K.surface(self, Vector2(B_X - SMALL, C_Z - SMALL), Vector2(B_X + SMALL, -A_HALF))
	K.surface(self, Vector2(HALF, C_Z - SMALL), Vector2(B_X - SMALL, C_Z + SMALL))
	K.surface(self, Vector2(HALF, 12.0), Vector2(HALF + WALK, 80.0), K.SIDEWALK, 0.03)
	K.surface(self, Vector2(-HALF - WALK, -200.0), Vector2(-HALF, 80.0), K.SIDEWALK, 0.03)

	# Arterial, south approach: normal lanes, then solid lines and turn lanes near the stop line.
	lines_ns([-10.2, -7.0, -3.5, 0.0, 3.5, 7.0, 10.2],
		["edge", "dash", "dash", "yellow2", "dash", "dash", "edge"], 80.0, 40.0)
	lines_ns([-10.2, -7.0, -3.5, 0.0, 3.5, 7.0, 10.2],
		["edge", "dash", "dash", "yellow2", "solid", "solid", "edge"], 40.0, STOP)
	K.line(self, Vector2(0.2, STOP), Vector2(HALF, STOP), K.WHITE, 0.4)
	crosswalk(Vector2(-HALF, A_HALF + 0.5), Vector2(HALF, A_HALF + 3.5), "x")
	for lane_x in [1.75, 5.25]:
		K.ground_text(self, "禁\n行\n機\n車", Vector2(lane_x, 60.0), K.YELLOW)
	K.ground_text(self, "左\n轉", Vector2(1.75, 25.0), K.WHITE, 0.0, 0.009)
	K.ground_text(self, "直\n行", Vector2(5.25, 25.0), K.WHITE, 0.0, 0.009)
	K.ground_text(self, "右\n轉\n專\n用", Vector2(8.75, 25.0), K.WHITE, 0.0, 0.009)
	K.ground_text(self, "禁\n行\n機\n車", Vector2(5.25, 18.0), K.YELLOW, 0.0, 0.006)
	# Arterial north of the intersection.
	lines_ns([-10.2, -7.0, -3.5, 0.0, 3.5, 7.0, 10.2],
		["edge", "dash", "dash", "yellow2", "dash", "dash", "edge"], -A_HALF - 4.0, -200.0)
	for z in [-40.0, -110.0, -180.0]:
		for lane_x in [1.75, 5.25]:
			K.ground_text(self, "禁\n行\n機\n車", Vector2(lane_x, z), K.YELLOW)

	# Street A (east part), side street B, back street C.
	lines_ew([0.0, A_HALF - 0.3, -A_HALF + 0.3], ["yellow2", "edge", "edge"], HALF + 4.0, B_X - SMALL)
	lines_ns([B_X], ["yellow2"], -A_HALF, C_Z + SMALL)
	lines_ew([C_Z], ["yellow2"], HALF, B_X - SMALL)

	sign_board("右轉專用", Vector3(HALF + 1.2, 0, 30.0), 0.0, Color(0.15, 0.35, 0.75), 2.2)
	# The three notices within 100 m (small, white, at the roadside — easy to ride past).
	for nz in [62.0, 48.0, 20.0]:
		sign_board("機車直行\n請右轉\n至鄰近路口\n待轉", Vector3(HALF + 0.8, 0, nz), 0.0, Color(0.92, 0.92, 0.9), 1.3)
	sign_board("台3　建國路", Vector3(-HALF - 1.5, 0, 60.0), PI, Color(0.1, 0.45, 0.25), 2.8)
	_wannian_creek()
	# The block inside the loop hides the detour from view.
	for bx in [22.0, 38.0]:
		for bz in [-25.0, -55.0]:
			model(CITY + BUILDINGS[_building_i % BUILDINGS.size()] + ".glb", Vector3(bx, 0, bz), PI / 2.0, 13.0, true)
			_building_i += 1
	StreetDressing.ns_side(self, HALF, 80.0, 14.0, 1, WALK)
	StreetDressing.ns_side(self, -HALF, 80.0, -200.0, -1, WALK, [[-12.0, 12.0]])
	buildings_ns(-HALF - WALK - 8.0, -200.0, 80.0, 1)
	buildings_ns(HALF + WALK + 8.0, 14.0, 80.0, -1)
	buildings_ns(HALF + WALK + 8.0, -200.0, C_Z - SMALL - 2.0, -1)

	_add_rules()
	gps = [Vector3(8.75, 0, -155.0)]


## 萬年溪 crosses the road north of the junction: a concrete channel under a short bridge, with
## the park's trees along it. The café is on the far bank.
func _wannian_creek() -> void:
	const CZ := -135.0
	K.surface(self, Vector2(-300.0, CZ - 7.0), Vector2(300.0, CZ + 7.0), Color(0.62, 0.62, 0.6), 0.005)  # channel walls/banks
	K.surface(self, Vector2(-300.0, CZ - 4.5), Vector2(300.0, CZ + 4.5), Color(0.25, 0.4, 0.38), 0.008)  # water
	K.surface(self, Vector2(-HALF - WALK, CZ - 7.5), Vector2(HALF + WALK, CZ + 7.5), K.ASPHALT, 0.02)  # the bridge deck
	lines_ns([-10.2, -7.0, -3.5, 0.0, 3.5, 7.0, 10.2], ["edge", "dash", "dash", "yellow2", "dash", "dash", "edge"], CZ + 7.5, CZ - 7.5)
	for x in [-HALF - WALK, HALF + WALK]:
		K.box(self, Vector3(0.3, 1.1, 15.0), Vector3(x, 0.55, CZ), Color(0.8, 0.78, 0.74), true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2
	for i in 18:
		var side := -1.0 if i % 2 == 0 else 1.0
		StreetDressing._tree(self, Vector3(side * rng.randf_range(HALF + WALK + 20.0, 120.0), 0, CZ + side * 10.0), rng.randf_range(1.0, 1.5))
	sign_board("萬年溪", Vector3(HALF + WALK + 0.5, 0, CZ + 8.0), 0.0, Color(0.1, 0.45, 0.25), 2.0)
	# 屏東 roadside: betel-nut stands with their glass booths and neon.
	for bz in [52.0, -60.0, -175.0]:
		_betel_stand(Vector3(-HALF - WALK + 1.2, 0, bz))


func _betel_stand(pos: Vector3) -> void:
	K.box(self, Vector3(2.2, 2.4, 2.4), pos + Vector3(0, 1.2, 0), Color(0.75, 0.88, 0.92))
	K.box(self, Vector3(2.4, 0.15, 2.8), pos + Vector3(0, 2.5, 0), Color(0.9, 0.2, 0.5))
	sign_board("檳榔", pos + Vector3(0.6, 0, 1.6), PI / 2.0, Color(0.95, 0.2, 0.55), 3.2)


func _add_rules() -> void:
	var fwd := Vector3.FORWARD
	ViolationZone.make(self, Vector2(0.3, STOP), Vector2(6.8, 80.0), "lane_ban", "turn_lane_straight",
		"直行車道禁行機車；可是機車道到了路口只能右轉。", fwd)
	ViolationZone.make(self, Vector2(0.3, -A_HALF + 0.5), Vector2(HALF, -2.0), "turn_lane_straight", "lane_ban,turn_no_yield",
		"這個路口機車怎麼直走都違規。轉彎不讓直行車、把直行機車撞倒的汽車，罰 900。", fwd)
	ViolationZone.make(self, Vector2(0.3, -200.0), Vector2(6.8, -A_HALF - 0.5), "lane_ban", "sidewalk", "", fwd)
	# Wrong-way: arterial southbound half, and the "other side" of A, B and C.
	ViolationZone.make(self, Vector2(-HALF, -200.0), Vector2(-0.3, 80.0), "wrong_way")
	# Stops short of junctions so turning across the opposing lane there is not "wrong way".
	ViolationZone.make(self, Vector2(HALF + 8.0, -A_HALF), Vector2(B_X - SMALL - 8.0, -0.3), "wrong_way", "", "", Vector3.RIGHT)
	ViolationZone.make(self, Vector2(B_X - SMALL, C_Z + SMALL + 8.0), Vector2(B_X - 0.3, -A_HALF - 8.0), "wrong_way", "", "", fwd)
	ViolationZone.make(self, Vector2(HALF + 8.0, C_Z + 0.3), Vector2(B_X - SMALL - 8.0, C_Z + SMALL), "wrong_way", "", "", Vector3.LEFT)
	ViolationZone.make(self, Vector2(HALF + CURB, 14.0), Vector2(HALF + WALK, 80.0), "sidewalk")
	ViolationZone.make(self, Vector2(-HALF - WALK, -200.0), Vector2(-HALF - CURB, 80.0), "sidewalk")
	goal(Vector2(7.0, -160.0), Vector2(HALF, -150.0))
	# Cars may use the inner lanes you may not.
	traffic([Vector3(5.25, 0, 90.0), Vector3(5.25, 0, -200.0)] as Array[Vector3], 11.0, 4.5)
	traffic([Vector3(1.75, 0, 90.0), Vector3(1.75, 0, -200.0)] as Array[Vector3], 12.0, 6.0, Callable(), 2.5)
	traffic([Vector3(-5.25, 0, -200.0), Vector3(-5.25, 0, 90.0)] as Array[Vector3], 12.0, 5.0)
	darter("dog", Vector3(36.0, 0, 11.0), Vector3(36.0, 0, -11.0), 22.0)
	# Other scooters do what the lane markings force: turn right and go round.
	traffic([Vector3(8.75, 0, 90.0), Vector3(8.75, 0, 16.0), Vector3(12.0, 0, 4.0), Vector3(54.0, 0, 3.5),
		Vector3(62.0, 0, -8.0), Vector3(62.0, 0, -76.0)] as Array[Vector3], 9.0, 3.0, Callable(), 1.0, Vector3.INF, Callable(), "scooter")
	traffic([Vector3(-8.75, 0, -200.0), Vector3(-8.75, 0, 90.0)] as Array[Vector3], 11.0, 2.5, Callable(), 0.0, Vector3.INF, Callable(), "scooter")
	pedestrians_ns(-HALF - 2.2, 80.0, -200.0, 8)
	pedestrians_ns(HALF + 2.2, 80.0, 14.0, 4)
	# Once you give up and turn right, the GPS "helpfully" reroutes.
	on_enter(Vector2(HALF + 4.0, 0.0), Vector2(HALF + 10.0, A_HALF), func() -> void:
		gps = [Vector3(B_X + 2.0, 0, -3.0), Vector3(B_X + 2.0, 0, C_Z - 2.0), Vector3(HALF + 2.0, 0, C_Z - 2.0), Vector3(8.75, 0, -155.0)]
		_gps_index = 0
		toast("導航：已重新規劃路線，多繞 400 公尺。"))
