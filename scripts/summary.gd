extends Control
## End screen: every ticket you collected, the total, what it costs in minimum-wage hours, and
## the source of every law cited. Content scrolls (wheel or ↑/↓); the restart hint stays put.

const WIDTH := 1060.0
const MIN_WAGE_HOURLY := 196  # 最低工資時薪, 2026-01-01 起（勞動部公告）
const MIN_WAGE_URL := "https://www.mol.gov.tw/1607/1632/1633/84947/post"
const FINE_TABLE_URL := "https://law.moj.gov.tw/LawClass/LawAll.aspx?pcode=D0080029"

var _scroll: ScrollContainer


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.1, 0.12)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	_scroll = ScrollContainer.new()
	_scroll.position = Vector2(90, 24)
	_scroll.size = Vector2(WIDTH + 30, 620)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(_scroll)
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(WIDTH, 0)
	box.add_theme_constant_override("separation", 6)
	_scroll.add_child(box)

	box.add_child(_label("今日交通罰單明細", 40, Color(1, 0.85, 0.3), true))
	var counts := {}
	for id in Game.tickets:
		counts[id] = counts.get(id, 0) + 1
	if counts.is_empty():
		box.add_child(_label("一張都沒有。你是台灣最守法的機車騎士（或是你開了 GM 模式）。", 24, Color.WHITE))
	for id in counts:
		var l := Game.law(id)
		box.add_child(_label("%s × %d　　NT$ %s" % [l["title"], counts[id], Ticket._money(int(l["fine"]) * counts[id])], 22, Color.WHITE))

	box.add_child(HSeparator.new())
	box.add_child(_label("總計：新臺幣 %s 元　記違規點數 %d 點" % [Ticket._money(Game.total_fine), Game.total_points], 30, Color(1, 0.4, 0.35), true))
	if Game.total_fine > 0:
		var hours := float(Game.total_fine) / MIN_WAGE_HOURLY
		var truck := float(Game.law("oncoming_truck")["fine"])
		box.add_child(_label("＝ 用最低時薪 %d 元工作 %.1f 小時。" % [MIN_WAGE_HOURLY, hours], 22, Color.WHITE))
		box.add_child(_label("＝ 一台跨雙黃線逆向的聯結車被罰 %.1f 次。" % (Game.total_fine / truck), 22, Color.WHITE))

	# To the people who ride these roads for real.
	box.add_child(HSeparator.new())
	box.add_child(_label("謹向每天騎過台 61 西濱後龍段機車道、新北土城擺接堡路的用路人，以及全台每天在待轉區裡等紅燈的機車騎士，致上最深的敬意。", 22, Color(1, 0.85, 0.3), true))
	box.add_child(_label("你們每天都在玩這個遊戲，而且沒有 R 鍵。", 22, Color.WHITE))

	# Sources: one line per article (all clauses of it merged), then the fine table and wage.
	box.add_child(HSeparator.new())
	box.add_child(_label("出處", 18, Color(0.75, 0.75, 0.75), true))
	var by_url := {}
	for id in counts:
		var l := Game.law(id)
		var name := Ticket._short(l["article"]).get_slice("（", 0)
		if not by_url.has(l["url"]):
			by_url[l["url"]] = []
		if not by_url[l["url"]].has(name):
			by_url[l["url"]].append(name)
	for url in by_url:
		box.add_child(_label("%s\n%s" % ["、".join(PackedStringArray(by_url[url])), url], 15, Color(0.65, 0.65, 0.65)))
	box.add_child(_label("罰鍰金額：違反道路交通管理事件統一裁罰基準表\n" + FINE_TABLE_URL, 15, Color(0.65, 0.65, 0.65)))
	box.add_child(_label("最低工資：勞動部公告（115 年 1 月 1 日起時薪 196 元）\n" + MIN_WAGE_URL, 15, Color(0.65, 0.65, 0.65)))

	var footer := _label("按空白鍵重新開始　（↑↓ 或滑鼠滾輪捲動）", 22, Color(0.7, 0.9, 1.0))
	footer.position = Vector2(90, 660)
	add_child(footer)


func _process(delta: float) -> void:
	var dir := Input.get_axis("accelerate", "brake")  # ↑ / ↓ (also W / S)
	if dir != 0.0:
		_scroll.scroll_vertical += int(dir * 600.0 * delta)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		Game.reset()
		Game.start_level(0)


func _label(text: String, size: int, color: Color, bold := false) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY  # CJK and long URLs: break anywhere
	label.custom_minimum_size.x = WIDTH
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if bold:
		label.add_theme_font_override("font", RoadKit.font())
	return label
