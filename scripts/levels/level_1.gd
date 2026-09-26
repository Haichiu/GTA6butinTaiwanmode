extends LevelBase
## Level 1 — 空蕩蕩的內側車道 (tutorial).
## A straight 3+3 lane arterial. Lanes 1–2 northbound are 禁行機車 and completely empty;
## the outer lane is full of illegally parked vehicles you have to thread past.
## Setting: 高雄成功二路 by 夢時代 (自由時報 2024: right after the 輕軌 tracks the inner lanes
## suddenly turn 禁行機車; near the port and industrial zone, so lots of trucks).

const HALF := 10.5
const WALK := 4.0
const Z_START := 40.0
const Z_END := -320.0
const RAIL_Z := -62.0  # 輕軌 crossing; 禁行機車 starts right after it


func _init() -> void:
	title = "空蕩蕩的內側車道"
	who = "上班族・07:52"
	objective = "八點打卡，今天再遲到就沒有全勤獎金了。公司在這條路直走到底。"
	deadline = 50.0
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
	var z := RAIL_Z - 12.0
	while z > Z_END + 20.0:
		for lane_x in [1.75, 5.25]:
			K.ground_text(self, "禁\n行\n機\n車", Vector2(lane_x, z), K.YELLOW)
		z -= 50.0
	_light_rail()
	_harbour_skyline()
	street_plate("成功二路", Vector3(HALF + 1.0, 0, 30.0), 0.0, -2.5)
	StreetDressing.ns_side(self, HALF, Z_START, Z_END, 1, WALK, [[-157.0, -147.0]])
	StreetDressing.ns_side(self, -HALF, Z_START, Z_END, -1, WALK)
	buildings_ns(HALF + WALK + 8.0, Z_END, Z_START, -1)
	buildings_ns(-HALF - WALK - 8.0, Z_END, Z_START, 1)

	# The outer lane's obstacle course (all facing north).
	# Tutorial: four, well spaced, and none where the 聯結車 swings over.
	var parked := [["delivery", -40.0, 6.0], ["sedan", -90.0, 4.5], ["truck", -130.0, 6.5],
		["delivery", -175.0, 6.0]]
	for p in parked:
		model(CARS + p[0] + ".glb", Vector3(9.5, 0, p[1]), PI, p[2], true)
	sign_board("股份有限公司", Vector3(HALF + 1.5, 0, -300.0), -PI / 2.0, Color(0.3, 0.3, 0.35), 2.5)

	ViolationZone.make(self, Vector2(0.3, Z_END), Vector2(6.8, RAIL_Z - 5.0), "lane_ban", "ped_red,sidewalk",
		"過了輕軌，內側車道突然禁行機車。\n在一條空無一車的車道上騎車 600，比行人闖紅燈（500）還貴。", Vector3.FORWARD)
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

## The 環狀輕軌 crossing the road: two tracks, the grass track bed on either side of the road.
func _light_rail() -> void:
	var steel := Color(0.85, 0.85, 0.88)
	K.surface(self, Vector2(-HALF - WALK, RAIL_Z - 3.2), Vector2(HALF + WALK, RAIL_Z + 3.2), Color(0.3, 0.3, 0.31), 0.025)
	for side in [-1.0, 1.0]:
		K.surface(self, Vector2(minf(side * (HALF + WALK), side * 300.0), RAIL_Z - 3.2),
			Vector2(maxf(side * (HALF + WALK), side * 300.0), RAIL_Z + 3.2), Color(0.35, 0.55, 0.3), 0.025)
	for track in [-1.6, 1.6]:
		for rail in [-0.72, 0.72]:
			K.line(self, Vector2(-300.0, RAIL_Z + track + rail), Vector2(300.0, RAIL_Z + track + rail), steel, 0.1)
	# Overhead line poles either side of the road.
	for x in [-HALF - WALK - 2.0, HALF + WALK + 2.0]:
		K.box(self, Vector3(0.25, 6.5, 0.25), Vector3(x, 3.25, RAIL_Z), Color(0.5, 0.5, 0.52))
	sign_board("注意輕軌", Vector3(HALF + 1.2, 0, RAIL_Z + 12.0), 0.0, Color(0.9, 0.75, 0.1), 2.0)
	street_plate("凱旋四路", Vector3(HALF + 1.0, 0, RAIL_Z + 5.0), 0.0, -3.0)  # the tracks run along it here
	for x in [-HALF + 0.2, 0.2]:
		K.line(self, Vector2(x, RAIL_Z + 4.5), Vector2(x + HALF - 0.4, RAIL_Z + 4.5), K.WHITE, 0.4)  # stop lines before the tracks
	# A tram waiting on the grass track just off the road: white with a green stripe.
	var tram := Vector3(-HALF - WALK - 22.0, 0, RAIL_Z - 1.6)
	K.box(self, Vector3(34.0, 3.2, 2.6), tram + Vector3(0, 1.9, 0), Color(0.93, 0.94, 0.92))
	K.box(self, Vector3(34.1, 0.5, 2.7), tram + Vector3(0, 1.5, 0), Color(0.2, 0.6, 0.35))
	K.box(self, Vector3(33.0, 0.9, 2.7), tram + Vector3(0, 2.6, 0), Color(0.2, 0.25, 0.3))  # windows


## What you see down 成功二路: harbour gantry cranes to the west, the 85 大樓 ahead,
## the 夢時代 ferris wheel over the rooftops.
func _harbour_skyline() -> void:
	for i in 5:
		_gantry_crane(Vector3(-190.0 - (i % 2) * 22.0, 0, -120.0 - i * 55.0))
	_tower_85(Vector3(-25.0, 0, -470.0))
	_ferris_wheel(Vector3(-80.0, 0, -240.0), 24.0)


func _gantry_crane(pos: Vector3) -> void:
	var blue := Color(0.2, 0.4, 0.7)
	for dx in [-6.0, 6.0]:
		for dz in [-4.0, 4.0]:
			K.box(self, Vector3(1.0, 32.0, 1.0), pos + Vector3(dx, 16.0, dz), blue)
	K.box(self, Vector3(14.0, 1.5, 9.0), pos + Vector3(0, 32.0, 0), blue)
	K.box(self, Vector3(56.0, 2.0, 2.0), pos + Vector3(-12.0, 30.0, 0), blue)  # boom out over the water


## 高雄 85 大樓: two towers joined into one, a gap in the middle, a spire on top.
func _tower_85(pos: Vector3) -> void:
	var glass := Color(0.45, 0.55, 0.62)
	for dx in [-14.0, 14.0]:
		K.box(self, Vector3(18.0, 150.0, 30.0), pos + Vector3(dx, 75.0, 0), glass)
	K.box(self, Vector3(46.0, 80.0, 30.0), pos + Vector3(0, 190.0, 0), glass)
	K.box(self, Vector3(22.0, 60.0, 22.0), pos + Vector3(0, 260.0, 0), glass)
	K.box(self, Vector3(2.0, 50.0, 2.0), pos + Vector3(0, 315.0, 0), Color(0.7, 0.7, 0.72))


func _ferris_wheel(pos: Vector3, r: float) -> void:
	var wheel := Node3D.new()
	wheel.position = pos + Vector3(0, 30.0 + r, 0)
	wheel.rotation.y = PI / 2.0
	add_child(wheel)
	for i in 16:
		var a := TAU * i / 16.0
		var spoke := K.box(wheel, Vector3(0.3, r, 0.3), Vector3(cos(a), sin(a), 0) * r / 2.0, Color(0.9, 0.9, 0.92))
		spoke.rotation.z = a - PI / 2.0
		var cabin := K.box(wheel, Vector3(2.0, 2.0, 2.0), Vector3(cos(a), sin(a), 0) * r,
			[Color(0.9, 0.3, 0.3), Color(0.3, 0.6, 0.9), Color(0.95, 0.8, 0.2)][i % 3])
		cabin.rotation.z = 0.0
	K.box(self, Vector3(40.0, 30.0, 40.0), pos + Vector3(0, 15.0, 0), Color(0.75, 0.72, 0.68))  # the mall roof it sits on


var truck: NpcVehicle
var truck_hit := false


func after_spawn() -> void:
	if not Game.ambient:
		return
	# Near the end, a southbound 聯結車 swings across the double yellow into your side — into the
	# empty 禁行機車 lanes. It's a scare for a rider who kept right; it only gets you if you're in
	# the lanes you weren't allowed in (tutorial level: the outer lane is the safe one).
	# Gentle waypoints: the trailer swings with each heading change, so no sharp kinks.
	var path: Array[Vector3] = [Vector3(-5.25, 0, -340.0), Vector3(-5.25, 0, -305.0), Vector3(-2.0, 0, -299.0),
		Vector3(1.5, 0, -292.0), Vector3(4.2, 0, -284.0), Vector3(4.2, 0, -225.0), Vector3(1.5, 0, -217.0),
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

