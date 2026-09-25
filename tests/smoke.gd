extends Node
## Headless smoke test. Run:
##   godot --headless --path . res://tests/smoke.tscn
## Exits with code 0 when every case passes, 1 otherwise.

const LEVEL := "res://scenes/main.tscn"

var _failures := 0


func _ready() -> void:
	await _case("騎在外側車道不會被開單", func(level: LevelBase) -> void:
		Input.action_press("accelerate")
		await _frames(90)
		Input.action_release("accelerate")
		_check(Game.tickets.is_empty(), "tickets should be empty, got %s" % [Game.tickets])
		_check(level.scooter.speed > 5.0, "scooter should be moving, speed=%.1f" % level.scooter.speed))

	await _case("騎進禁行機車車道會吃 lane_ban", func(level: LevelBase) -> void:
		_teleport(level.scooter, Vector3(5.25, 0.1, 40.0))
		await _frames(10)
		_check(Game.tickets == ["lane_ban"], "expected [lane_ban], got %s" % [Game.tickets])
		_check(Game.total_fine == 600, "expected fine 600, got %d" % Game.total_fine)
		_check(level.scooter.frozen, "scooter should freeze after a ticket"))

	await _case("騎上人行道會吃 sidewalk", func(level: LevelBase) -> void:
		_teleport(level.scooter, Vector3(12.5, 0.1, 40.0))
		await _frames(10)
		_check(Game.tickets == ["sidewalk"], "expected [sidewalk], got %s" % [Game.tickets]))

	await _case("抵達終點過關、不開單", func(level: LevelBase) -> void:
		_teleport(level.scooter, Vector3(8.75, 0.1, -65.0))
		await _frames(10)
		_check(Game.tickets.is_empty(), "tickets should be empty, got %s" % [Game.tickets])
		_check(level._ended and level.scooter.frozen, "level should end at the goal"))

	print("SMOKE %s (%d failures)" % ["PASS" if _failures == 0 else "FAIL", _failures])
	get_tree().quit(0 if _failures == 0 else 1)


func _case(name: String, body: Callable) -> void:
	Game.total_fine = 0
	Game.total_points = 0
	Game.tickets.clear()
	var level: LevelBase = load(LEVEL).instantiate()
	add_child(level)
	await _frames(3)
	print("CASE ", name)
	await body.call(level)
	level.queue_free()
	await _frames(2)


func _teleport(scooter: Scooter, pos: Vector3) -> void:
	scooter.global_transform = Transform3D(Basis.IDENTITY, pos)
	scooter.speed = 3.0


func _frames(n: int) -> void:
	for i in n:
		await get_tree().physics_frame


func _check(ok: bool, message: String) -> void:
	if not ok:
		_failures += 1
		print("  FAIL: ", message)
