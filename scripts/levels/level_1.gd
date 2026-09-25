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
	objective = "騎到 300 公尺外的便當店。機車只能騎最外側車道。（方向鍵／WASD）"


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
	buildings_ns(HALF + WALK + 8.0, Z_END, Z_START, -1)
	buildings_ns(-HALF - WALK - 8.0, Z_END, Z_START, 1)

	# The outer lane's obstacle course (all facing north).
	var parked := [["delivery", -40.0, 6.0], ["sedan", -90.0, 4.5], ["truck", -130.0, 6.5],
		["delivery", -175.0, 6.0], ["taxi", -215.0, 4.5], ["van", -250.0, 5.0]]
	for p in parked:
		model(CARS + p[0] + ".glb", Vector3(9.5, 0, p[1]), PI, p[2], true)
	sign_board("便當", Vector3(HALF + 1.5, 0, -300.0), -PI / 2.0, Color(0.8, 0.25, 0.15), 2.5)

	ViolationZone.make(self, Vector2(0.3, Z_END), Vector2(6.8, Z_START), "lane_ban", "ped_red,sidewalk",
		"在一條空無一車的車道上騎車 600，比行人闖紅燈（500）還貴。", Vector3.FORWARD)
	ViolationZone.make(self, Vector2(-HALF, Z_END), Vector2(-0.3, Z_START), "wrong_way")
	ViolationZone.make(self, Vector2(HALF + CURB, Z_END), Vector2(HALF + WALK, Z_START), "sidewalk", "lane_ban",
		"騎上人行道閃違停，跟騎進空的內側車道，罰一樣多。")
	ViolationZone.make(self, Vector2(-HALF - WALK, Z_END), Vector2(-HALF - CURB, Z_START), "sidewalk")
	goal(Vector2(7.0, -300.0), Vector2(HALF, -290.0))
	gps = [Vector3(8.75, 0, -295.0)]
