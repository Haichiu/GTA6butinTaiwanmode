extends Node
## Renders a few screenshots for visual review. Run (needs a window, not headless):
##   godot --path . res://tests/shot.tscn -- <out_dir>

const LEVEL := "res://scenes/main.tscn"


func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://shots"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var level: LevelBase = load(LEVEL).instantiate()
	add_child(level)
	await _frames(30)
	await _shot(out_dir + "/1_start.png")

	_place(level, Vector3(8.75, 0.1, 30.0))
	await _frames(40)
	await _shot(out_dir + "/2_intersection.png")

	_place(level, Vector3(8.75, 0.1, -30.0))
	await _frames(40)
	await _shot(out_dir + "/3_waiting_box.png")

	_place(level, Vector3(5.25, 0.1, 40.0))
	await _frames(60)
	await _shot(out_dir + "/4_ticket.png")
	for t in level.find_children("*", "Ticket", true, false):
		for c in t.find_children("*", "Control", true, false):
			print(c.get_class(), " ", c.get_global_rect(), " a=", c.modulate.a, " vis=", c.is_visible_in_tree())
	get_tree().quit()


func _place(level: LevelBase, pos: Vector3) -> void:
	level.scooter.global_transform = Transform3D(Basis.IDENTITY, pos)
	level.camera.global_position = level.camera._desired_position()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
