class_name Ticket
extends CanvasLayer
## The traffic ticket that slides in on a violation. Built in code; call show_ticket().

const PAPER := Color(0.98, 0.96, 0.9)
const INK := Color(0.12, 0.12, 0.14)
const STAMP := Color(0.8, 0.12, 0.12)
const TEXT_WIDTH := 584.0  # panel min width 640 minus 2 * 28 margin

var _panel: PanelContainer
var _flash: ColorRect


func _ready() -> void:
	layer = 10
	_flash = ColorRect.new()
	_flash.color = Color(0.9, 0.1, 0.1, 0.0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)


func show_ticket(law_id: String, contrast_id: String, caption: String) -> void:
	var l := Game.law(law_id)
	_panel = PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PAPER
	style.border_color = STAMP
	style.set_border_width_all(6)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(28)
	_panel.add_theme_stylebox_override("panel", style)
	_panel.custom_minimum_size = Vector2(640, 0)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)
	box.add_child(_label("交通違規罰單", 40, STAMP, true))
	box.add_child(_label("違規事項：%s" % l["title"], 26, INK))
	box.add_child(_label(l["article"], 18, INK.lightened(0.3)))
	var points := "　記違規點數 %d 點" % l["points"] if int(l["points"]) > 0 else ""
	box.add_child(_label("罰鍰：新臺幣 %s 元%s" % [_money(l["fine"]), points], 30, STAMP, true))

	if contrast_id != "":
		box.add_child(HSeparator.new())
		var c := Game.law(contrast_id)
		if caption != "":
			box.add_child(_label(caption, 22, INK, true))
		box.add_child(_label("對照：%s　新臺幣 %s 元" % [c["title"], _money(c["fine"])], 20, INK))
		box.add_child(_label(c["article"], 16, INK.lightened(0.3)))

	box.add_child(HSeparator.new())
	box.add_child(_label("今日累計罰款：新臺幣 %s 元" % _money(Game.total_fine), 20, INK))
	box.add_child(_label("按 R／Enter／空白鍵 重來", 18, INK.lightened(0.3)))

	# A full-screen holder slides; the panel stays centered inside it.
	var center := Control.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	center.add_child(_panel)
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	# Red flash, then the ticket slides up from below.
	_flash.color.a = 0.55
	var tw := create_tween()
	tw.tween_property(_flash, "color:a", 0.15, 0.4)
	_panel.modulate.a = 0.0
	center.position.y = 200
	var tw2 := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw2.tween_property(center, "position:y", 0.0, 0.35).set_delay(0.15)
	tw2.parallel().tween_property(_panel, "modulate:a", 1.0, 0.2).set_delay(0.15)


func _label(text: String, size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# Fixed width: autowrap labels with zero width report absurd heights during layout.
	label.custom_minimum_size.x = TEXT_WIDTH
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", RoadKit.font())
	return label


static func _money(amount) -> String:
	var s := str(int(amount))
	var out := ""
	while s.length() > 3:
		out = "," + s.substr(s.length() - 3) + out
		s = s.substr(0, s.length() - 3)
	return s + out
