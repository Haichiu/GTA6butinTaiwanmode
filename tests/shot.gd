extends Node
## Renders review screenshots of every level (needs a window, not headless):
##   godot --path . res://tests/shot.tscn -- <out_dir>

## [level, file name, scooter position, yaw]; position null = spawn point.
const SHOTS := [
	[1, "l1_street", Vector3(8.75, 0.1, -60.0), 0.0],
	[3, "l3_street", Vector3(9.9, 0.1, 45.0), 0.0],
	[7, "l7_bridge", null, 0.0],
	[7, "l7_narrow", Vector3(11.4, 0.1, -70.0), 0.0],
	[7, "l7_loop", Vector3(20.0, 0.1, -106.0), -PI / 2.0],
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
		if s.size() > 4:
			# Show the real ticket for this law as the level would (caption/contrast from its zone).
			for z in level.find_children("*", "ViolationZone", true, false):
				if z.law_id == s[4]:
					level._on_violated(z.law_id, z.contrast_id, z.caption, true)
					break
		if s[0] == 6 and s[1] == "l6_truck":
			level.truck.global_position = Vector3(3.8, 0, -265.0)
			level.truck.rotation.y = 0.0
			level.truck.set_physics_process(false)
		if s[1] == "l1_truck" and level.get("truck") != null:
			level.truck.global_position = Vector3(6.3, 0, -262.0)
			level.truck.rotation.y = 0.0
			level.truck.set_physics_process(false)
		await _frames(150 if s[1] in ["l1_uncle", "l1_street", "l3_street"] else 30)
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
