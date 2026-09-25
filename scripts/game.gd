extends Node
## Global game state (autoload "Game"): input setup, law data, level order and the running fine tally.
## The tally survives restarts on purpose: every retry costs you.

## charged=false means the ticket is someone else's (shown for contrast, not added to your total).
signal violated(law_id: String, contrast_id: String, caption: String, charged: bool)

const LAWS_PATH := "res://data/laws.json"
const LEVELS: Array[String] = [
	"res://scenes/levels/level_1.tscn",
	"res://scenes/levels/level_2.tscn",
	"res://scenes/levels/level_3.tscn",
	"res://scenes/levels/level_4.tscn",
	"res://scenes/levels/level_5.tscn",
	"res://scenes/levels/level_6.tscn",
	"res://scenes/levels/level_7.tscn",
]
const SUMMARY := "res://scenes/summary.tscn"
const KEYS := {
	"accelerate": [KEY_UP, KEY_W],
	"brake": [KEY_DOWN, KEY_S],
	"steer_left": [KEY_LEFT, KEY_A],
	"steer_right": [KEY_RIGHT, KEY_D],
	"restart": [KEY_R, KEY_ENTER, KEY_SPACE],
}

var laws := {}
var total_fine := 0
var total_points := 0
var tickets: Array[String] = []  # law ids charged to the player, in order
var level_index := 0
## GM (testing) mode: tickets and crashes don't stop you; number keys jump between levels.
## Internal only: available in debug runs (editor / `godot --path .`), never in exported releases.
var gm_available := OS.is_debug_build()
var gm := false
## Hazards and ambient traffic. Rule tests switch this off so they stay deterministic.
var ambient := true
var sfx: Sfx


func _ready() -> void:
	# Actions are registered in code so project.godot stays hand-editable.
	for action in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in KEYS[action]:
			# Register by physical position and by logical key: browsers don't always report both.
			var physical := InputEventKey.new()
			physical.physical_keycode = keycode
			InputMap.action_add_event(action, physical)
			var logical := InputEventKey.new()
			logical.keycode = keycode
			InputMap.action_add_event(action, logical)
	laws = _load_laws()
	gm = gm_available and OS.get_cmdline_user_args().has("--gm")
	# Owned here rather than a second autoload, so project.godot needs no edits while the editor is open.
	sfx = Sfx.new()
	add_child(sfx)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.pressed or key.echo:
		return
	if not gm_available:
		return
	if key.physical_keycode == KEY_G:
		gm = not gm
		get_viewport().set_input_as_handled()
	elif gm and key.physical_keycode >= KEY_1 and key.physical_keycode <= KEY_9:
		var index := key.physical_keycode - KEY_1
		if index < LEVELS.size():
			start_level(index)
			get_viewport().set_input_as_handled()
	elif gm and key.physical_keycode == KEY_N:
		next_level()
		get_viewport().set_input_as_handled()


func law(id: String) -> Dictionary:
	assert(laws.has(id), "Unknown law id: %s" % id)
	return laws.get(id, {})


## Issue a ticket. Contrast is another law shown for comparison.
func report(law_id: String, contrast_id := "", caption := "", charged := true) -> void:
	if charged:
		var l := law(law_id)
		total_fine += int(l.get("fine", 0))
		total_points += int(l.get("points", 0))
		tickets.append(law_id)
	violated.emit(law_id, contrast_id, caption, charged)


func reset() -> void:
	total_fine = 0
	total_points = 0
	tickets.clear()
	level_index = 0


func start_level(index: int) -> void:
	level_index = index
	get_tree().change_scene_to_file(LEVELS[index] if index < LEVELS.size() else SUMMARY)


func next_level() -> void:
	start_level(level_index + 1)


func _load_laws() -> Dictionary:
	var text := FileAccess.get_file_as_string(LAWS_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("laws"):
		push_error("Failed to load %s" % LAWS_PATH)
		return {}
	return parsed["laws"]
