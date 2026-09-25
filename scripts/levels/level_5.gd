extends LevelBase
## Level 5 — 路口才知道.
## The inner lane has a painted left-turn arrow, but a small sign at the far corner says
## 禁止左轉 7:00–9:00 — and it's 08:10. You only find out at the intersection.
## Turning around mid-block crosses the double yellow (49-1-2); turning around inside the
## no-left intersection is its own violation (49-1-3). Legal: straight on, U-turn at the next
## intersection, come back, then turn right.

const HALF := 7.0  # 2+2 lanes, no 禁行機車
const WALK := 4.0
const A_HALF := 7.0  # street A at z = 0 (school is west on it), 2+2 lanes
const B_Z := -130.0  # next intersection
const B_HALF := 4.0
const STOP := 11.5

var _reached_b := false


func _init() -> void:
	title = "路口才知道"
	who = "爸爸・08:10"
	objective = "小孩打電話來：「爸！我作業忘記帶了！」\n學校在前面路口左轉。"
	deadline = 50.0
	deadline_name = "早自習結束"
	place = "國小"
	waiting_person = true
	ending = "老師接過作業：「……今天沒有要交作業喔。」"
	late_ending = "早自習結束了。\n老師：「沒關係，明天再交就好。」"


func spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(1.75, 0.1, 85.0))


func build() -> void:
	K.surface(self, Vector2(-HALF, -200.0), Vector2(HALF, 95.0))
	K.surface(self, Vector2(-150.0, -A_HALF), Vector2(150.0, A_HALF))
	K.surface(self, Vector2(-40.0, B_Z - B_HALF), Vector2(40.0, B_Z + B_HALF))
	for sx in [-1, 1]:
		K.surface(self, Vector2(minf(sx * HALF, sx * (HALF + WALK)), A_HALF + WALK), Vector2(maxf(sx * HALF, sx * (HALF + WALK)), 95.0), K.SIDEWALK, 0.03)
	var xs := [-6.7, -3.5, 0.0, 3.5, 6.7]
	lines_ns(xs, ["edge", "dash", "yellow2", "dash", "edge"], STOP, 95.0)
	lines_ns(xs, ["edge", "dash", "yellow2", "dash", "edge"], -A_HALF - 4.0, B_Z + B_HALF + 1.0)
	lines_ns(xs, ["edge", "dash", "yellow2", "dash", "edge"], B_Z - B_HALF - 1.0, -200.0)
	lines_ew([-6.7, -3.5, 0.0, 3.5, 6.7], ["edge", "dash", "yellow2", "dash", "edge"], -150.0, -HALF - 4.0)
	lines_ew([-6.7, -3.5, 0.0, 3.5, 6.7], ["edge", "dash", "yellow2", "dash", "edge"], HALF + 4.0, 150.0)
	K.line(self, Vector2(0.2, STOP), Vector2(HALF, STOP), K.WHITE, 0.4)
	crosswalk(Vector2(-HALF, A_HALF + 0.5), Vector2(HALF, A_HALF + 3.5), "x")
	crosswalk(Vector2(-HALF, -A_HALF - 3.5), Vector2(HALF, -A_HALF - 0.5), "x")
	# The painted arrows say left is fine...
	K.ground_text(self, "↰\n↑", Vector2(1.75, 25.0), K.WHITE, 0.0, 0.012)
	K.ground_text(self, "↑", Vector2(5.25, 25.0), K.WHITE, 0.0, 0.012)
	# ...the small sign on the far corner says otherwise.
	sign_board("禁止左轉\n7:00–9:00", Vector3(-HALF - 1.2, 0, -A_HALF - 3.0), 0.0, Color(0.8, 0.12, 0.12), 2.4)
	sign_board("國小", Vector3(-80.0, 0, -A_HALF - 1.5), 0.0, Color(0.1, 0.5, 0.3), 2.5)
	for sx in [-1, 1]:
		buildings_ns(sx * (HALF + WALK + 8.0), A_HALF + WALK, 95.0, -sx)
		buildings_ns(sx * (HALF + WALK + 8.0), B_Z + B_HALF + 4.0, -A_HALF - WALK, -sx)
		buildings_ns(sx * (HALF + WALK + 8.0), -200.0, B_Z - B_HALF - 4.0, -sx)
	_add_rules()
	gps = [Vector3(-2.0, 0, -2.0), Vector3(-80.0, 0, -3.5)]


func _add_rules() -> void:
	var back := Vector3.BACK  # southbound
	ViolationZone.make(self, Vector2(-150.0, -A_HALF), Vector2(-0.5, A_HALF), "no_left_turn", "ped_jaywalk",
		"地上畫左轉箭頭，牌子寫早上禁止左轉：罰 600，比行人亂穿馬路（500）還貴。", Vector3.LEFT) \
		.when(func() -> bool: return not _reached_b)
	# Turning around inside the no-left intersection.
	ViolationZone.make(self, Vector2(-HALF, -A_HALF), Vector2(-0.3, A_HALF), "uturn_no_left", "no_left_turn",
		"不能左轉，那迴轉總可以吧？不行，禁止左轉的地方也不能迴轉：900，比左轉還貴。", back) \
		.when(func() -> bool: return not _reached_b)
	# Turning around mid-block across the double yellow.
	ViolationZone.make(self, Vector2(-HALF, B_Z + B_HALF + 1.0), Vector2(-0.3, -A_HALF - 1.0), "uturn_double_yellow", "no_left_turn",
		"在雙黃線上迴轉 900，比剛剛直接左轉（600）還貴。", back) \
		.when(func() -> bool: return not _reached_b)
	# Wrong-way on the arterial, but not inside the intersections where turning riders swing across.
	for seg in [[STOP, 95.0], [B_Z + B_HALF + 6.0, -A_HALF - 6.0], [-200.0, B_Z - B_HALF - 6.0]]:
		ViolationZone.make(self, Vector2(-HALF, seg[0]), Vector2(-0.3, seg[1]), "wrong_way", "", "", Vector3.FORWARD)
	ViolationZone.make(self, Vector2(-150.0, 0.3), Vector2(-HALF - 6.0, A_HALF), "wrong_way", "", "", Vector3.LEFT)
	goal(Vector2(-85.0, -A_HALF), Vector2(-75.0, 0.0))
	# Reaching the next intersection makes the U-turn (and the way back) legitimate.
	on_enter(Vector2(-HALF, B_Z - B_HALF), Vector2(HALF, B_Z + B_HALF), func() -> void:
		_reached_b = true
		gps = [Vector3(-3.5, 0, -10.0), Vector3(-80.0, 0, -3.5)]
		_gps_index = 0)
