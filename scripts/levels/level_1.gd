extends LevelBase
## Level 1 — 空蕩蕩的內側車道 (tutorial).
## A straight 3+3 lane arterial. Lanes 1–2 northbound are 禁行機車 and completely empty;
## the outer lane is full of illegally parked vehicles you have to thread past.

const HALF := 10.5
const WALK := 4.0
const Z_START := 40.0
const Z_END := -320.0


func _init() -> void:
	title = "空蕩蕩的內側車道"
	who = "上班族・07:52"
	objective = "八點打卡，今天再遲到就沒有全勤獎金了。公司在這條路直走到底。"
	deadline = 40.0
	deadline_name = "打卡"
	place = "公司"
	waiting_person = false
	ending = "打卡機：「嗶——07:59:58」\n全勤獎金保住了。"
	late_ending = "打卡機：「嗶——08:00:03」\n全勤獎金，下個月見。"


func spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(8.75, 0.1, 20.0))


func build() -> void:
	K.surface(self, Vector2(-HALF, Z_END), Vector2(HALF, Z_START))
	K.surface(self, Vector2(HALF, Z_END), Vector2(HALF + WALK, Z_START), K.SIDEWALK, 0.03)
	K.surface(self, Vector2(-HALF - WALK, Z_END), Vector2(-HALF, Z_START), K.SIDEWALK, 0.03)
	lines_ns([-10.2, -7.0, -3.5, 0.0, 3.5, 7.0, 10.2],
		["edge", "dash", "dash", "yellow2", "dash", "dash", "edge"], Z_START, Z_END)
	var z := 0.0
	while z > Z_END + 20.0:
		for lane_x in [1.75, 5.25]:
			K.ground_text(self, "禁\n行\n機\n車", Vector2(lane_x, z), K.YELLOW)
		z -= 50.0
	StreetDressing.ns_side(self, HALF, Z_START, Z_END, 1, WALK, [[-157.0, -147.0]])
	StreetDressing.ns_side(self, -HALF, Z_START, Z_END, -1, WALK)
	buildings_ns(HALF + WALK + 8.0, Z_END, Z_START, -1)
	buildings_ns(-HALF - WALK - 8.0, Z_END, Z_START, 1)

	# The outer lane's obstacle course (all facing north).
	var parked := [["delivery", -40.0, 6.0], ["sedan", -90.0, 4.5], ["truck", -130.0, 6.5],
		["delivery", -175.0, 6.0], ["taxi", -215.0, 4.5], ["van", -250.0, 5.0]]
	for p in parked:
		model(CARS + p[0] + ".glb", Vector3(9.5, 0, p[1]), PI, p[2], true)
	sign_board("股份有限公司", Vector3(HALF + 1.5, 0, -300.0), -PI / 2.0, Color(0.3, 0.3, 0.35), 2.5)

	ViolationZone.make(self, Vector2(0.3, Z_END), Vector2(6.8, Z_START), "lane_ban", "ped_red,sidewalk",
		"在一條空無一車的車道上騎車 600，比行人闖紅燈（500）還貴。", Vector3.FORWARD)
	ViolationZone.make(self, Vector2(-HALF, Z_END), Vector2(-0.3, Z_START), "wrong_way")
	ViolationZone.make(self, Vector2(HALF + CURB, Z_END), Vector2(HALF + WALK, Z_START), "sidewalk", "lane_ban",
		"騎上人行道閃違停，跟騎進空的內側車道，罰一樣多。")
	ViolationZone.make(self, Vector2(-HALF - WALK, Z_END), Vector2(-HALF - CURB, Z_START), "sidewalk")
	goal(Vector2(7.0, -300.0), Vector2(HALF, -290.0))
	# 老阿伯 steps out between the parked truck and delivery van.
	darter("uncle", Vector3(12.5, 0, -152.0), Vector3(-12.0, 0, -152.0), 42.0)
	traffic([Vector3(-5.25, 0, Z_END), Vector3(-5.25, 0, Z_START + 20.0)] as Array[Vector3], 12.0, 4.0)
	traffic([Vector3(-1.75, 0, Z_END), Vector3(-1.75, 0, Z_START + 20.0)] as Array[Vector3], 13.0, 6.5, Callable(), 2.0)
	# Oncoming scooters in their outer lane; pedestrians on both sidewalks.
	traffic([Vector3(-8.75, 0, Z_END), Vector3(-8.75, 0, Z_START + 20.0)] as Array[Vector3], 11.0, 2.2, Callable(), 0.5, Vector3.INF, Callable(), "scooter")
	pedestrians_ns(HALF + 2.2, Z_START, Z_END, 7)
	pedestrians_ns(-HALF - 2.2, Z_START, Z_END, 7)
	gps = [Vector3(8.75, 0, -295.0)]

var truck: NpcVehicle
var truck_hit := false


func after_spawn() -> void:
	if not Game.ambient:
		return
	# Near the end, a southbound 聯結車 swings across the double yellow into your side.
	# Gentle waypoints: the trailer swings with each heading change, so no sharp kinks, and it only
	# drifts back after it has passed you.
	var path: Array[Vector3] = [Vector3(-5.25, 0, -340.0), Vector3(-5.25, 0, -305.0), Vector3(-2.0, 0, -299.0),
		Vector3(2.5, 0, -292.0), Vector3(6.3, 0, -284.0), Vector3(6.3, 0, -225.0), Vector3(2.5, 0, -217.0),
		Vector3(-2.0, 0, -210.0), Vector3(-5.25, 0, -204.0), Vector3(-5.25, 0, 80.0)]
	truck = NpcVehicle.make_custom(self, semi_truck(), AABB(Vector3(-1.3, 0, -11.0), Vector3(2.6, 4.0, 16.0)), path, 12.0)
	truck.target = scooter
	truck.yields = false  # it is supposed to come at you
	# Timed so it's in your lane about when a rider at ~36 km/h gets there.
	truck.trigger_distance = 128.0
	truck.touched.connect(func() -> void:
		if _ended:
			return
		truck_hit = true
		Game.sfx.play("crash")
		Game.report("oncoming_truck", "lane_ban",
			"撞你的聯結車跨雙黃線逆向：只開這條的話罰 1,400。\n你剛剛如果騎進空的內側車道：600。", false))

