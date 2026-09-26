extends Control
## Last page after the fines: a plain tribute to the people who ride these roads for real.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.06, 0.07)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var text := Label.new()
	# Broken by hand so no line starts with punctuation.
	text.text = "謹向每天騎過台 61 西濱後龍段機車道、\n新北土城擺接堡路的用路人，\n以及全台每天在待轉區裡等紅燈的機車騎士，\n致上最深的敬意。\n\n你們每天都在玩這個遊戲。"
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_override("font", RoadKit.font())
	text.add_theme_font_size_override("font_size", 30)
	text.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
	text.position = Vector2(140, 170)
	text.size = Vector2(1000, 360)
	add_child(text)
	var hint := Label.new()
	hint.text = "按空白鍵回到標題"
	hint.add_theme_font_size_override("font_size", 18)
	hint.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	hint.position = Vector2(560, 650)
	add_child(hint)
	# Fade in slowly; this page is meant to be read.
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 1.2)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		Game.reset()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
