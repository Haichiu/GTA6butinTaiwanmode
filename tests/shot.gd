extends Node
## Renders review screenshots of every level (needs a window, not headless):
##   godot --path . res://tests/shot.tscn -- <out_dir>

## [level, file name, scooter position, yaw]; position null = spawn point.
const SHOTS := [
	[1, "l1_start", null, 0.0],
	[1, "l1_squeeze", Vector3(7.7, 0.1, -25.0), 0.0],
	[2, "l2_approach", Vector3(8.75, 0.1, 40.0), 0.0],
	[2, "l2_detour", Vector3(62.0, 0.1, -20.0), 0.0],
	[3, "l3_stopbox", Vector3(9.9, 0.1, 28.0), 0.0],
	[3, "l3_waitbox", Vector3(12.5, 0.1, -5.3), PI / 2.0],
	[4, "l4_start", null, 0.0],
	[4, "l4_waitbox", Vector3(-9.5, 0.1, -5.3), -PI / 2.0],
	[5, "l5_bridge", Vector3(8.3, 0.1, -60.0), 0.0],
	[6, "l6_ramp", Vector3(5.25, 0.1, -20.0), 0.0],
	[6, "l6_truck", Vector3(8.3, 0.1, -230.0), 0.0],
]


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://shots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var only: String = args[1] if args.size() > 1 else ""  # optional name prefix filter, e.g. "l6"
	for s in SHOTS:
		if only != "" and not str(s[1]).begins_with(only):
			continue
		Game.level_index = s[0] - 1
		var level: LevelBase = load(Game.LEVELS[s[0] - 1]).instantiate()
		add_child(level)
		await _frames(5)
		if s[2] != null:
			level.scooter.global_transform = Transform3D(Basis(Vector3.UP, s[3]), s[2])
			level.camera.global_position = level.camera._desired_position()
		level.scooter.frozen = true  # hold still for the picture
		if s[0] == 6 and s[1] == "l6_truck":
			level.truck.global_position = Vector3(3.8, 0, -265.0)
			level.truck.rotation.y = 0.0
			level.truck.set_physics_process(false)
		await _frames(30)
		await _shot("%s/%s.png" % [out_dir, s[1]])
		level.queue_free()
		await _frames(2)
	get_tree().quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
