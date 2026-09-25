extends Node
## Global game state (autoload "Game"): input setup, law data, and the running fine tally.
## The tally survives restarts on purpose: every retry costs you.

signal violated(law_id: String, contrast_id: String, caption: String)

const LAWS_PATH := "res://data/laws.json"
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
var tickets: Array[String] = []  # law ids, in the order they were issued


func _ready() -> void:
	# Actions are registered in code so project.godot stays hand-editable.
	for action in KEYS:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for keycode in KEYS[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = keycode
			InputMap.action_add_event(action, ev)
	laws = _load_laws()


func law(id: String) -> Dictionary:
	assert(laws.has(id), "Unknown law id: %s" % id)
	return laws.get(id, {})


## Record a ticket and notify the level. Contrast is another law shown for comparison.
func report(law_id: String, contrast_id := "", caption := "") -> void:
	var l := law(law_id)
	total_fine += int(l.get("fine", 0))
	total_points += int(l.get("points", 0))
	tickets.append(law_id)
	violated.emit(law_id, contrast_id, caption)


func _load_laws() -> Dictionary:
	var text := FileAccess.get_file_as_string(LAWS_PATH)
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("laws"):
		push_error("Failed to load %s" % LAWS_PATH)
		return {}
	return parsed["laws"]
