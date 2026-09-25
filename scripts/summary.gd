extends Control
## End screen: every ticket you collected, the total, and one comparison to put it in perspective.


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.position = Vector2(140, 60)
	box.custom_minimum_size = Vector2(1000, 0)
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	box.add_child(_label("今日交通罰單明細", 44, Color(1, 0.85, 0.3), true))

	var counts := {}
	for id in Game.tickets:
		counts[id] = counts.get(id, 0) + 1
	if counts.is_empty():
		box.add_child(_label("一張都沒有。你是台灣最守法的機車騎士（或是你作弊）。", 26, Color.WHITE))
	for id in counts:
		var l := Game.law(id)
		box.add_child(_label("%s × %d　　NT$ %s" % [l["title"], counts[id], Ticket._money(int(l["fine"]) * counts[id])], 24, Color.WHITE))

	box.add_child(HSeparator.new())
	box.add_child(_label("總計：新臺幣 %s 元　記違規點數 %d 點" % [Ticket._money(Game.total_fine), Game.total_points], 32, Color(1, 0.4, 0.35), true))
	var truck := int(Game.law("oncoming_truck")["fine"])
	if Game.total_fine > 0:
		var times := float(Game.total_fine) / truck
		box.add_child(_label("相當於一台跨雙黃線逆向的聯結車被罰 %.1f 次。" % times, 24, Color.WHITE))
	box.add_child(_label("所有條文與金額都是真的，出處見 docs/laws.md。", 18, Color(0.7, 0.7, 0.7)))
	box.add_child(_label("按空白鍵重新開始", 22, Color(0.7, 0.9, 1.0)))


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		Game.reset()
		Game.start_level(0)


func _label(text: String, size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY  # CJK: break anywhere
	label.custom_minimum_size.x = 1000
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", RoadKit.font())
	return label
