class_name LevelBase
extends Node3D
## Shared level setup: lighting, ground, scooter, camera, HUD, GPS arrow, goal and level flow.
## Subclasses set title/objective, override build() to lay out the level and spawn_transform().

const K = preload("res://scripts/road_kit.gd")
const ROADS := "res://assets/kenney/roads/Models/GLB format/"
const CARS := "res://assets/kenney/cars/Models/GLB format/"
const CITY := "res://assets/kenney/commercial/Models/GLB format/"
## Tolerance so brushing the curb line isn't a sidewalk ticket.
const CURB := 0.3
const TRAFFIC_MODELS := ["sedan", "taxi", "suv", "van", "hatchback-sports"]
const BUILDINGS := ["building-a", "building-b", "building-c", "building-d", "building-e", "building-f", "building-g", "building-h"]

var title := ""
var objective := ""  # the situation, in the character's words — never the rule
var who := ""  # whose day this level is
## Seconds until the deadline (0 = none). Being late never fails the level; it changes the ending line.
var deadline := 0.0
var deadline_name := ""  # e.g. "打卡"
var place := ""  # label floating over the goal: a person, a door, a venue...
var waiting_person := true  # draw someone standing at the goal
var ending := ""  # the little ending when you make it in time
var late_ending := ""  # ...and when you don't
## Waypoints the GPS arrow points through, in order. It always suggests the "obvious" route.
var gps: Array[Vector3] = []

var scooter: Scooter
var camera: FollowCamera
var _speed_label: Label
var _fine_label: Label
var _message: Label
var _intro: Label
var _arrow: Node3D
var _gps_index := 0
var _ended := false
var _won := false
var _can_continue := false
var _building_i := 0
var _elapsed := 0.0  # level time for the deadline, clamped per frame like the intro
var _timer_label: Label
var _gm_label: Label
var _intro_time := 0.0  # seconds the intro has been shown (clamped per frame, see _process)
var _pending_darters: Array[NpcVehicle] = []


func _ready() -> void:
	_setup_environment()
	build()
	scooter = Scooter.new()
	scooter.name = "Scooter"
	# Set the transform before entering the tree so it never exists at the origin (inside zones).
	scooter.transform = spawn_transform()
	add_child(scooter)
	camera = FollowCamera.new()
	camera.target = scooter
	add_child(camera)
	camera.make_current()
	_arrow = _build_arrow()
	add_child(_arrow)
	_setup_hud()
	Game.violated.connect(_on_violated)
	after_spawn()
	# Darters are created in build(), before the scooter exists; aim them now.
	for d in _pending_darters:
		d.target = scooter


func build() -> void:
	pass


## Hook for things that need the scooter (NPC targets etc.).
func after_spawn() -> void:
	pass


func spawn_transform() -> Transform3D:
	return Transform3D.IDENTITY


func _process(delta: float) -> void:
	_speed_label.text = "%d km/h" % roundi(scooter.speed_kmh())
	_fine_label.text = "今日罰款 NT$ %s" % Ticket._money(Game.total_fine)
	_gm_label.visible = Game.gm
	if not _ended:
		_elapsed += minf(delta, 0.1)
	if deadline > 0.0:
		var left := deadline - _elapsed
		_timer_label.text = "距離%s還有 %d 秒" % [deadline_name, ceili(left)] if left > 0.0 else "%s時間已經過了" % deadline_name
		_timer_label.add_theme_color_override("font_color", Color(1, 0.35, 0.3) if left < 10.0 else Color.WHITE)
	_update_arrow()
	# Fade the intro after 6 s of *play*. Clamping delta matters on the web, where the first
	# frame after a slow level load can report several seconds at once.
	_intro_time += minf(delta, 0.1)
	if _intro_time > 6.0 and _intro_time < 7.5 and _intro.text.begins_with("第"):
		_intro.modulate.a = clampf(1.0 - (_intro_time - 6.0), 0.0, 1.0)


func _unhandled_input(event: InputEvent) -> void:
	if _can_continue and event.is_action_pressed("restart"):
		if _won:
			Game.next_level()
		else:
			get_tree().reload_current_scene()


# --- Level flow -----------------------------------------------------------

## Area that ends the level successfully when the scooter reaches it.
func goal(min_xz: Vector2, max_xz: Vector2) -> void:
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var size := max_xz - min_xz
	box.size = Vector3(size.x, 3.0, size.y)
	shape.shape = box
	area.add_child(shape)
	var center := (min_xz + max_xz) / 2.0
	area.position = Vector3(center.x, 1.5, center.y)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body == scooter and not _ended:
			win())
	add_child(area)
	# Small ring on the ground plus the person waiting there.
	var ring := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 1.6
	disc.bottom_radius = 1.6
	disc.height = 0.03
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.85, 0.2, 0.55)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	disc.material = mat
	ring.mesh = disc
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.position = Vector3(center.x, 0.06, center.y)
	add_child(ring)
	var side := 1.0 if center.x >= 0.0 else -1.0
	var anchor := Vector3(center.x + side * 1.4, 0, center.y)
	if waiting_person:
		var person := _person(Color(0.85, 0.3, 0.35))
		person.position = anchor
		add_child(person)
	var tag := Label3D.new()
	tag.text = place
	tag.font = K.font()
	tag.font_size = 96
	tag.pixel_size = 0.006
	tag.outline_size = 16
	tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	tag.position = anchor + Vector3.UP * 2.4
	add_child(tag)


## Something darts across the road when the scooter gets within `trigger` meters.
## kind: "uncle" (老阿伯 crossing slowly), "dog", "ball" (a ball, then a kid chasing it).
## Hitting the person/animal ends the run with *their* ticket — the absurdity is how cheap it is.
func darter(kind: String, from: Vector3, to: Vector3, trigger: float) -> void:
	if not Game.ambient:
		return
	var path: Array[Vector3] = [from, to]
	match kind:
		"uncle":
			# Steps out, then stops in the first lane he reaches to look around for a while.
			var lane := from + (to - from).normalized() * 4.0
			var uncle_path: Array[Vector3] = [from, lane, to]
			var npc := NpcVehicle.make_custom(self, _person(Color(0.97, 0.97, 0.93), 0.95), AABB(Vector3(-0.3, 0, -0.2), Vector3(0.6, 1.8, 0.4)), uncle_path, 1.6)
			npc.dwell = {1: 3.0}
			_arm_darter(npc, trigger, func() -> void:
				_hazard_hit("ped_jaywalk", "老阿伯擅自穿越車道，罰 500。\n撞到他的你，可能要面對過失傷害的刑事責任，加上民事賠償。"))
		"dog":
			var npc := NpcVehicle.make_custom(self, _dog(), AABB(Vector3(-0.2, 0, -0.45), Vector3(0.4, 0.6, 0.9)), path, 6.0)
			_arm_darter(npc, trigger, func() -> void:
				_hazard_hit("pet_owner", "狗主人放狗在馬路上跑，罰 300。\n你摔車、修車、看醫生，自己出。"))
		"ball":
			var ball := NpcVehicle.make_custom(self, _ball(), AABB(Vector3(-0.2, 0, -0.2), Vector3(0.4, 0.4, 0.4)), path, 5.0)
			_arm_darter(ball, trigger, func() -> void: toast("一顆球從車底滾過去了……", 2.0))
			var kid_path: Array[Vector3] = [from - (to - from).normalized() * 3.0, to]
			var kid := NpcVehicle.make_custom(self, _person(Color(0.95, 0.75, 0.2), 0.6), AABB(Vector3(-0.2, 0, -0.15), Vector3(0.4, 1.1, 0.3)), kid_path, 3.0)
			_arm_darter(kid, trigger + 4.0, func() -> void:
				_hazard_hit("ped_play", "小孩在馬路上追球，罰 500（對，行人也會被罰）。\n撞到小孩的你，可能要面對過失傷害的刑事責任，加上民事賠償。"))


func _arm_darter(npc: NpcVehicle, trigger: float, on_hit: Callable) -> void:
	npc.yields = false
	npc.trigger_distance = trigger
	npc.free_at_end = false
	_pending_darters.append(npc)
	npc.touched.connect(on_hit)


func _hazard_hit(law_id: String, caption: String) -> void:
	if _ended:
		return
	Game.sfx.play("crash")
	Game.report(law_id, "", caption, false)


## Ordinary traffic: spawns a car at the start of `path` every `interval` seconds while `active`
## (e.g. its light is green) and removes it at the end. Cars keep their distance from you;
## running into one is an accident report (see _car_contact).
func traffic(path: Array[Vector3], mps: float, interval: float, active := Callable(), first_delay := 0.0) -> void:
	if not Game.ambient:
		return
	var timer := Timer.new()
	timer.wait_time = interval
	timer.autostart = false
	add_child(timer)
	var spawn := func() -> void:
		if _ended or (active.is_valid() and not active.call()):
			return
		var car := NpcVehicle.make(self, CARS + TRAFFIC_MODELS[randi() % TRAFFIC_MODELS.size()] + ".glb", 4.4, path, mps)
		car.target = scooter
		car.free_at_end = true
		car.touched.connect(func() -> void: _car_contact(car))
	# The timer belongs to the level, so a restart can't fire it into a freed scene.
	timer.timeout.connect(func() -> void:
		timer.wait_time = interval
		spawn.call())
	timer.start(maxf(first_delay, 0.01))


## Scooter touched an ordinary car. Hitting it from behind is a (zero-fine) rear-end report;
## anything else is just a crash.
func _car_contact(car: Node3D) -> void:
	if _ended or scooter == null:
		return
	var forward := -scooter.global_transform.basis.z
	var to_car := car.global_position - scooter.global_position
	to_car.y = 0.0
	Game.sfx.play("crash")
	if to_car.length() > 0.01 and forward.dot(to_car.normalized()) > 0.5 and scooter.speed > 1.0:
		Game.report("rear_end", "car_speeding",
			"一般道路追撞前車：處罰條例找不到罰鍰，0 元。\n但修車、保險、跟對方喬，全部自己來。同樣的事在國道罰 3,000 起。")
	else:
		fail("跟汽車擦撞了。")


func _dog() -> Node3D:
	var root := Node3D.new()
	var fur := Color(0.7, 0.5, 0.25)
	K.box(root, Vector3(0.3, 0.3, 0.7), Vector3(0, 0.4, 0), fur)
	K.box(root, Vector3(0.25, 0.25, 0.3), Vector3(0, 0.6, 0.4), fur)
	for p in [Vector2(-0.1, -0.25), Vector2(0.1, -0.25), Vector2(-0.1, 0.25), Vector2(0.1, 0.25)]:
		K.box(root, Vector3(0.08, 0.3, 0.08), Vector3(p.x, 0.15, p.y), fur.darkened(0.3))
	return root


func _ball() -> Node3D:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	sphere.material = K.material(Color(0.95, 0.3, 0.2))
	mi.mesh = sphere
	mi.position.y = 0.2
	var root := Node3D.new()
	root.add_child(mi)
	return root


## A simple standing figure (someone waiting, a pedestrian...). Faces +Z.
func _person(shirt: Color, height := 1.0) -> Node3D:
	var root := Node3D.new()
	K.box(root, Vector3(0.18, 0.8, 0.18), Vector3(-0.12, 0.4, 0) * Vector3(1, height, 1), Color(0.2, 0.2, 0.3))
	K.box(root, Vector3(0.18, 0.8, 0.18), Vector3(0.12, 0.4, 0) * Vector3(1, height, 1), Color(0.2, 0.2, 0.3))
	K.box(root, Vector3(0.5, 0.65, 0.3), Vector3(0, 1.1 * height, 0), shirt)
	K.box(root, Vector3(0.3, 0.3, 0.3), Vector3(0, 1.6 * height, 0), Color(0.95, 0.8, 0.65))
	root.scale = Vector3.ONE * height
	return root


func win() -> void:
	Game.sfx.play("win")
	_won = true
	var late := deadline > 0.0 and _elapsed > deadline
	_end()
	var line := late_ending if late and late_ending != "" else ending
	_show_message("%s\n按空白鍵前往下一關" % (line if line != "" else "到了！"))


## Non-ticket failure (e.g. hit by a truck): message then restart.
func fail(text: String) -> void:
	if _ended:
		return
	Game.sfx.play("crash")
	if Game.gm:
		toast("GM｜" + text, 3.0)
		return
	_end()
	_show_message(text + "\n按空白鍵重來")


func _on_violated(law_id: String, contrast_id: String, caption: String, charged: bool) -> void:
	if _ended:
		return
	if Game.gm:
		var l := Game.law(law_id)
		Game.sfx.play("stamp")
		toast("GM｜%s罰單：%s　NT$ %s" % ["" if charged else "對方的", l["title"], Ticket._money(l["fine"])], 3.0)
		return
	_end()
	var ticket := Ticket.new()
	add_child(ticket)
	ticket.show_ticket(law_id, contrast_id, caption, charged)


func _end() -> void:
	_ended = true
	scooter.frozen = true
	_intro.visible = false
	# Short grace period so a held key doesn't skip the ticket instantly.
	get_tree().create_timer(0.6).timeout.connect(func() -> void: _can_continue = true)


## Transient notice in the top-left (reuses the intro label).
func toast(text: String, seconds := 4.0) -> void:
	_intro.text = text
	_intro.visible = true
	_intro.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(seconds)
	tw.tween_property(_intro, "modulate:a", 0.0, 0.8)


## One-shot area that calls `fn` when the scooter enters it.
func on_enter(min_xz: Vector2, max_xz: Vector2, fn: Callable) -> void:
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var size := max_xz - min_xz
	box.size = Vector3(size.x, 3.0, size.y)
	shape.shape = box
	area.add_child(shape)
	var center := (min_xz + max_xz) / 2.0
	area.position = Vector3(center.x, 1.5, center.y)
	var fired := [false]
	area.body_entered.connect(func(body: Node3D) -> void:
		if body == scooter and not fired[0]:
			fired[0] = true
			fn.call())
	add_child(area)


func _show_message(text: String) -> void:
	_message.text = text
	_message.visible = true


# --- Building helpers -----------------------------------------------------

## Lane lines along the north-south axis at each x in `xs`. kinds: "yellow2", "dash", "solid", "edge".
func lines_ns(xs: Array, kinds: Array, z0: float, z1: float) -> void:
	for i in xs.size():
		_line_kind(Vector2(xs[i], z0), Vector2(xs[i], z1), kinds[i], Vector2(1, 0))


## Lane lines along the east-west axis at each z in `zs`.
func lines_ew(zs: Array, kinds: Array, x0: float, x1: float) -> void:
	for i in zs.size():
		_line_kind(Vector2(x0, zs[i]), Vector2(x1, zs[i]), kinds[i], Vector2(0, 1))


func _line_kind(a: Vector2, b: Vector2, kind: String, side: Vector2) -> void:
	match kind:
		"yellow2":
			K.line(self, a - side * 0.2, b - side * 0.2, K.YELLOW)
			K.line(self, a + side * 0.2, b + side * 0.2, K.YELLOW)
		"dash":
			K.line(self, a, b, K.WHITE, K.LINE_W, 4.0)
		"solid", "edge":
			K.line(self, a, b, K.WHITE)


## A row of buildings along x = `x` from z0 to z1, fronts facing the road (sign of `face`: +1 = east).
func buildings_ns(x: float, z0: float, z1: float, face: int) -> void:
	var z := minf(z0, z1) + 8.0
	while z < maxf(z0, z1) - 6.0:
		model(CITY + BUILDINGS[_building_i % BUILDINGS.size()] + ".glb", Vector3(x, 0, z), PI / 2.0 * face, 14.0, true)
		_building_i += 1
		z += 16.0


func buildings_ew(z: float, x0: float, x1: float, face: int) -> void:
	var x := minf(x0, x1) + 8.0
	while x < maxf(x0, x1) - 6.0:
		model(CITY + BUILDINGS[_building_i % BUILDINGS.size()] + ".glb", Vector3(x, 0, z), 0.0 if face > 0 else PI, 14.0, true)
		_building_i += 1
		x += 16.0


## Place a Kenney GLB, uniformly scaled so its largest horizontal extent equals `size` meters.
func model(path: String, pos: Vector3, rot_y := 0.0, size := 0.0, collide := false) -> Node3D:
	var inst: Node3D = load(path).instantiate()
	var holder := Node3D.new()
	holder.add_child(inst)
	var aabb := aabb_of(inst)
	if size > 0.0:
		var extent := maxf(aabb.size.x, aabb.size.z)
		if extent > 0.0:
			holder.scale = Vector3.ONE * (size / extent)
	if collide:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		box_shape.size = aabb.size
		shape.shape = box_shape
		shape.position = aabb.get_center()
		body.add_child(shape)
		holder.add_child(body)
	holder.position = pos
	holder.rotation.y = rot_y
	add_child(holder)
	return holder


## Zebra crossing plus its rule: coming to a stop on it is a ticket (60-2-3).
func crosswalk(min_xz: Vector2, max_xz: Vector2, along: String) -> void:
	K.zebra(self, min_xz, max_xz, along)
	ViolationZone.make(self, min_xz, max_xz, "crosswalk_stop", "ped_red,turn_ignore_ped",
		"停下來時壓到斑馬線 900；行人闖紅燈 500，汽車轉彎不看行人 900。") \
		.when(func() -> bool: return scooter != null and scooter.speed < 0.2)


## Floating sign (e.g. 兩段式左轉 / 國道入口) on a pole.
func sign_board(text: String, pos: Vector3, facing_y: float, bg := Color(0.15, 0.35, 0.75), height := 4.0) -> void:
	var root := Node3D.new()
	root.position = pos
	root.rotation.y = facing_y
	add_child(root)
	K.box(root, Vector3(0.15, height, 0.15), Vector3(0, height / 2.0, 0), Color(0.5, 0.5, 0.5))
	var lines := text.split("\n")
	var width := 0.0
	for l in lines:
		width = maxf(width, l.length() * 0.55)
	var h := lines.size() * 0.6 + 0.4
	K.box(root, Vector3(width + 0.6, h, 0.1), Vector3(0, height + h / 2.0, 0), bg)
	var label := Label3D.new()
	label.text = text
	label.font = K.font()
	label.font_size = 96
	label.pixel_size = 0.005
	label.position = Vector3(0, height + h / 2.0, 0.06)
	label.modulate = Color.WHITE
	root.add_child(label)


static func aabb_of(node: Node) -> AABB:
	var result := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		var xf := mi.transform
		var p := mi.get_parent()
		while p != null and p != node:
			if p is Node3D:
				xf = (p as Node3D).transform * xf
			p = p.get_parent()
		var box := xf * mi.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result


# --- Setup ---------------------------------------------------------------

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.45, 0.65, 0.9)
	sky_mat.sky_horizon_color = Color(0.85, 0.88, 0.9)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.88, 0.9)
	env.fog_density = 0.004
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)

	# Ground plane with collision; top surface at y=0.
	K.box(self, Vector3(1200, 1, 1200), Vector3(0, -0.5, 0), K.GRASS, true)


func _build_arrow() -> Node3D:
	var root := Node3D.new()
	# A HUD element living in 3D: flat color, no lighting, no shadow on the road.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.75, 1.0)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var shaft := MeshInstance3D.new()
	shaft.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var box := BoxMesh.new()
	box.size = Vector3(0.25, 0.08, 1.0)
	box.material = mat
	shaft.mesh = box
	shaft.position.z = 0.2
	root.add_child(shaft)
	var head := MeshInstance3D.new()
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var prism := PrismMesh.new()
	prism.size = Vector3(0.8, 0.7, 0.08)
	prism.material = mat
	head.mesh = prism
	head.rotation.x = -PI / 2.0  # tip points to -Z
	head.position.z = -0.6
	root.add_child(head)
	return root


func _update_arrow() -> void:
	_arrow.visible = not gps.is_empty() and not _ended
	if not _arrow.visible:
		return
	while _gps_index < gps.size() - 1 and _flat_dist(scooter.global_position, gps[_gps_index]) < 10.0:
		_gps_index += 1
	var to := gps[_gps_index] - scooter.global_position
	_arrow.global_position = scooter.global_position + Vector3.UP * 2.6
	_arrow.rotation.y = atan2(-to.x, -to.z)


static func _flat_dist(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _setup_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_speed_label = _hud_label(32)
	_speed_label.position = Vector2(24, 650)
	layer.add_child(_speed_label)
	_fine_label = _hud_label(26)
	_fine_label.position = Vector2(900, 20)
	layer.add_child(_fine_label)
	_timer_label = _hud_label(26)
	_timer_label.position = Vector2(900, 58)
	layer.add_child(_timer_label)
	_gm_label = _hud_label(20)
	_gm_label.text = "GM 模式｜罰單不中斷　1–7 選關　N 下一關　G 關閉"
	_gm_label.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	_gm_label.position = Vector2(420, 686)
	layer.add_child(_gm_label)
	_message = _hud_label(40)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.position = Vector2(240, 280)
	_message.size = Vector2(800, 160)
	_message.visible = false
	layer.add_child(_message)
	_intro = _hud_label(30)
	_intro.position = Vector2(24, 20)
	_intro.size = Vector2(840, 120)
	_intro.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY  # CJK text: break anywhere, not at spaces
	_intro.text = "第 %d 關｜%s\n%s" % [Game.level_index + 1, who if who != "" else title, objective]
	layer.add_child(_intro)


func _hud_label(size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	return label
