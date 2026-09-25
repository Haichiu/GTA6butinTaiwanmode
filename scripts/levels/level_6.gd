extends LevelBase
## Level 6 — 導航叫你上國道.
## The GPS routes you onto the freeway (scooters: 4,000). Staying on the provincial road is legal,
## but a truck crosses the double yellow line straight at you — and would pay only 1,400.

const HALF := 7.0  # provincial road, 2+2 lanes
const SHOULDER := 9.5  # right shoulder outer edge (x)
const HWY_MIN := 30.0  # freeway, x in [HWY_MIN, HWY_MAX]
const HWY_MAX := 44.0
const RAMP_FROM := Vector2(8.5, -55.0)
const RAMP_TO := Vector2(35.0, -135.0)
const Z_END := -460.0

var truck: NpcVehicle
var truck_hit := false


func _init() -> void:
	title = "導航叫你上國道"
	objective = "導航說：「走國道可以省 20 分鐘。」目的地在這條路直走 400 公尺。"


func spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(5.25, 0.1, 40.0))


func build() -> void:
	K.surface(self, Vector2(-HALF, Z_END), Vector2(SHOULDER, 60.0))
	lines_ns([-6.7, -3.5, 0.0, 3.5, 7.0], ["edge", "dash", "yellow2", "dash", "edge"], 60.0, Z_END)
	# On-ramp: a rotated strip from the provincial road up to the freeway.
	var ramp := RAMP_TO - RAMP_FROM
	var mid := (RAMP_FROM + RAMP_TO) / 2.0
	var strip := K.box(self, Vector3(8.0, 0.02, ramp.length()), Vector3(mid.x, 0.025, mid.y), K.ASPHALT)
	strip.rotation.y = atan2(ramp.x, ramp.y)
	# Freeway.
	K.surface(self, Vector2(HWY_MIN, Z_END), Vector2(HWY_MAX, -120.0))
	lines_ns([HWY_MIN + 0.3, HWY_MIN + 4.9, HWY_MIN + 9.5, HWY_MAX - 0.3], ["edge", "dash", "dash", "edge"], -125.0, Z_END)
	K.box(self, Vector3(0.3, 0.9, -140.0 - Z_END), Vector3(HWY_MIN - 1.5, 0.45, (-140.0 + Z_END) / 2.0), Color(0.7, 0.7, 0.72))
	sign_board("國道1號　往台北 ↗\n省 20 分鐘", Vector3(SHOULDER + 2.0, 0, -30.0), 0.0, Color(0.1, 0.5, 0.25), 4.5)
	sign_board("機車\n禁止進入", Vector3(RAMP_FROM.x + 6.0, 0, RAMP_FROM.y - 12.0), 0.0, Color(0.85, 0.15, 0.15), 1.8)
	sign_board("目的地", Vector3(SHOULDER + 1.5, 0, -425.0), -PI / 2.0, Color(0.1, 0.55, 0.25), 2.5)
	buildings_ns(-HALF - 14.0, Z_END, 60.0, 1)

	for zone in [[Vector2(14.0, -125.0), Vector2(HWY_MIN - 1.0, -65.0)], [Vector2(HWY_MIN - 1.0, Z_END), Vector2(HWY_MAX, -115.0)]]:
		ViolationZone.make(self, zone[0], zone[1], "highway_scooter", "oncoming_truck,car_speeding,turn_no_yield",
			"機車上國道 4,000 ＞ 聯結車逆向 1,400＋汽車超速 1,600＋轉彎不讓直行車 900。三條加起來，還找你 100 元。")
	ViolationZone.make(self, Vector2(-HALF, Z_END), Vector2(-0.3, 60.0), "wrong_way")
	goal(Vector2(0.3, -430.0), Vector2(SHOULDER, -420.0))
	gps = [Vector3(RAMP_FROM.x + 3.0, 0, RAMP_FROM.y - 10.0), Vector3(RAMP_TO.x, 0, RAMP_TO.y),
		Vector3(37.0, 0, -300.0), Vector3(5.25, 0, -425.0)]
	# Ride past the on-ramp and the GPS gives up on the freeway.
	on_enter(Vector2(0.3, -150.0), Vector2(SHOULDER, -140.0), func() -> void:
		gps = [Vector3(5.25, 0, -425.0)]
		_gps_index = 0
		toast("導航：已重新規劃路線，預計多花 20 分鐘。"))


func after_spawn() -> void:
	# The truck comes south in its own lane, drifts across the double yellow into yours, then back.
	var path: Array[Vector3] = [Vector3(-3.5, 0, Z_END + 10.0), Vector3(-3.5, 0, -340.0), Vector3(3.8, 0, -310.0),
		Vector3(3.8, 0, -240.0), Vector3(-3.5, 0, -210.0), Vector3(-3.5, 0, 80.0)]
	truck = NpcVehicle.make_custom(self, _semi_truck(), AABB(Vector3(-1.3, 0, -11.0), Vector3(2.6, 4.0, 16.0)), path, 12.0)
	truck.target = scooter
	# Timed so the truck is in your lane roughly when a rider at full speed gets there.
	truck.trigger_distance = 330.0
	truck.touched.connect(_on_truck_hit)


## 聯結車: Kenney truck cab in front (+Z) pulling a long box trailer.
func _semi_truck() -> Node3D:
	var root := Node3D.new()
	var cab: Node3D = load(CARS + "truck.glb").instantiate()
	var holder := Node3D.new()
	holder.add_child(cab)
	var aabb := LevelBase.aabb_of(cab)
	holder.scale = Vector3.ONE * (2.6 / aabb.size.x)
	holder.position.z = 2.0
	root.add_child(holder)
	K.box(root, Vector3(2.6, 3.0, 11.0), Vector3(0, 2.1, -5.5), Color(0.85, 0.85, 0.82))
	K.box(root, Vector3(2.4, 0.3, 11.0), Vector3(0, 0.45, -5.5), Color(0.2, 0.2, 0.2))
	for z in [-8.5, -9.8]:
		K.box(root, Vector3(2.7, 0.9, 0.9), Vector3(0, 0.45, z), Color(0.1, 0.1, 0.1))
	return root


func _on_truck_hit() -> void:
	if _ended:
		return
	truck_hit = true
	Game.report("oncoming_truck", "highway_scooter",
		"撞到你的聯結車跨雙黃線逆向：只開跨雙黃線的話，罰 1,400。\n你剛剛如果騎上國道：罰 4,000。", false)
