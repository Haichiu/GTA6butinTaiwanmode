extends LevelBase
## Level 5 — 路口才知道. Whether (and how) you may turn left changes from one junction to the next.
##
## Junction A (z = 0): the inner lane has a painted left arrow, but a small sign at the far corner
##   says 禁止左轉 7:00–9:00 — and it's 08:10. Turning left is 48-1-2; turning around inside it
##   is 49-1-3; turning around mid-block afterwards crosses the double yellow (49-1-2).
## Between A and B the inner lane becomes 禁行機車.
## Junction B (z = B_Z): no 兩段式左轉 sign at all — but because the inner lane is 禁行機車,
##   police say you must still turn left in two stages (警方四原則, see docs/laws.md).
##   The school is left at B.

const HALF := 7.0  # arterial 2+2
const WALK := 4.0
const A_HALF := 7.0  # street A at z = 0
const B_Z := -130.0  # junction B, signalized; street B is 2+2
const B_HALF := 7.0
const STOP := 11.5  # stop line distance from a junction centre
const BOX_MIN := Vector2(7.8, B_Z - 6.6)  # 待轉區 at B's far-right corner (westbound lanes)
const BOX_MAX := Vector2(9.8, B_Z - 4.2)

var sig: TrafficSignal
var box: WaitBox


func _init() -> void:
	title = "路口才知道"
	who = "爸爸・08:10"
	objective = "小孩打電話來：「爸！我作業忘記帶了！」\n學校在前面路口左轉。"
	deadline = 60.0
	deadline_name = "早自習結束"
	place = "國小"
	waiting_person = true
	ending = "老師接過作業：「……今天沒有要交作業喔。」"
	late_ending = "早自習結束了。\n老師：「沒關係，明天再交就好。」"


func spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(1.75, 0.1, 85.0))


func build() -> void:
	K.surface(self, Vector2(-HALF, -220.0), Vector2(HALF, 95.0))
	K.surface(self, Vector2(-150.0, -A_HALF), Vector2(150.0, A_HALF))
	K.surface(self, Vector2(-150.0, B_Z - B_HALF), Vector2(60.0, B_Z + B_HALF))
	for sx in [-1, 1]:
		K.surface(self, Vector2(minf(sx * HALF, sx * (HALF + WALK)), A_HALF + WALK), Vector2(maxf(sx * HALF, sx * (HALF + WALK)), 95.0), K.SIDEWALK, 0.03)
	var xs := [-6.7, -3.5, 0.0, 3.5, 6.7]
	var kinds := ["edge", "dash", "yellow2", "dash", "edge"]
	lines_ns(xs, kinds, STOP, 95.0)
	lines_ns(xs, kinds, -A_HALF - 4.0, B_Z + STOP)
	lines_ns(xs, kinds, B_Z - STOP, -220.0)
	var zs := [-6.7, -3.5, 0.0, 3.5, 6.7]
	lines_ew(zs, kinds, -150.0, -HALF - 4.0)
	lines_ew(zs, kinds, HALF + 4.0, 150.0)
	lines_ew([B_Z - 6.7, B_Z - 3.5, B_Z, B_Z + 3.5, B_Z + 6.7], kinds, -150.0, -HALF - 7.3)
	lines_ew([B_Z - 6.7, B_Z - 3.5, B_Z, B_Z + 3.5, B_Z + 6.7], kinds, HALF + 7.3, 60.0)
	# Junction A.
	K.line(self, Vector2(0.2, STOP), Vector2(HALF, STOP), K.WHITE, 0.4)
	crosswalk(Vector2(-HALF, A_HALF + 0.5), Vector2(HALF, A_HALF + 3.5), "x")
	crosswalk(Vector2(-HALF, -A_HALF - 3.5), Vector2(HALF, -A_HALF - 0.5), "x")
	# The painted arrows say left is fine...
	K.ground_text(self, "↰\n↑", Vector2(1.75, 25.0), K.WHITE, 0.0, 0.012)
	K.ground_text(self, "↑", Vector2(5.25, 25.0), K.WHITE, 0.0, 0.012)
	# ...the small sign on the far corner says otherwise.
	sign_board("禁止左轉\n7:00–9:00", Vector3(-HALF - 1.2, 0, -A_HALF - 3.0), 0.0, Color(0.8, 0.12, 0.12), 2.4)
	# Between A and B: the inner lane is 禁行機車.
	for z in [-30.0, -75.0]:
		K.ground_text(self, "禁\n行\n機\n車", Vector2(1.75, z), K.YELLOW)
	# Junction B: signal, stop line, crosswalks, and a 待轉區 — but no 兩段式 sign anywhere.
	K.line(self, Vector2(0.2, B_Z + STOP), Vector2(HALF, B_Z + STOP), K.WHITE, 0.4)
	crosswalk(Vector2(-HALF, B_Z + B_HALF + 0.5), Vector2(HALF, B_Z + B_HALF + 3.5), "x")
	crosswalk(Vector2(-HALF, B_Z - B_HALF - 3.5), Vector2(HALF, B_Z - B_HALF - 0.5), "x")
	crosswalk(Vector2(HALF + 3.3, B_Z - B_HALF), Vector2(HALF + 6.3, B_Z + B_HALF), "z")
	crosswalk(Vector2(-HALF - 6.3, B_Z - B_HALF), Vector2(-HALF - 3.3, B_Z + B_HALF), "z")
	K.outline(self, BOX_MIN, BOX_MAX)
	K.ground_text(self, "機車\n待轉", (BOX_MIN + BOX_MAX) / 2.0, K.WHITE, PI / 2.0, 0.004)
	sig = TrafficSignal.new()
	add_child(sig)
	sig.setup(TrafficSignal.Phase.EW_GO, 8.0)
	sig.add_head(Vector3(HALF + 1.5, 0, B_Z - B_HALF - 4.0), "ns", Vector3.FORWARD)
	sig.add_head(Vector3(-HALF - 2.0, 0, B_Z - B_HALF - 1.5), "ew", Vector3.LEFT)
	sign_board("國小", Vector3(-80.0, 0, B_Z - B_HALF - 1.5), 0.0, Color(0.1, 0.5, 0.3), 2.5)
	for sx in [-1, 1]:
		# Sidewalks the whole way, dressed like any Taiwanese street.
		for seg in [[A_HALF + WALK, 95.0], [B_Z + B_HALF + WALK, -A_HALF - WALK], [-220.0, B_Z - B_HALF - WALK]]:
			K.surface(self, Vector2(minf(sx * HALF, sx * (HALF + WALK)), seg[0]), Vector2(maxf(sx * HALF, sx * (HALF + WALK)), seg[1]), K.SIDEWALK, 0.03)
			StreetDressing.ns_side(self, sx * HALF, seg[1], seg[0], sx, WALK)
		buildings_ns(sx * (HALF + WALK + 8.0), A_HALF + WALK, 95.0, -sx)
		buildings_ns(sx * (HALF + WALK + 8.0), B_Z + B_HALF + 4.0, -A_HALF - WALK, -sx)
		buildings_ns(sx * (HALF + WALK + 8.0), -220.0, B_Z - B_HALF - 4.0, -sx)
	box = WaitBox.make(self, BOX_MIN, BOX_MAX)
	box.turn_area = Rect2(Vector2(-HALF, B_Z - B_HALF), Vector2(2.0 * HALF + 3.3, 2.0 * B_HALF))
	_add_rules()
	gps = [Vector3(-2.0, 0, -2.0), Vector3(-80.0, 0, B_Z - 3.5)]


func _add_rules() -> void:
	var back := Vector3.BACK  # southbound
	var fwd := Vector3.FORWARD
	# Junction A.
	ViolationZone.make(self, Vector2(-150.0, -A_HALF), Vector2(-0.5, A_HALF), "no_left_turn", "ped_jaywalk",
		"地上畫左轉箭頭，牌子寫早上禁止左轉：罰 600，比行人亂穿馬路（500）還貴。", Vector3.LEFT)
	ViolationZone.make(self, Vector2(-HALF, -A_HALF), Vector2(-0.3, A_HALF), "uturn_no_left", "no_left_turn",
		"不能左轉，那迴轉總可以吧？不行，禁止左轉的地方也不能迴轉：900，比左轉還貴。", back)
	ViolationZone.make(self, Vector2(-HALF, B_Z + STOP + 1.0), Vector2(-0.3, -A_HALF - 1.0), "uturn_double_yellow", "no_left_turn",
		"在雙黃線上迴轉 900，比剛剛直接左轉（600）還貴。", back)
	# Between A and B: inner lane 禁行機車 — enforced only from the first painted marking (z -30).
	# Riding straight out of A in the inner lane is legal (its arrow allows it); the dashed line
	# before the marking leaves room to move over.
	ViolationZone.make(self, Vector2(0.3, B_Z + STOP), Vector2(3.3, -34.0), "lane_ban", "no_left_turn",
		"過了路口，剛剛畫著左轉箭頭的那條車道，變成禁行機車。", fwd)
	# Junction B: no sign, but the inner lane is 禁行機車 -> two stages anyway.
	ViolationZone.make(self, Vector2(-150.0, B_Z - B_HALF), Vector2(-0.5, B_Z + B_HALF), "two_stage_left", "no_left_turn",
		"這個路口沒有兩段式左轉的標誌。但內側車道禁行機車，所以一樣要兩段式左轉（警方說明）。", Vector3.LEFT) \
		.when(func() -> bool: return not box.waited)
	ViolationZone.make(self, Vector2(-HALF, B_Z - B_HALF), Vector2(HALF, B_Z - 0.3), "red_light", "ped_red",
		"待轉區提早一秒出發＝闖紅燈 1,800，是行人闖紅燈（500）的 3.6 倍。", Vector3.LEFT) \
		.when(func() -> bool: return box.waited and sig.is_red("ew"))
	StopLineRule.make(self, sig, "ns", fwd, Vector3(0, 0, B_Z + STOP), 0.3, HALF)
	# Wrong-way on the arterial, but not inside the junctions where turning riders swing across.
	for seg in [[STOP, 95.0], [B_Z + STOP + 4.0, -A_HALF - 6.0], [-220.0, B_Z - STOP - 4.0]]:
		ViolationZone.make(self, Vector2(-HALF, seg[0]), Vector2(-0.3, seg[1]), "wrong_way", "", "", fwd)
	ViolationZone.make(self, Vector2(-150.0, B_Z + 0.3), Vector2(-HALF - 8.0, B_Z + B_HALF), "wrong_way", "", "", Vector3.LEFT)
	goal(Vector2(-85.0, B_Z - B_HALF), Vector2(-75.0, B_Z))
	# School zone: a ball, then a kid.
	darter("ball", Vector3(-50.0, 0, B_Z - 12.0), Vector3(-50.0, 0, B_Z + 12.0), 26.0)
	var ns_go := func() -> bool: return not sig.is_red("ns")
	traffic([Vector3(5.25, 0, 95.0), Vector3(5.25, 0, -220.0)] as Array[Vector3], 11.0, 5.0, Callable(), 0.0,
		Vector3(5.25, 0, B_Z + STOP), ns_go)
	traffic([Vector3(-5.25, 0, -220.0), Vector3(-5.25, 0, 95.0)] as Array[Vector3], 11.0, 6.0, Callable(), 3.0,
		Vector3(-5.25, 0, B_Z - STOP), ns_go)
	traffic([Vector3(5.25, 0, 95.0), Vector3(5.25, 0, -220.0)] as Array[Vector3], 9.5, 3.0, Callable(), 1.5,
		Vector3(5.25, 0, B_Z + STOP), ns_go, "scooter")
	traffic([Vector3(-5.25, 0, -220.0), Vector3(-5.25, 0, 95.0)] as Array[Vector3], 9.5, 3.0, Callable(), 0.5,
		Vector3(-5.25, 0, B_Z - STOP), ns_go, "scooter")
	for sx in [-1, 1]:
		pedestrians_ns(sx * (HALF + 2.2), 95.0, A_HALF + WALK + 1.0, 4)
		pedestrians_ns(sx * (HALF + 2.2), -A_HALF - WALK - 1.0, B_Z + B_HALF + WALK + 1.0, 4)
	# Past junction A the GPS just points at the school.
	on_enter(Vector2(-HALF, -A_HALF - 12.0), Vector2(HALF, -A_HALF - 6.0), func() -> void:
		gps = [Vector3(-2.0, 0, B_Z - 2.0), Vector3(-80.0, 0, B_Z - 3.5)]
		_gps_index = 0)
