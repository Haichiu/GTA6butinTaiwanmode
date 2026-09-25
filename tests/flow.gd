extends Node
## Screenshots of the title and summary screens, exercising real scene changes:
##   godot --path . res://tests/flow.tscn -- <out_dir>


func _ready() -> void:
	var out_dir: String = OS.get_cmdline_user_args()[0]
	# Outlive scene changes by moving under the root instead of being the current scene.
	var tree := get_tree()
	get_parent().remove_child.call_deferred(self)
	await tree.process_frame
	tree.root.add_child(self)
	tree.change_scene_to_file("res://scenes/main.tscn")
	await _frames(20)
	await _shot(out_dir + "/title.png")
	# Pretend a run happened, then advance past the last level.
	Game.reset()
	for id in ["lane_ban", "turn_lane_straight", "two_stage_left", "red_light", "two_stage_right", "lane_ban", "wait_outside_box",
			"no_left_turn", "uturn_double_yellow", "crosswalk_stop", "stop_line", "expressway_scooter", "rear_end", "sidewalk"]:
		Game.report(id)
	Game.level_index = Game.LEVELS.size() - 1
	Game.next_level()
	await _frames(20)
	print("current scene: ", tree.current_scene.scene_file_path)
	await _shot(out_dir + "/summary.png")
	tree.quit()


func _shot(path: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(path)
	print("saved ", path)


func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame
