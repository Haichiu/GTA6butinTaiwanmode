extends LevelBase
## Level 7 — 後龍死亡彎 (台61 西濱後龍段, 龍港; see docs/laws.md for sources).
## As riders described it (自由時報 2022-08-17 陳情記者會, 民視 2023 實測):
## there is no separate scooter lane. You ride the expressway's outer *mixed* lane with the cars;
## right after getting on the bridge it suddenly becomes 禁行機車 and a row of 棒棒糖 squeezes
## scooters into a narrow, broken strip against the 紐澤西護欄 — gravel, debris, no warning sign.
## Then a sudden 90° turn and a 180° U-turn before you rejoin the same road.

const CAR_W := 7.0  # main lanes, 2 each way: x in [-7, 7]
const MIX_MAX := 10.9  # outer mixed lane x in [7, 10.9] until the squeeze
const POST_X := 9.0  # the 棒棒糖 row that splits the mixed lane
const BARRIER_X := 11.15  # 紐澤西護欄 centre (inner face ~10.9)
const LANE_X := 10.0  # the scooter strip's centreline, strip x in [9.1, 10.9]
const STRIP_W := 1.8
const SQUEEZE_Z := 30.0  # where 禁行機車 starts — on the bridge
const BRIDGE_Z := [70.0, 20.0]
# The detour: the strip is closed between BLOCK_START and BLOCK_END; a sharp 90° right, a 180°
# U-turn, and a 90° back onto the very same strip.
const BLOCK_START := -100.0
const BLOCK_END := -118.0
const TURN_R := 4.0
const DW := 2.2  # detour width
const LOOP_X := 20.0
const ROUGH_END := -190.0  # where the broken surface ends
const Z_END := -540.0
const GRAVEL := Color(0.55, 0.5, 0.42)


func _init() -> void:
	title = "後龍死亡彎"
	who = "大學生・週五 17:40"
	objective = "週五沒課，沿著西濱騎回家過週末。媽媽說今晚滷了一鍋肉。\n導航：「沿著西濱一直直走就到了。」"
	deadline = 100.0
	deadline_name = "滷肉上桌"
	place = "家"
	waiting_person = true
	ending = "媽媽：「回來啦！怎麼一身砂？」"
	late_ending = "媽媽：「滷肉都涼了……西濱又怎麼了？」"


func spawn_transform() -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(9.8, 0.1, 60.0))


## Centerline of the detour as (center, radius, a0, a1) arcs and straight pieces, in riding order.
func _pieces() -> Array:
	var z_out := BLOCK_START - TURN_R
	var z_back := BLOCK_END + TURN_R
	return [
		["arc", Vector2(LANE_X + TURN_R, BLOCK_START), TURN_R, PI, 1.5 * PI],  # north -> east, sharp
		["line", Vector2(LANE_X + TURN_R, z_out), Vector2(LOOP_X, z_out)],
		["arc", Vector2(LOOP_X, (z_out + z_back) / 2.0), (z_out - z_back) / 2.0, 0.5 * PI, -0.5 * PI],  # U-turn
		["line", Vector2(LOOP_X, z_back), Vector2(LANE_X + TURN_R, z_back)],
		["arc", Vector2(LANE_X + TURN_R, BLOCK_END), TURN_R, 0.5 * PI, PI],  # west -> north, back on the strip
	]


func build() -> void:
	# Main lanes plus the outer mixed lane, one surface.
	K.surface(self, Vector2(-CAR_W, Z_END), Vector2(MIX_MAX, 70.0))
	lines_ns([-6.7, -3.5, 0.0, 3.5, 7.0], ["edge", "dash", "yellow2", "dash", "dash"], 70.0, Z_END)
	sign_board("台61 西濱快速公路", Vector3(-CAR_W - 1.5, 0, 50.0), 0.0, Color(0.1, 0.45, 0.25), 3.0)
	# The squeeze: 禁行機車 painted in the mixed lane, 棒棒糖 down the middle of it, and the strip.
	for z in [SQUEEZE_Z - 6.0, -40.0, -160.0, -300.0]:
		K.ground_text(self, "禁\n行\n機\n車", Vector2(8.0, z), K.YELLOW, 0.0, 0.010)
	K.post_row(self, Vector2(POST_X, SQUEEZE_Z), Vector2(POST_X, Z_END), 1.6)
	# 紐澤西護欄 on the right the whole way (opened where the detour leaves and rejoins).
	_barrier(Vector2(BARRIER_X, 70.0), Vector2(BARRIER_X, BLOCK_START + 1.0))
	_barrier(Vector2(BARRIER_X, BLOCK_END - 1.0), Vector2(BARRIER_X, Z_END))
	K.glare_screen(self, Vector2(BARRIER_X, 20.0), Vector2(BARRIER_X, BLOCK_START + 2.0))
	K.glare_screen(self, Vector2(BARRIER_X, BLOCK_END - 2.0), Vector2(BARRIER_X, Z_END))
	# The closed stretch of strip: chevrons.
	var z := BLOCK_START - 2.0
	while z > BLOCK_END + 2.0:
		K.line(self, Vector2(POST_X + 0.3, z), Vector2(MIX_MAX - 0.3, z - 1.2), K.YELLOW, 0.25)
		z -= 2.2
	# Detour: narrow, posts both sides, 紐澤西護欄 behind the outer posts.
	for piece in _pieces():
		if piece[0] == "arc":
			K.arc_surface(self, piece[1], piece[2] - DW / 2.0, piece[2] + DW / 2.0, piece[3], piece[4])
			for side in [-1.0, 1.0]:
				K.arc_posts(self, piece[1], piece[2] + side * (DW / 2.0 + 0.25), piece[3], piece[4], 1.2)
		else:
			var a: Vector2 = piece[1]
			var b: Vector2 = piece[2]
			K.surface(self, Vector2(minf(a.x, b.x), a.y - DW / 2.0), Vector2(maxf(a.x, b.x), a.y + DW / 2.0))
			for side in [-1.0, 1.0]:
				K.line_posts(self, Vector2(a.x, a.y + side * (DW / 2.0 + 0.25)), Vector2(b.x, b.y + side * (DW / 2.0 + 0.25)), 1.2)
	var hairpin: Array = _pieces()[2]
	var steps := 14
	for i in steps:
		var p0 := K.on_arc(hairpin[1], hairpin[2] + DW / 2.0 + 1.0, lerpf(hairpin[3], hairpin[4], float(i) / steps))
		var p1 := K.on_arc(hairpin[1], hairpin[2] + DW / 2.0 + 1.0, lerpf(hairpin[3], hairpin[4], float(i + 1) / steps))
		_barrier(p0, p1)
	_broken_surface()
	_real_surroundings()
	_add_rules()


## A concrete 紐澤西護欄 segment (solid, counts as a guardrail for crashes).
func _barrier(from: Vector2, to: Vector2) -> void:
	var d := to - from
	var mid := (from + to) / 2.0
	var body := K.box(self, Vector3(0.5, 0.85, d.length() + 0.05), Vector3(mid.x, 0.425, mid.y), Color(0.72, 0.71, 0.68), true)
	body.rotation.y = atan2(d.x, d.y)
	body.add_to_group("guardrail")


## The strip's surface: patched asphalt, gravel everywhere, debris against the barrier.
func _broken_surface() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2022
	# Darker patches.
	var z := SQUEEZE_Z
	while z > ROUGH_END:
		var seg := rng.randf_range(2.0, 6.0)
		K.surface(self, Vector2(POST_X + 0.2, z - seg), Vector2(MIX_MAX - 0.1, z), Color(0.19, 0.19, 0.2), 0.022)
		z -= seg + rng.randf_range(3.0, 9.0)
	# Gravel on the strip and around the bends.
	for i in 220:
		var p := Vector2(rng.randf_range(POST_X + 0.2, MIX_MAX - 0.1), rng.randf_range(ROUGH_END, SQUEEZE_Z))
		K.box(self, Vector3(0.15, 0.04, 0.15), Vector3(p.x, 0.05, p.y), GRAVEL)
	for piece in _pieces():
		if piece[0] != "arc":
			continue
		for i in 30:
			var p := K.on_arc(piece[1], piece[2] + rng.randf_range(-0.9, 0.9), lerpf(piece[3], piece[4], rng.randf()))
			K.box(self, Vector3(0.15, 0.04, 0.15), Vector3(p.x, 0.05, p.y), GRAVEL)
	# Debris by the barrier: fallen cones, broken concrete. The concrete is solid.
	z = SQUEEZE_Z - 12.0
	while z > ROUGH_END:
		if z < BLOCK_START + 4.0 and z > BLOCK_END - 4.0:
			z -= 6.0
			continue
		if rng.randf() < 0.5:
			var cone := model(ROADS + "construction-cone.glb", Vector3(MIX_MAX - 0.25, 0, z), rng.randf_range(0, TAU), 0.5)
			cone.rotation.z = PI / 2.0  # knocked over
		else:
			var chunk := K.box(self, Vector3(0.35, 0.25, 0.5), Vector3(MIX_MAX - 0.2, 0.125, z), Color(0.6, 0.6, 0.58), true)
			chunk.add_to_group("guardrail")
		z -= rng.randf_range(14.0, 28.0)


## Around it: the 後龍溪 bridge you start on, the bridge-rebuilding works to the east, the coast
## railway and 龍港 platform to the west, wooded hills, the retaining wall inside the U-turn.
func _real_surroundings() -> void:
	K.surface(self, Vector2(-200.0, BRIDGE_Z[1]), Vector2(200.0, BRIDGE_Z[0]), Color(0.1, 0.24, 0.36), 0.01)
	K.box(self, Vector3(0.3, 1.1, BRIDGE_Z[0] - BRIDGE_Z[1]), Vector3(-CAR_W - 0.3, 0.55, (BRIDGE_Z[0] + BRIDGE_Z[1]) / 2.0), Color(0.72, 0.72, 0.74), true)
	sign_board("後龍溪橋", Vector3(BARRIER_X + 1.5, 0, 66.0), 0.0, Color(0.1, 0.45, 0.25), 2.6)
	# The works: the new bridge going up beside the old one. A temporary steel trestle (鋼便橋) over
	# the river carries the machines; sheet-metal hoarding (施工圍籬) runs right behind the barrier.
	K.box(self, Vector3(22.0, 0.3, 90.0), Vector3(25.0, 0.15, 25.0), Color(0.42, 0.38, 0.33))
	for p in 35:
		K.box(self, Vector3(0.08, 2.0, 3.9), Vector3(BARRIER_X + 1.4, 1.0, 68.0 - p * 4.0), Color(0.93, 0.93, 0.9) if p % 2 == 0 else Color(0.2, 0.55, 0.35))
	for pos in [Vector3(20.0, 0.3, 45.0), Vector3(28.0, 0.3, 5.0), Vector3(24.0, 0, -45.0)]:
		model(CARS + "tractor-shovel.glb", pos, rng_yaw(pos), 6.0)
	for pos in [Vector3(30.0, 0.3, 30.0), Vector3(20.0, 0, -30.0), Vector3(30.0, 0, -60.0)]:
		var pile := MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.2
		cone.bottom_radius = 3.0
		cone.height = 2.0
		cone.material = K.material(GRAVEL)
		pile.mesh = cone
		pile.position = pos + Vector3(0, 1.0, 0)
		add_child(pile)
	for i in 6:
		K.box(self, Vector3(1.2, 9.0, 1.2), Vector3(30.0, 4.5, 55.0 - i * 14.0), Color(0.62, 0.6, 0.57))  # new bridge piers
	sign_board("施工中\n請減速", Vector3(BARRIER_X + 0.8, 0, 34.0), 0.0, Color(0.9, 0.5, 0.1), 2.0)
	# Coast railway and a small station to the west, the sea beyond.
	K.surface(self, Vector2(-44.0, Z_END), Vector2(-36.0, 20.0), Color(0.45, 0.42, 0.38), 0.02)
	for rx in [-41.2, -38.8]:
		K.line(self, Vector2(rx, 20.0), Vector2(rx, Z_END), Color(0.35, 0.35, 0.38), 0.12)
	K.box(self, Vector3(4.0, 0.9, 40.0), Vector3(-32.0, 0.45, -150.0), Color(0.6, 0.58, 0.55), true)
	sign_board("龍港", Vector3(-32.0, 0, -150.0), PI / 2.0, Color(0.3, 0.3, 0.3), 2.2)
	K.surface(self, Vector2(-600.0, Z_END - 60.0), Vector2(-90.0, 20.0), Color(0.12, 0.3, 0.45), 0.012)
	# Inside the U-turn: a concrete retaining wall holding up a grassy mound (Street View 2026-03).
	var hairpin: Array = _pieces()[2]
	var wall := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = hairpin[2] - DW / 2.0 - 0.8
	cyl.bottom_radius = cyl.top_radius + 0.2
	cyl.height = 2.2
	cyl.material = K.material(Color(0.45, 0.45, 0.43))
	wall.mesh = cyl
	wall.position = Vector3(hairpin[1].x, 1.1, hairpin[1].y)
	add_child(wall)
	# Wooded hills.
	var rng := RandomNumberGenerator.new()
	rng.seed = 1617
	for i in 70:
		var p := Vector2(rng.randf_range(36.0, 110.0), rng.randf_range(-70.0, -260.0))
		StreetDressing._tree(self, Vector3(p.x, 0, p.y), rng.randf_range(0.9, 1.6))
	for hill in [Vector3(70.0, -2.0, -140.0), Vector3(95.0, -3.0, -220.0)]:
		var h := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 40.0
		sm.height = 18.0
		sm.material = K.material(Color(0.3, 0.45, 0.28))
		h.mesh = sm
		h.position = hill
		add_child(h)
	# Signs: 限速 25 on the detour (聯合新聞網 headline). No advance warning of the turn — riders
	# at the 2022 press conference asked for exactly that sign to be added.
	sign_board("限速\n25", Vector3(BARRIER_X + 1.2, 0, BLOCK_START - 14.0), -PI / 2.0, Color(0.85, 0.12, 0.12), 2.0)
	sign_board("台中 ↑　竹南 ↓", Vector3(-CAR_W - 1.5, 0, -30.0), 0.0, Color(0.1, 0.45, 0.25), 4.0)


func rng_yaw(pos: Vector3) -> float:
	return fmod(pos.x * 1.7 + pos.z * 0.3, TAU)


func _add_rules() -> void:
	ViolationZone.make(self, Vector2(-CAR_W, Z_END), Vector2(CAR_W - 0.3, 70.0), "expressway_scooter", "oncoming_truck,car_speeding",
		"機車騎上快速公路主線 4,000。明明直直走就到了，機車卻要出去繞一圈棒棒糖。")
	ViolationZone.make(self, Vector2(CAR_W + 0.3, Z_END), Vector2(POST_X - 0.2, SQUEEZE_Z - 2.0), "lane_ban", "oncoming_truck,car_speeding",
		"外側混合車道一上橋就變成禁行機車，一排棒棒糖把機車擠到護欄邊（西濱後龍段陳情實況，2022）。", Vector3.FORWARD)
	# Rough strip: the bars get kicked around.
	_zone_setter(Vector2(POST_X, ROUGH_END), Vector2(MIX_MAX, SQUEEZE_Z), "bump", 0.8, 0.0)
	# Gravel on the bends: the front washes out.
	for piece in _pieces():
		if piece[0] != "arc":
			continue
		var c: Vector2 = piece[1]
		var reach: float = piece[2] + DW
		_zone_setter(c - Vector2(reach, reach), c + Vector2(reach, reach), "grip", 0.5, 1.0)
	goal(Vector2(POST_X + 0.2, -505.0), Vector2(MIX_MAX, -495.0))
	gps = [Vector3(4.0, 0, -500.0)]
	# Once the jam clears: five cameras in 300 m. The 40 -> 50 -> 40 -> 50 pattern is copied from
	# 新北土城擺接堡路 (自由時報 2026-09-19); five cameras on it is our exaggeration. Top speed is
	# 50.4 km/h, so flat out every one of them gets you. Fines: the real 第40條 tiers.
	for cam in [[-235.0, 40], [-295.0, 50], [-355.0, 40], [-415.0, 50], [-470.0, 40]]:
		speed_camera(LANE_X, cam[0], cam[1], BARRIER_X + 1.0)
	on_enter(Vector2(POST_X, BLOCK_START - 2.0), Vector2(LANE_X + 6.0, BLOCK_START + 6.0), func() -> void:
		gps = [Vector3(LOOP_X + 4.0, 0, (BLOCK_START + BLOCK_END) / 2.0), Vector3(LANE_X, 0, BLOCK_END - 8.0), Vector3(LANE_X, 0, -500.0)]
		_gps_index = 0
		toast("導航：……前面不是直直的嗎？"))
	# Cars (and trucks) in the lanes beside you — including the mixed lane, right next to the posts.
	traffic([Vector3(1.75, 0, 80.0), Vector3(1.75, 0, Z_END)] as Array[Vector3], 20.0, 3.5)
	traffic([Vector3(5.25, 0, 80.0), Vector3(5.25, 0, Z_END)] as Array[Vector3], 18.0, 5.0, Callable(), 1.5)
	traffic([Vector3(8.0, 0, 90.0), Vector3(8.0, 0, Z_END)] as Array[Vector3], 17.0, 4.0, Callable(), 2.5)
	traffic([Vector3(5.25, 0, 90.0), Vector3(5.25, 0, Z_END)] as Array[Vector3], 16.0, 9.0, Callable(), 4.0, Vector3.INF, Callable(), "semi")
	traffic([Vector3(-3.5, 0, Z_END), Vector3(-3.5, 0, 80.0)] as Array[Vector3], 20.0, 4.0)
	# Other scooters squeezed into the same strip, taking the same detour.
	var loop_path: Array[Vector3] = [Vector3(9.8, 0, 80.0), Vector3(LANE_X, 0, SQUEEZE_Z + 4.0)]
	for piece in _pieces():
		if piece[0] == "arc":
			for i in range(1, 7):
				var p := K.on_arc(piece[1], piece[2], lerpf(piece[3], piece[4], i / 6.0))
				loop_path.append(Vector3(p.x, 0, p.y))
		else:
			loop_path.append(Vector3(piece[2].x, 0, piece[2].y))
	loop_path.append(Vector3(LANE_X, 0, Z_END))
	traffic(loop_path, 5.0, 5.0, Callable(), 2.0, Vector3.INF, Callable(), "scooter")


## Area that sets a scooter property on entry and resets it on exit (grip on gravel, bump on ruts).
func _zone_setter(min_xz: Vector2, max_xz: Vector2, prop: String, inside: float, outside: float) -> void:
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var size := max_xz - min_xz
	box.size = Vector3(size.x, 3.0, size.y)
	shape.shape = box
	area.add_child(shape)
	var c := (min_xz + max_xz) / 2.0
	area.position = Vector3(c.x, 1.5, c.y)
	area.body_entered.connect(func(b: Node3D) -> void:
		if b is Scooter:
			b.set(prop, inside))
	area.body_exited.connect(func(b: Node3D) -> void:
		if b is Scooter:
			b.set(prop, outside))
	add_child(area)


func after_spawn() -> void:
	scooter.hit_rail.connect(func(impact: float) -> void:
		# ~1.5 m/s driven into a post or barrier (about 5 km/h head-on) knocks a scooter over.
		if impact > 1.5:
			fail("自摔。失控穿過棒棒糖，撞上紐澤西護欄。"))
	if not Game.ambient:
		return
	# Right after the detour: a jam of scooters crawling along the strip.
	for i in 6:
		var start_z := BLOCK_END - 10.0 - i * 4.5
		var rider := NpcVehicle.make_custom(self, _jam_scooter(i), AABB(Vector3(-0.35, 0, -0.9), Vector3(0.7, 1.8, 1.8)),
			[Vector3(LANE_X, 0, start_z), Vector3(LANE_X, 0, ROUGH_END)] as Array[Vector3], 2.2)
		rider.free_at_end = true  # the jam clears where the broken surface ends
		rider.target = scooter
		rider.trigger_distance = 28.0
		rider.yields = false
		rider.add_to_group("traffic")
		rider.touched.connect(func() -> void: toast("前面在塞車……（按喇叭也沒用）", 2.0))


func _jam_scooter(i: int) -> Node3D:
	var root := Node3D.new()
	var colors := [Color(0.9, 0.3, 0.3), Color(0.3, 0.5, 0.9), Color(0.95, 0.95, 0.95), Color(0.3, 0.7, 0.4)]
	K.box(root, Vector3(0.45, 0.5, 1.6), Vector3(0, 0.45, 0), colors[i % colors.size()])
	K.box(root, Vector3(0.45, 0.6, 0.3), Vector3(0, 1.1, -0.1), Color(0.25, 0.25, 0.3))
	K.box(root, Vector3(0.3, 0.3, 0.3), Vector3(0, 1.55, -0.1), Color(0.95, 0.85, 0.3))
	return root
