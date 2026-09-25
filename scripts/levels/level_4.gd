extends LevelBase
## Level 4 — 兩段式「右」轉.
## One-way road, four lanes. Scooters may use only the outermost lanes; the right one is closed for
## construction, so you're in the left lane. 道路交通安全規則 99-2-2: on a one-way road with 3+
## lanes, a scooter in the left lane must turn RIGHT in two stages. Destination: to the right.

const HALF := 7.0  # 4 lanes, all northbound
const WALK := 4.0
const EW := 7.0  # cross street, one-way eastbound, 4 lanes
const STOP := 11.5
const BOX_MIN := Vector2(-11.0, -6.8)  # 待轉區 at the far-left corner, facing east
const BOX_MAX := Vector2(-8.0, -3.8)

var sig: TrafficSignal
var box: WaitBox


func _init() -> void:
	title = "兩段式「右」轉"
	objective = "右轉去銀行。單行道、你騎在左側車道……右轉也要兩段式。"


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
	K.zebra(self, Vector2(-HALF, EW + 0.5), Vector2(HALF, EW + 3.5), "x")
	K.zebra(self, Vector2(-HALF - 6.8, -EW), Vector2(-HALF - 3.8, EW), "z")
	K.zebra(self, Vector2(HALF + 3.8, -EW), Vector2(HALF + 6.8, EW), "z")
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

	sig = TrafficSignal.new()
	add_child(sig)
	sig.setup(TrafficSignal.Phase.NS_GO, 14.0)
	sig.add_head(Vector3(-HALF - 1.5, 0, -EW - 4.0), "ns", Vector3.FORWARD)
	sig.add_head(Vector3(HALF + 2.5, 0, -EW - 1.5), "ew", Vector3.RIGHT)

	for sx in [-1, 1]:
		buildings_ns(sx * (HALF + WALK + 8.0), EW + WALK, 95.0, -sx)
		buildings_ns(sx * (HALF + WALK + 8.0), -120.0, -EW - WALK, -sx)

	box = WaitBox.make(self, BOX_MIN, BOX_MAX)
	_add_rules()
	gps = [Vector3(-2.0, 0, 2.0), Vector3(95.0, 0, 0.0)]


func _add_rules() -> void:
	var fwd := Vector3.FORWARD
	ViolationZone.make(self, Vector2(0.5, -EW), Vector2(150.0, EW), "two_stage_right", "no_helmet",
		"少了一段待轉罰 600；少了一頂安全帽罰 500。", Vector3.RIGHT).when(func() -> bool: return not box.waited)
	ViolationZone.make(self, Vector2(-HALF, EW + 0.5), Vector2(HALF, STOP - 0.2), "red_light", "", "", fwd) \
		.when(func() -> bool: return sig.is_red("ns"))
	# Leaving the 待轉區 before the cross street turns green. (A direct right turn is two_stage_right instead.)
	ViolationZone.make(self, Vector2(-HALF, -EW), Vector2(HALF, EW), "red_light", "", "", Vector3.RIGHT) \
		.when(func() -> bool: return box.waited and sig.is_red("ew"))
	ViolationZone.make(self, Vector2(-3.3, STOP), Vector2(3.3, 95.0), "lane_ban", "", "", fwd)
	# One-way streets: going against them is wrong-way.
	ViolationZone.make(self, Vector2(-HALF, -120.0), Vector2(HALF, 95.0), "wrong_way", "", "", Vector3.BACK)
	# Not inside the intersection or around the 待轉區, where riders legitimately swing west-ish.
	ViolationZone.make(self, Vector2(-150.0, -EW), Vector2(BOX_MIN.x - 2.0, EW), "wrong_way", "", "", Vector3.LEFT)
	ViolationZone.make(self, Vector2(HALF + 2.0, -EW), Vector2(150.0, EW), "wrong_way", "", "", Vector3.LEFT)
	ViolationZone.make(self, Vector2(-HALF - WALK, EW + WALK), Vector2(-HALF - CURB, 95.0), "sidewalk")
	goal(Vector2(90.0, -EW), Vector2(100.0, EW))
