extends Control
## Title screen.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.position = Vector2(140, 180)
	box.add_theme_constant_override("separation", 18)
	add_child(box)
	box.add_child(_label("GTA6 but in Taiwan mode", 64, Color(1, 0.85, 0.3), true))
	box.add_child(_label("你不是輸在技術，是輸給交通法規。", 30, Color.WHITE))
	box.add_child(_label("方向鍵／WASD 騎車　R／Enter／空白鍵 重來", 22, Color(0.75, 0.75, 0.75)))
	box.add_child(_label("按空白鍵開始", 28, Color(0.7, 0.9, 1.0)))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		Game.reset()
		Game.start_level(0)


func _label(text: String, size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", RoadKit.font())
	return label
