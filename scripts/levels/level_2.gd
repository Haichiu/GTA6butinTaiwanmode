extends LevelBase
## Level 2 — 我的車道呢？ (after Geomeme's 左轉道設計).
## At the intersection the scooter lane turns into a right-turn-only lane, and the only
## straight lane is 禁行機車. Scooters simply cannot go straight here. The legal way is a
## right turn and a loop around the block: street A east, side street B north, back street C west.

const HALF := 10.5
const WALK := 4.0
const A_HALF := 7.0  # street A (z = 0), 2+2 lanes
const STOP := 11.5  # northbound stop line z
const B_X := 60.0  # side street B centerline, 1+1 lanes
const C_Z := -80.0  # back street C centerline, 1+1 lanes
const SMALL := 4.0  # half width of B and C


func _init() -> void:
	title = "我的車道呢？"
	who = "歌迷・18:57"
	objective = "搶了三個月的演唱會門票，七點開場。場館就在前面路口正對面。"
	deadline = 50.0
	deadline_name = "開場"
	place = "演唱會入口"
	waiting_person = false
	ending = "衝進場館的瞬間，第一首歌前奏剛好下。\n全場尖叫，你也是。"
	late_ending = "你在場館外面，隔著牆聽完了安可。"


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
	sign_board("巨蛋演唱會\n今晚 19:00", Vector3(HALF + 1.5, 0, -155.0), -PI / 2.0, Color(0.55, 0.15, 0.6), 2.5)
	# The block inside the loop hides the detour from view.
	for bx in [22.0, 38.0]:
		for bz in [-25.0, -55.0]:
			model(CITY + BUILDINGS[_building_i % BUILDINGS.size()] + ".glb", Vector3(bx, 0, bz), PI / 2.0, 13.0, true)
			_building_i += 1
	buildings_ns(-HALF - WALK - 8.0, -200.0, 80.0, 1)
	buildings_ns(HALF + WALK + 8.0, 14.0, 80.0, -1)
	buildings_ns(HALF + WALK + 8.0, -200.0, C_Z - SMALL - 2.0, -1)

	_add_rules()
	gps = [Vector3(8.75, 0, -155.0)]


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
	# Once you give up and turn right, the GPS "helpfully" reroutes.
	on_enter(Vector2(HALF + 4.0, 0.0), Vector2(HALF + 10.0, A_HALF), func() -> void:
		gps = [Vector3(B_X + 2.0, 0, -3.0), Vector3(B_X + 2.0, 0, C_Z - 2.0), Vector3(HALF + 2.0, 0, C_Z - 2.0), Vector3(8.75, 0, -155.0)]
		_gps_index = 0
		toast("導航：已重新規劃路線，多繞 400 公尺。"))
