extends LevelBase
## Level 3 — 兩段式左轉 (with Geomeme's 機車停等區: the box is full of cars).
## Destination is to the left. Legal: go straight on green, stop in the 待轉區 at the far-right
## corner, turn to face west, wait for the cross street's green, then go.

const HALF := 10.5  # arterial 3+3
const WALK := 4.0
const EW := 7.0  # cross street 2+2
const STOP := 11.5
# 待轉區 per the marking rules: in front of the crosswalk (x 14.3), rear edge >= 0.5 m from it,
# front edge not past the arterial's edge (x 10.5). Deliberately shallow: overshoot and you're on the zebra.
const BOX_MIN := Vector2(11.8, -6.6)
const BOX_MAX := Vector2(13.8, -4.2)

var sig: TrafficSignal
var box: WaitBox
var rusher: NpcVehicle  # the car behind the 待轉區 that floors it on green ("待撞區")
var _rush_timer := 0.0


func _init() -> void:
	title = "兩段式左轉"
	who = "孫子・06:40"
	objective = "阿嬤去巷口早餐店買蛋餅，打電話叫你去載她回家。\n早餐店在左邊那條巷子。"
	deadline = 45.0
	deadline_name = "阿嬤等到不耐煩"
	place = "阿嬤"
	waiting_person = true
	ending = "阿嬤跳上後座：「乖孫，蛋餅阿嬤請你，還燒燒！」"
	late_ending = "阿嬤：「等到蛋餅都冷了啦……沒要緊，阿嬤牙齒不好剛好。」"


func spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(9.8, 0.1, 80.0))


func build() -> void:
	K.surface(self, Vector2(-HALF, -120.0), Vector2(HALF, 95.0))
	K.surface(self, Vector2(-150.0, -EW), Vector2(150.0, EW))
	for sz in [-1, 1]:
		for sx in [-1, 1]:
			var z_near := EW + WALK
			K.surface(self, Vector2(minf(sx * HALF, sx * (HALF + WALK)), minf(sz * z_near, sz * 95.0)),
				Vector2(maxf(sx * HALF, sx * (HALF + WALK)), maxf(sz * z_near, sz * 95.0)), K.SIDEWALK, 0.03)
			K.surface(self, Vector2(minf(sx * (HALF + 7.5), sx * 150.0), minf(sz * EW, sz * (EW + WALK))),
				Vector2(maxf(sx * (HALF + 7.5), sx * 150.0), maxf(sz * EW, sz * (EW + WALK))), K.SIDEWALK, 0.03)
	var xs := [-10.2, -7.0, -3.5, 0.0, 3.5, 7.0, 10.2]
	lines_ns(xs, ["edge", "dash", "dash", "yellow2", "dash", "dash", "edge"], STOP, 95.0)
	lines_ns(xs, ["edge", "dash", "dash", "yellow2", "dash", "dash", "edge"], -STOP, -120.0)
	lines_ew([-6.7, -3.5, 0.0, 3.5, 6.7], ["edge", "dash", "yellow2", "dash", "edge"], HALF + 7.5, 150.0)
	lines_ew([-6.7, -3.5, 0.0, 3.5, 6.7], ["edge", "dash", "yellow2", "dash", "edge"], -150.0, -HALF - 7.5)
	K.line(self, Vector2(0.2, STOP), Vector2(HALF, STOP), K.WHITE, 0.4)
	K.line(self, Vector2(-HALF, -STOP), Vector2(-0.2, -STOP), K.WHITE, 0.4)
	K.line(self, Vector2(HALF + 7.3, -EW), Vector2(HALF + 7.3, -0.2), K.WHITE, 0.4)
	K.line(self, Vector2(-HALF - 7.3, 0.2), Vector2(-HALF - 7.3, EW), K.WHITE, 0.4)
	crosswalk(Vector2(-HALF, EW + 0.5), Vector2(HALF, EW + 3.5), "x")
	crosswalk(Vector2(-HALF, -EW - 3.5), Vector2(HALF, -EW - 0.5), "x")
	crosswalk(Vector2(HALF + 3.8, -EW), Vector2(HALF + 6.8, EW), "z")
	crosswalk(Vector2(-HALF - 6.8, -EW), Vector2(-HALF - 3.8, EW), "z")

	# Approach: 禁行機車 inside, 機車停等區 in the outer lane — occupied by cars.
	for z in [30.0, 70.0]:
		for lane_x in [1.75, 5.25]:
			K.ground_text(self, "禁\n行\n機\n車", Vector2(lane_x, z), K.YELLOW)
	K.outline(self, Vector2(7.2, STOP + 0.2), Vector2(HALF - 0.3, STOP + 5.0))
	K.ground_text(self, "機\n車", Vector2(8.75, STOP + 2.6), K.WHITE, 0.0, 0.006)
	model(CARS + "sedan.glb", Vector3(8.0, 0, STOP + 2.8), PI, 4.4, true)
	model(CARS + "suv.glb", Vector3(8.0, 0, STOP + 9.0), PI, 4.6, true)
	# 待轉區.
	K.outline(self, BOX_MIN, BOX_MAX)
	K.ground_text(self, "機車\n待轉", (BOX_MIN + BOX_MAX) / 2.0, K.WHITE, PI / 2.0, 0.004)

	sign_board("機慢車\n兩段左轉", Vector3(HALF + 1.2, 0, 40.0), 0.0, Color(0.15, 0.35, 0.75), 2.2)
	sign_board("科技執法\n違規取締", Vector3(HALF + 1.2, 0, 22.0), 0.0, Color(0.9, 0.75, 0.1), 2.2)
	sign_board("早餐", Vector3(-95.0, 0, -EW - 1.5), 0.0, Color(0.8, 0.25, 0.15), 2.5)

	sig = TrafficSignal.new()
	add_child(sig)
	sig.setup(TrafficSignal.Phase.NS_GO, 14.0)
	sig.add_head(Vector3(HALF + 1.5, 0, -EW - 4.0), "ns", Vector3.FORWARD)
	sig.add_head(Vector3(-HALF - 1.5, 0, EW + 4.0), "ns", Vector3.BACK)
	sig.add_head(Vector3(-HALF - 2.5, 0, -EW - 1.5), "ew", Vector3.LEFT)
	sig.add_head(Vector3(HALF + 2.5, 0, EW + 1.5), "ew", Vector3.RIGHT)

	for sx in [-1, 1]:
		StreetDressing.ns_side(self, sx * HALF, 95.0, EW + WALK, sx, WALK)
		StreetDressing.ns_side(self, sx * HALF, -EW - WALK, -120.0, sx, WALK)
		buildings_ns(sx * (HALF + WALK + 8.0), EW + WALK, 95.0, -sx)
		buildings_ns(sx * (HALF + WALK + 8.0), -120.0, -EW - WALK, -sx)

	box = WaitBox.make(self, BOX_MIN, BOX_MAX)
	# Stopping to wait anywhere in the intersection (or next to the box) other than in it.
	box.turn_area = Rect2(Vector2(-HALF, -EW), Vector2(HALF + 3.8 + HALF, 2.0 * EW))
	_add_rules()
	gps = [Vector3(5.0, 0, -2.0), Vector3(-95.0, 0, -3.5)]


func _add_rules() -> void:
	var fwd := Vector3.FORWARD
	ViolationZone.make(self, Vector2(-150.0, -EW), Vector2(-0.5, EW), "two_stage_left", "turn_no_yield,car_in_box",
		"你少停一次待轉區 600；汽車轉彎不讓直行車、把人撞飛，才 900。", Vector3.LEFT).when(func() -> bool: return not box.waited)
	StopLineRule.make(self, sig, "ns", Vector3.FORWARD, Vector3(0, 0, STOP), 0.3, HALF)
	# Leaving the 待轉區 before the cross street turns green. (A direct left turn is two_stage_left instead.)
	ViolationZone.make(self, Vector2(-HALF, -EW), Vector2(HALF, -0.3), "red_light", "ped_red",
		"待轉區提早一秒出發＝闖紅燈 1,800，是行人闖紅燈（500）的 3.6 倍。", Vector3.LEFT) \
		.when(func() -> bool: return box.waited and sig.is_red("ew"))
	ViolationZone.make(self, Vector2(0.3, STOP), Vector2(6.8, 95.0), "lane_ban", "car_in_box",
		"閃開霸佔停等區的汽車，你罰 600；那台汽車整台停在機車格裡，也才 900。", fwd)
	ViolationZone.make(self, Vector2(-HALF, -120.0), Vector2(-0.3, -EW - 0.5), "wrong_way")
	ViolationZone.make(self, Vector2(-HALF, EW + 0.5), Vector2(-0.3, 95.0), "wrong_way")
	ViolationZone.make(self, Vector2(HALF + CURB, EW + WALK), Vector2(HALF + WALK, 95.0), "sidewalk")
	goal(Vector2(-100.0, -EW), Vector2(-90.0, 0.0))
	# Cars stop at their stop line on red (yellow: go if you're already committed).
	var ns_go := func() -> bool: return not sig.is_red("ns")
	var ew_go := func() -> bool: return not sig.is_red("ew")
	traffic([Vector3(-5.25, 0, -60.0), Vector3(-5.25, 0, 95.0)] as Array[Vector3], 11.0, 3.5, Callable(), 0.0, Vector3(-5.25, 0, -STOP), ns_go)
	traffic([Vector3(5.25, 0, 60.0), Vector3(5.25, 0, -120.0)] as Array[Vector3], 11.0, 5.0, Callable(), 1.5, Vector3(5.25, 0, STOP), ns_go)
	traffic([Vector3(-40.0, 0, 3.5), Vector3(150.0, 0, 3.5)] as Array[Vector3], 11.0, 3.0, Callable(), 0.0, Vector3(-HALF - 7.3, 0, 3.5), ew_go)
	# Scooters squeeze past the cars in the 停等區 like you do, and stop on red.
	traffic([Vector3(9.9, 0, 95.0), Vector3(9.9, 0, STOP + 1.0), Vector3(8.75, 0, -10.0), Vector3(8.75, 0, -120.0)] as Array[Vector3], 9.0, 2.5,
		Callable(), 0.5, Vector3(9.9, 0, STOP), ns_go, "scooter")
	traffic([Vector3(-8.75, 0, -120.0), Vector3(-8.75, 0, 95.0)] as Array[Vector3], 10.0, 2.5, Callable(), 1.5, Vector3(-8.75, 0, -STOP), ns_go, "scooter")
	for sx in [-1, 1]:
		pedestrians_ns(sx * (HALF + 2.2), 95.0, EW + WALK + 1.0, 4)
		pedestrians_ns(sx * (HALF + 2.2), -EW - WALK - 1.0, -120.0, 4)


func after_spawn() -> void:
	# Waiting at the westbound stop line right behind the 待轉區; floors it 1.2 s after green.
	var path: Array[Vector3] = [Vector3(HALF + 10.0, 0, -5.25), Vector3(-150.0, 0, -5.25)]
	rusher = NpcVehicle.make(self, CARS + "sedan.glb", 4.4, path, 10.0)
	rusher.hold = true
	rusher.yields = false  # it is supposed to hit you
	rusher.target = scooter
	rusher.touched.connect(func() -> void:
		fail("待轉區又叫「待撞區」：綠燈一亮，後面的車就衝過來了。"))


func _physics_process(delta: float) -> void:
	if rusher.hold and sig.state("ew") == "green":
		_rush_timer += delta
		if _rush_timer > 1.2:
			rusher.hold = false
			Game.sfx.play("horn")
