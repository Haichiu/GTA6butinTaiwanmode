extends Node
## Headless level tests. Run:
##   godot --headless --path . res://tests/smoke.tscn
## Each case loads a level, then either teleports the scooter into a trap or drives the legal
## route with a simple autopilot. Exits 0 when every case passes, 1 otherwise.

var _failures := 0
var _level: LevelBase


func _ready() -> void:
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
	]


func _run(case: Array) -> void:
	Game.reset()
	Game.level_index = case[0] - 1
	_level = load(Game.LEVELS[case[0] - 1]).instantiate()
	add_child(_level)
	await _frames(3)
	print("CASE L%d %s" % [case[0], case[1]])
	var before := _failures
	await case[2].call(_level)
	if _failures > before:
		print("  (tickets=%s pos=%s)" % [Game.tickets, _level.scooter.global_position])
	for a in ["accelerate", "brake", "steer_left", "steer_right"]:
		Input.action_release(a)
	_level.queue_free()
	await _frames(2)


# --- Actions -----------------------------------------------------------------

func _teleport_expect(l: LevelBase, pos: Vector3, yaw: float, expected: Array) -> void:
	l.scooter.global_transform = Transform3D(Basis(Vector3.UP, yaw), pos)
	l.scooter.speed = 3.0
	await _frames(10)
	_expect_tickets(expected)


## Autopilot through waypoints at `cruise` m/s. Stops early if the level ends.
func _drive(l: LevelBase, points: Array, cruise: float, timeout := 90.0) -> void:
	var s := l.scooter
	var i := 0
	var t := 0.0
	while i < points.size() and t < timeout and not l._ended:
		var to: Vector3 = points[i] - s.global_position
		to.y = 0.0
		if to.length() < 3.0:
			i += 1
			continue
		_steer_toward(s, to)
		_hold_speed(s, cruise)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	# Let the scooter roll into goal zones placed just past the last point.
	for a in ["accelerate", "steer_left", "steer_right"]:
		Input.action_release(a)
	await _frames(20)
	if t >= timeout:
		_fail("autopilot timed out at waypoint %d" % i)


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
	if Game.tickets != expected:
		_fail("expected tickets %s, got %s" % [expected, Game.tickets])


func _expect_win(l: LevelBase) -> void:
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
