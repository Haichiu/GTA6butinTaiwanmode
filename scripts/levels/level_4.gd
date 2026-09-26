extends LevelBase
## Level 4 — 兩段式「右」轉.
## One-way road, four lanes. Scooters may use only the outermost lanes; the right one is closed for
## construction, so you're in the left lane. 道路交通安全規則 99-2-2: on a one-way road with 3+
## lanes, a scooter in the left lane must turn RIGHT in two stages. Destination: to the right.
## Setting: 台北重慶南路一段 in the 博愛特區 — a four-lane one-way street (維基百科), old bookshops
## along it, bank head offices, and the 總統府 tower at the end of the street.

const HALF := 7.0  # 4 lanes, all northbound
const WALK := 4.0
const EW := 7.0  # cross street, one-way eastbound, 4 lanes
const STOP := 11.5
# 待轉區 at the far-left corner, facing east: in front of the west crosswalk (x -10.8) with a 0.5 m
# gap, front edge not past the one-way road's edge (x -7). Shallow on purpose.
const BOX_MIN := Vector2(-10.3, -6.6)
const BOX_MAX := Vector2(-8.3, -4.2)

var sig: TrafficSignal
var box: WaitBox
var rusher: NpcVehicle
var _rush_timer := 0.0


func _init() -> void:
	title = "兩段式「右」轉"
	who = "小老闆・15:28"
	objective = "貨款今天一定要存進去，銀行三點半關門。銀行在右邊那條路上。"
	deadline = 45.0
	deadline_name = "銀行關門"
	place = "銀行"
	waiting_person = false
	ending = "鐵捲門拉到一半，你用滑壘的姿勢滑了進去。"
	late_ending = "鐵捲門在你面前「唰——」一聲關上。"


func spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(-5.25, 0.1, 80.0))


func build() -> void:
	K.surface(self, Vector2(-HALF, -120.0), Vector2(HALF, 95.0))
	K.surface(self, Vector2(-150.0, -EW), Vector2(150.0, EW))
	for sz in [-1, 1]:
		for sx in [-1, 1]:
			K.surface(self, Vector2(minf(sx * HALF, sx * (HALF + WALK)), minf(sz * (EW + WALK), sz * 95.0)),
				Vector2(maxf(sx * HALF, sx * (HALF + WALK)), maxf(sz * (EW + WALK), sz * 95.0)), K.SIDEWALK, 0.03)
			K.surface(self, Vector2(minf(sx * (HALF + 7.5), sx * 150.0), minf(sz * EW, sz * (EW + WALK))),
				Vector2(maxf(sx * (HALF + 7.5), sx * 150.0), maxf(sz * EW, sz * (EW + WALK))), K.SIDEWALK, 0.03)
	var xs := [-6.7, -3.5, 0.0, 3.5, 6.7]
	lines_ns(xs, ["edge", "dash", "dash", "dash", "edge"], STOP, 95.0)
	lines_ns(xs, ["edge", "dash", "dash", "dash", "edge"], -EW - 4.0, -120.0)
	var zs := [-6.7, -3.5, 0.0, 3.5, 6.7]
	lines_ew(zs, ["edge", "dash", "dash", "dash", "edge"], HALF + 7.5, 150.0)
	lines_ew(zs, ["edge", "dash", "dash", "dash", "edge"], -150.0, -HALF - 7.5)
	K.line(self, Vector2(-HALF, STOP), Vector2(HALF, STOP), K.WHITE, 0.4)
	K.line(self, Vector2(-HALF - 7.3, -EW), Vector2(-HALF - 7.3, EW), K.WHITE, 0.4)
	crosswalk(Vector2(-HALF, EW + 0.5), Vector2(HALF, EW + 3.5), "x")
	crosswalk(Vector2(-HALF - 6.8, -EW), Vector2(-HALF - 3.8, EW), "z")
	crosswalk(Vector2(HALF + 3.8, -EW), Vector2(HALF + 6.8, EW), "z")
	for z in [30.0, 70.0]:
		for lane_x in [-1.75, 1.75]:
			K.ground_text(self, "禁\n行\n機\n車", Vector2(lane_x, z), K.YELLOW)
		K.ground_text(self, "單\n行\n道", Vector2(-5.25, z + 15.0), K.WHITE, 0.0, 0.008)
	K.outline(self, BOX_MIN, BOX_MAX)
	K.ground_text(self, "機車\n待轉", (BOX_MIN + BOX_MAX) / 2.0, K.WHITE, -PI / 2.0, 0.004)

	# Right lane closed for construction all the way to the intersection.
	var z := 90.0
	while z > STOP + 2.0:
		model(ROADS + "construction-cone.glb", Vector3(3.9, 0, z), 0.0, 0.5, true)
		z -= 4.0
	for bz in [60.0, 35.0]:
		model(ROADS + "construction-barrier.glb", Vector3(5.25, 0, bz), 0.0, 3.0, true)
	sign_board("施工中\n外側車道封閉", Vector3(HALF + 1.2, 0, 75.0), 0.0, Color(0.9, 0.5, 0.1), 2.2)
	sign_board("機慢車\n兩段右轉", Vector3(-HALF - 1.2, 0, 40.0), 0.0, Color(0.15, 0.35, 0.75), 2.2)
	sign_board("銀行", Vector3(95.0, 0, EW + 1.5), PI, Color(0.1, 0.4, 0.7), 2.5)
	sign_board("重慶南路一段", Vector3(-HALF - 1.5, 0, 60.0), 0.0, Color(0.1, 0.35, 0.7), 3.0)
	_bookshops_and_tower()

	sig = TrafficSignal.new()
	add_child(sig)
	sig.setup(TrafficSignal.Phase.NS_GO, 14.0)
	sig.add_head(Vector3(-HALF - 1.5, 0, -EW - 4.0), "ns", Vector3.FORWARD)
	sig.add_head(Vector3(HALF + 2.5, 0, -EW - 1.5), "ew", Vector3.RIGHT)

	for sx in [-1, 1]:
		StreetDressing.ns_side(self, sx * HALF, 95.0, EW + WALK, sx, WALK)
		StreetDressing.ns_side(self, sx * HALF, -EW - WALK, -120.0, sx, WALK)
		buildings_ns(sx * (HALF + WALK + 8.0), EW + WALK, 95.0, -sx)
		buildings_ns(sx * (HALF + WALK + 8.0), -120.0, -EW - WALK, -sx)

	box = WaitBox.make(self, BOX_MIN, BOX_MAX)
	# Stopping to wait anywhere in the intersection (or next to the box) other than in it.
	box.turn_area = Rect2(Vector2(-HALF - 3.8, -EW), Vector2(2.0 * HALF + 3.8, 2.0 * EW))
	_add_rules()
	gps = [Vector3(-2.0, 0, 2.0), Vector3(95.0, 0, 0.0)]


## 重慶南路 used to be 書店街: vertical bookshop signs on both sides. At the end of the street, the
## red-brick 總統府 with its central tower. The bank on the right street gets a stone front.
func _bookshops_and_tower() -> void:
	var names := ["書局", "文具", "參考書", "出版社", "書局", "考試用書", "字典", "書局"]
	var colors := [Color(0.1, 0.35, 0.6), Color(0.6, 0.12, 0.12), Color(0.15, 0.45, 0.3)]
	var i := 0
	for sx in [-1, 1]:
		for z in [85.0, 72.0, 60.0, 48.0, 36.0, -20.0, -34.0, -50.0, -66.0, -82.0, -98.0]:
			StreetDressing._shop_sign(self, Vector3(sx * (HALF + WALK + 1.2), 0, z + sx * 3.0), sx,
				names[i % names.size()], colors[i % colors.size()], 4.5 + (i % 3) * 0.8)
			i += 1
	# 總統府: a long red-brick front with white bands, and the tall central tower.
	var brick := Color(0.7, 0.32, 0.22)
	var band := Color(0.92, 0.9, 0.85)
	var front := Vector3(0, 0, -250.0)
	K.box(self, Vector3(130.0, 20.0, 16.0), front + Vector3(0, 10.0, 0), brick)
	for y in [7.0, 14.0, 20.0]:
		K.box(self, Vector3(130.5, 0.8, 16.5), front + Vector3(0, y, 0), band)
	K.box(self, Vector3(14.0, 60.0, 14.0), front + Vector3(0, 30.0, 0), brick)
	for y in [22.0, 38.0, 54.0]:
		K.box(self, Vector3(14.5, 1.0, 14.5), front + Vector3(0, y, 0), band)
	K.box(self, Vector3(9.0, 8.0, 9.0), front + Vector3(0, 64.0, 0), band)
	# The bank: pale stone with columns.
	var bank := Vector3(95.0, 0, -EW - WALK - 8.0)
	K.box(self, Vector3(28.0, 16.0, 12.0), bank + Vector3(0, 8.0, 0), Color(0.82, 0.8, 0.74))
	for cx in [-9.0, -3.0, 3.0, 9.0]:
		K.box(self, Vector3(1.2, 10.0, 1.2), bank + Vector3(cx, 5.0, 6.5), Color(0.9, 0.88, 0.82))


func _add_rules() -> void:
	var fwd := Vector3.FORWARD
	ViolationZone.make(self, Vector2(0.5, -EW), Vector2(150.0, EW), "two_stage_right", "no_helmet",
		"少轉一段 600 ＞ 不戴安全帽 500：法律覺得你少等一個紅燈，比你的頭還危險。", Vector3.RIGHT) \
		.when(func() -> bool: return not box.waited)
	StopLineRule.make(self, sig, "ns", Vector3.FORWARD, Vector3(0, 0, STOP), -HALF, HALF)
	# Leaving the 待轉區 before the cross street turns green. (A direct right turn is two_stage_right instead.)
	ViolationZone.make(self, Vector2(-HALF, -EW), Vector2(HALF, EW), "red_light", "ped_red",
		"待轉區提早一秒出發＝闖紅燈 1,800，是行人闖紅燈（500）的 3.6 倍。", Vector3.RIGHT) \
		.when(func() -> bool: return box.waited and sig.is_red("ew"))
	ViolationZone.make(self, Vector2(-3.3, STOP), Vector2(3.3, 95.0), "lane_ban", "", "", fwd)
	# One-way streets: going against them is wrong-way.
	ViolationZone.make(self, Vector2(-HALF, -120.0), Vector2(HALF, 95.0), "wrong_way", "", "", Vector3.BACK)
	# Not inside the intersection or around the 待轉區, where riders legitimately swing west-ish.
	ViolationZone.make(self, Vector2(-150.0, -EW), Vector2(BOX_MIN.x - 2.0, EW), "wrong_way", "", "", Vector3.LEFT)
	ViolationZone.make(self, Vector2(HALF + 2.0, -EW), Vector2(150.0, EW), "wrong_way", "", "", Vector3.LEFT)
	ViolationZone.make(self, Vector2(-HALF - WALK, EW + WALK), Vector2(-HALF - CURB, 95.0), "sidewalk")
	goal(Vector2(90.0, -EW), Vector2(100.0, EW))
	# Cars stop at their stop line on red (yellow: go if you're already committed).
	var ns_go := func() -> bool: return not sig.is_red("ns")
	var ew_go := func() -> bool: return not sig.is_red("ew")
	traffic([Vector3(-1.75, 0, 60.0), Vector3(-1.75, 0, -120.0)] as Array[Vector3], 11.0, 4.0, Callable(), 0.0, Vector3(-1.75, 0, STOP), ns_go)
	traffic([Vector3(1.75, 0, 60.0), Vector3(1.75, 0, -120.0)] as Array[Vector3], 12.0, 5.0, Callable(), 2.0, Vector3(1.75, 0, STOP), ns_go)
	traffic([Vector3(-40.0, 0, 3.5), Vector3(150.0, 0, 3.5)] as Array[Vector3], 11.0, 3.0, Callable(), 0.0, Vector3(-HALF - 7.3, 0, 3.5), ew_go)
	# Scooters in the left lane with you, stopping on red.
	traffic([Vector3(-5.25, 0, 95.0), Vector3(-5.25, 0, -120.0)] as Array[Vector3], 9.0, 2.5, Callable(), 1.0, Vector3(-5.25, 0, STOP), ns_go, "scooter")
	for sx in [-1, 1]:
		pedestrians_ns(sx * (HALF + 2.2), 95.0, EW + WALK + 1.0, 4)
		pedestrians_ns(sx * (HALF + 2.2), -EW - WALK - 1.0, -120.0, 4)


func after_spawn() -> void:
	# Waiting at the eastbound stop line right behind the 待轉區 ("待撞區"); floors it 1.2 s after green.
	var path: Array[Vector3] = [Vector3(-HALF - 10.5, 0, -5.25), Vector3(150.0, 0, -5.25)]
	rusher = NpcVehicle.make(self, CARS + "taxi.glb", 4.4, path, 10.0)
	rusher.hold = true
	rusher.yields = false  # it is supposed to hit you
	rusher.target = scooter
	rusher.touched.connect(func() -> void:
		fail("待轉區又叫「待撞區」：綠燈一亮，後面的計程車就衝過來了。"))


func _physics_process(delta: float) -> void:
	if rusher.hold and sig.state("ew") == "green":
		_rush_timer += delta
		if _rush_timer > 1.2:
			rusher.hold = false
			Game.sfx.play("horn")
