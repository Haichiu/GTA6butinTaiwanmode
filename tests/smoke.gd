extends Node
## Headless level tests. Run:
##   godot --headless --path . res://tests/smoke.tscn
## Each case loads a level, then either teleports the scooter into a trap or drives the legal
## route with a simple autopilot. Exits 0 when every case passes, 1 otherwise.

var _failures := 0
var _checks := 0  # expectations evaluated in the current case
var _level: LevelBase
var _last_uncharged := ""  # most recent ticket issued to someone else


func _ready() -> void:
	Game.violated.connect(func(law_id: String, _c: String, _cap: String, charged: bool) -> void:
		if not charged:
			_last_uncharged = law_id)
	var only := OS.get_cmdline_user_args()
	for case in _cases():
		if only.size() > 0 and not only.has(str(case[0])):
			continue
		await _run(case)
	print("SMOKE %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	get_tree().quit(0 if _failures == 0 else 1)


## [level number, name, body(level) coroutine]
func _cases() -> Array:
	return [
		[1, "合法路線：貼著違停車騎到便當店", func(l: LevelBase) -> void:
			await _drive(l, [Vector3(7.7, 0, -20), Vector3(7.7, 0, -270), Vector3(8.75, 0, -296)], 7.0)
			_expect_win(l)],
		[1, "騎進空的內側車道", func(l: LevelBase) -> void:
			await _teleport_expect(l, Vector3(5.25, 0.1, 0), 0.0, ["lane_ban"])],
		[1, "逆向", func(l: LevelBase) -> void:
			await _teleport_expect(l, Vector3(-5.0, 0.1, 0), 0.0, ["wrong_way"])],
		[1, "騎上人行道", func(l: LevelBase) -> void:
			await _teleport_expect(l, Vector3(12.5, 0.1, 0), 0.0, ["sidewalk"])],

		[2, "外側車道直走過路口", func(l: LevelBase) -> void:
			await _drive(l, [Vector3(8.75, 0, 20), Vector3(8.75, 0, -30)], 8.0)
			_expect_tickets(["turn_lane_straight"])],
		[2, "切到直行車道", func(l: LevelBase) -> void:
			await _teleport_expect(l, Vector3(5.25, 0.1, 30), 0.0, ["lane_ban"])],
		[2, "合法路線：右轉繞一圈", func(l: LevelBase) -> void:
			await _drive(l, [Vector3(8.75, 0, 16), Vector3(12.0, 0, 4.0), Vector3(54, 0, 3.5), Vector3(62, 0, -8),
				Vector3(62, 0, -76), Vector3(54, 0, -82), Vector3(14, 0, -82), Vector3(8.75, 0, -90), Vector3(8.75, 0, -155)], 7.0)
			_expect_win(l)],

		[3, "直接左轉", func(l: LevelBase) -> void:
			l.sig.setup(TrafficSignal.Phase.NS_GO, 30.0)
			await _drive(l, [Vector3(9.8, 0, 16), Vector3(8.0, 0, 4), Vector3(0, 0, -3), Vector3(-40, 0, -3.5)], 7.0)
			_expect_tickets(["two_stage_left"])],
		[3, "閃停等區的車切進禁行機車道", func(l: LevelBase) -> void:
			await _teleport_expect(l, Vector3(5.25, 0.1, 30), 0.0, ["lane_ban"])],
		[3, "闖紅燈", func(l: LevelBase) -> void:
			l.sig.setup(TrafficSignal.Phase.EW_GO, 30.0)
			await _drive(l, [Vector3(9.8, 0, 16), Vector3(9.0, 0, -20)], 7.0)
			_expect_tickets(["red_light"])],
		[3, "合法路線：待轉區等橫向綠燈", func(l: LevelBase) -> void:
			l.sig.setup(TrafficSignal.Phase.NS_GO, 30.0)
			await _into_box(l, [Vector3(9.9, 0, 40), Vector3(9.9, 0, 10), Vector3(12.0, 0, -1.0)], Vector3(12.8, 0, -5.4))
			await _stop_and_wait(l, PI / 2.0, func() -> bool: return l.sig.state("ew") == "green")
			await _drive(l, [Vector3(0, 0, -5.4), Vector3(-95, 0, -3.5)], 13.0)
			_expect_win(l)],
		[3, "待轉時車身壓到斑馬線", func(l: LevelBase) -> void:
			await _teleport_expect(l, Vector3(13.9, 0.1, -5.4), PI / 2.0, ["crosswalk_stop"], 0.0)],
		[3, "紅燈停車前輪壓過停止線", func(l: LevelBase) -> void:
			l.sig.setup(TrafficSignal.Phase.EW_GO, 30.0)
			await _teleport_expect(l, Vector3(8.75, 0.1, 11.5 - 0.3), 0.0, ["stop_line"], 0.0)],
		[3, "紅燈只有車頭凸出停止線（勸導）", func(l: LevelBase) -> void:
			l.sig.setup(TrafficSignal.Phase.EW_GO, 30.0)
			await _teleport_expect(l, Vector3(8.75, 0.1, 11.5 + 0.75), 0.0, [], 0.0)],
		[3, "待撞區：綠燈了還不走", func(l: LevelBase) -> void:
			l.sig.setup(TrafficSignal.Phase.NS_GO, 30.0)
			await _into_box(l, [Vector3(9.9, 0, 40), Vector3(9.9, 0, 10), Vector3(12.0, 0, -1.0)], Vector3(12.8, 0, -5.4))
			await _stop_and_wait(l, PI / 2.0, func() -> bool: return l.sig.state("ew") == "green")
			Input.action_press("brake")
			await _frames(240)
			_checks += 1
			if not (l._ended and not l._won and Game.tickets.is_empty()):
				_fail("expected to be rear-ended in the 待轉區 (ended=%s tickets=%s)" % [l._ended, Game.tickets])],

		[4, "直接右轉", func(l: LevelBase) -> void:
			l.sig.setup(TrafficSignal.Phase.NS_GO, 30.0)
			await _drive(l, [Vector3(-5.25, 0, 16), Vector3(-5.0, 0, 6), Vector3(3, 0, 0), Vector3(40, 0, 0)], 7.0)
			_expect_tickets(["two_stage_right"])],
		[4, "騎進中間禁行機車道", func(l: LevelBase) -> void:
			await _teleport_expect(l, Vector3(-1.75, 0.1, 30), 0.0, ["lane_ban"])],
		[4, "單行道逆向", func(l: LevelBase) -> void:
			await _teleport_expect(l, Vector3(-5.25, 0.1, 30), PI, ["wrong_way"])],
		[4, "合法路線：兩段式右轉", func(l: LevelBase) -> void:
			l.sig.setup(TrafficSignal.Phase.NS_GO, 30.0)
			await _into_box(l, [Vector3(-5.25, 0, 10), Vector3(-7.5, 0, -1.0)], Vector3(-9.3, 0, -5.4))
			await _stop_and_wait(l, -PI / 2.0, func() -> bool: return l.sig.state("ew") == "green")
			await _drive(l, [Vector3(0, 0, -5.4), Vector3(95, 0, -3)], 13.0)
			_expect_win(l)],
		[3, "待轉區還沒綠燈就出發", func(l: LevelBase) -> void:
			l.sig.setup(TrafficSignal.Phase.NS_GO, 30.0)
			await _into_box(l, [Vector3(9.9, 0, 40), Vector3(9.9, 0, 10), Vector3(12.0, 0, -1.0)], Vector3(12.8, 0, -5.4))
			await _stop_and_wait(l, PI / 2.0, func() -> bool: return true)
			await _drive(l, [Vector3(0, 0, -5.4), Vector3(-40, 0, -3.5)], 7.0)
			_expect_tickets(["red_light"])],

		[5, "照地上的箭頭左轉", func(l: LevelBase) -> void:
			await _drive(l, [Vector3(1.75, 0, 16), Vector3(1.0, 0, 3), Vector3(-6, 0, -3.5), Vector3(-40, 0, -3.5)], 7.0)
			_expect_tickets(["no_left_turn"])],
		[5, "在路口直接迴轉", func(l: LevelBase) -> void:
			await _teleport_expect(l, Vector3(-3.5, 0.1, -2.0), PI, ["uturn_no_left"])],
		[5, "在雙黃線上迴轉", func(l: LevelBase) -> void:
			await _teleport_expect(l, Vector3(-3.5, 0.1, -60.0), PI, ["uturn_double_yellow"])],
		[5, "合法路線：直走到下個路口迴轉再右轉", func(l: LevelBase) -> void:
			await _drive(l, [Vector3(1.75, 0, 16), Vector3(1.75, 0, -120), Vector3(1.0, 0, -131), Vector3(-2.5, 0, -133),
				Vector3(-3.5, 0, -124), Vector3(-3.5, 0, -12), Vector3(-6, 0, -4), Vector3(-80, 0, -3.5)], 7.0)
			_expect_win(l)],
		[6, "橋上超車閃進汽車道", func(l: LevelBase) -> void:
			await _teleport_expect(l, Vector3(5.25, 0.1, -80), 0.0, ["lane_ban"])],
		[6, "撞到腳踏車只會被擋住，不會失敗", func(l: LevelBase) -> void:
			await _drive(l, [Vector3(5.25, 0, 0), Vector3(8.3, 0, -20), Vector3(8.3, 0, -120)], 10.0, 30.0)
			_checks += 1
			if l._ended:
				_fail("bumping a cyclist should not end the level (tickets=%s)" % [Game.tickets])
			await _drive(l, [Vector3(8.3, 0, -188), Vector3(5.25, 0, -210), Vector3(5.25, 0, -284)], 4.0, 150.0)
			_expect_win(l)],
		[6, "合法路線：跟在腳踏車後面慢慢騎", func(l: LevelBase) -> void:
			await _drive(l, [Vector3(5.25, 0, 0), Vector3(8.3, 0, -20), Vector3(8.3, 0, -188), Vector3(5.25, 0, -210), Vector3(5.25, 0, -284)], 3.2, 150.0)
			_expect_win(l)],

		[7, "照導航騎上國道", func(l: LevelBase) -> void:
			await _drive(l, [Vector3(6.5, 0, -45), Vector3(20, 0, -95)], 8.0)
			_expect_tickets(["highway_scooter"])],
		[7, "被逆向聯結車撞（罰單是對方的）", func(l: LevelBase) -> void:
			await _drive(l, [Vector3(5.25, 0, -425)], 13.0)
			_checks += 1
			if not (l.truck_hit and Game.tickets.is_empty() and Game.total_fine == 0):
				_fail("expected truck hit with no fine charged (hit=%s tickets=%s)" % [l.truck_hit, Game.tickets])],
		[7, "合法路線：閃到路肩", func(l: LevelBase) -> void:
			await _drive(l, [Vector3(8.3, 0, 20), Vector3(8.3, 0, -400), Vector3(5.25, 0, -426)], 13.0)
			_expect_win(l)],

		# --- Hazards and traffic (ambient on) ---
		[1, "老阿伯衝出來：沒煞車撞上", func(l: LevelBase) -> void:
			_teleport(l, Vector3(7.7, 0.1, -110.0), 0.0)
			await _drive(l, [Vector3(7.7, 0, -170.0)], 10.0, 20.0)
			_expect_hit(l, "ped_jaywalk"), "ambient"],
		[1, "老阿伯衝出來：停下讓他過", func(l: LevelBase) -> void:
			_teleport(l, Vector3(7.7, 0.1, -110.0), 0.0)
			await _drive(l, [Vector3(7.7, 0, -126.0)], 6.0, 20.0, 1.0, false)
			await _stop_and_wait(l, 0.0, func() -> bool: return true)
			Input.action_press("brake")
			await _frames(360)
			Input.action_release("brake")
			await _drive(l, [Vector3(7.7, 0, -270), Vector3(8.75, 0, -296)], 7.0)
			_expect_win(l), "ambient"],
		[5, "學校前小孩追球：撞上小孩", func(l: LevelBase) -> void:
			l._reached_b = true
			_teleport(l, Vector3(-30.0, 0.1, -3.5), PI / 2.0)  # close enough to set the ball rolling
			var kid := await _wait_for_npc(l, func(n: NpcVehicle) -> bool: return n.speed == 3.0 and n.global_position.z > -7.0)
			_teleport(l, Vector3(kid.global_position.x + 3.0, 0.1, kid.global_position.z + 1.0), PI / 2.0)
			l.scooter.speed = 4.0
			Input.action_press("accelerate")
			await _frames(40)
			_expect_hit(l, "ped_play"), "ambient"],
		[7, "追撞前車：一般道路 0 元", func(l: LevelBase) -> void:
			var car: NpcVehicle = null
			for i in 600:
				await get_tree().physics_frame
				for n in l.find_children("*", "NpcVehicle", true, false):
					if n.free_at_end and n.global_position.x > 0.0 and n.global_position.z < 0.0:
						car = n
				if car != null:
					break
			_teleport(l, car.global_position + Vector3(0, 0.1, 5.0), 0.0)
			l.scooter.speed = 14.0
			l.scooter.max_speed = 20.0  # test only: guarantee closing speed on a 13 m/s car
			Input.action_press("accelerate")
			await _frames(90)
			_expect_tickets(["rear_end"])
			_checks += 1
			if Game.total_fine != 0:
				_fail("rear-end should cost 0, got %d" % Game.total_fine), "ambient"],
	]


func _wait_for_npc(l: LevelBase, pred: Callable, max_frames := 900) -> NpcVehicle:
	for i in max_frames:
		for n in l.find_children("*", "NpcVehicle", true, false):
			if pred.call(n):
				return n
		await get_tree().physics_frame
	_fail("npc never appeared")
	return null


func _teleport(l: LevelBase, pos: Vector3, yaw: float) -> void:
	l.scooter.global_transform = Transform3D(Basis(Vector3.UP, yaw), pos)
	l.scooter.speed = 0.0


## Ran into a person/animal: the run ends with *their* ticket, nothing charged to you.
func _expect_hit(l: LevelBase, law_id: String) -> void:
	_checks += 1
	if not (l._ended and not l._won and Game.tickets.is_empty() and _last_uncharged == law_id):
		_fail("expected to hit someone (%s); ended=%s won=%s tickets=%s last=%s" % [law_id, l._ended, l._won, Game.tickets, _last_uncharged])


func _run(case: Array) -> void:
	Game.reset()
	_last_uncharged = ""
	Game.ambient = case.size() > 3 and case[3] == "ambient"
	Game.level_index = case[0] - 1
	var inst: Node = load(Game.LEVELS[case[0] - 1]).instantiate()
	if not inst is LevelBase:
		print("CASE L%d %s" % [case[0], case[1]])
		_fail("level %d failed to load (script error?)" % case[0])
		return
	_level = inst
	add_child(_level)
	await _frames(3)
	print("CASE L%d %s" % [case[0], case[1]])
	var before := _failures
	_checks = 0
	await case[2].call(_level)
	# A script error aborts the case body silently; treat "no expectation reached" as failure.
	if _checks == 0:
		_fail("case aborted before any expectation (script error?)")
	if _failures > before:
		print("  (tickets=%s pos=%s)" % [Game.tickets, _level.scooter.global_position])
	for a in ["accelerate", "brake", "steer_left", "steer_right"]:
		Input.action_release(a)
	_level.queue_free()
	await _frames(2)


# --- Actions -----------------------------------------------------------------

func _teleport_expect(l: LevelBase, pos: Vector3, yaw: float, expected: Array, speed := 3.0) -> void:
	l.scooter.global_transform = Transform3D(Basis(Vector3.UP, yaw), pos)
	l.scooter.speed = speed
	await _frames(10)
	_expect_tickets(expected)


## Autopilot through waypoints at `cruise` m/s. Stops early if the level ends.
func _drive(l: LevelBase, points: Array, cruise: float, timeout := 90.0, reach := 3.0, coast := true) -> void:
	var s := l.scooter
	var i := 0
	var t := 0.0
	while i < points.size() and t < timeout and not l._ended:
		var to: Vector3 = points[i] - s.global_position
		to.y = 0.0
		if to.length() < reach:
			i += 1
			continue
		_steer_toward(s, to)
		_hold_speed(s, cruise)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	# Let the scooter roll into goal zones placed just past the last point.
	for a in ["accelerate", "steer_left", "steer_right"]:
		Input.action_release(a)
	if coast:
		await _frames(20)
	if t >= timeout:
		_fail("autopilot timed out at waypoint %d" % i)


## Drive `approach`, then creep precisely onto `spot` (a 待轉區) without coasting past it.
func _into_box(l: LevelBase, approach: Array, spot: Vector3) -> void:
	await _drive(l, approach, 6.0, 90.0, 3.0, false)
	await _drive(l, [spot], 2.0, 30.0, 0.4, false)


## Brake to a stop, optionally pivot to `yaw`, and wait until `until` returns true.
func _stop_and_wait(l: LevelBase, yaw: float, until: Callable, timeout := 40.0) -> void:
	var s := l.scooter
	var t := 0.0
	Input.action_release("accelerate")
	while t < timeout and not l._ended:
		Input.action_press("brake")
		var err := wrapf(yaw - s.rotation.y, -PI, PI)
		_press_steer(clampf(err * 3.0, -1.0, 1.0) if absf(err) > 0.03 else 0.0)
		if s.speed < 0.1 and absf(err) < 0.05 and until.call():
			break
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	Input.action_release("brake")
	_press_steer(0.0)
	if t >= timeout:
		_fail("wait timed out")


func _steer_toward(s: Scooter, to: Vector3) -> void:
	var desired := atan2(-to.x, -to.z)
	var err := wrapf(desired - s.rotation.y, -PI, PI)
	_press_steer(clampf(err * 3.0, -1.0, 1.0))


func _press_steer(v: float) -> void:
	if v > 0.0:
		Input.action_press("steer_left", v)
		Input.action_release("steer_right")
	elif v < 0.0:
		Input.action_press("steer_right", -v)
		Input.action_release("steer_left")
	else:
		Input.action_release("steer_left")
		Input.action_release("steer_right")


func _hold_speed(s: Scooter, cruise: float) -> void:
	if s.speed < cruise:
		Input.action_press("accelerate")
		Input.action_release("brake")
	else:
		Input.action_release("accelerate")
		if s.speed > cruise + 1.5:
			Input.action_press("brake", 0.5)
		else:
			Input.action_release("brake")


# --- Assertions --------------------------------------------------------------

func _expect_tickets(expected: Array) -> void:
	_checks += 1
	if Game.tickets != expected:
		_fail("expected tickets %s, got %s" % [expected, Game.tickets])


func _expect_win(l: LevelBase) -> void:
	_checks += 1
	if not Game.tickets.is_empty():
		_fail("legal route got tickets %s" % [Game.tickets])
	elif not l._won:
		_fail("did not reach the goal (pos=%s)" % l.scooter.global_position)


func _fail(message: String) -> void:
	_failures += 1
	print("  FAIL: ", message)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame
