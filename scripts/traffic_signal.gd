class_name TrafficSignal
extends Node3D
## Two-phase signal controller for one intersection (north-south vs east-west) with
## Taiwanese-style countdown displays. Heads are added with add_head().

const GREEN_TIME := 10.0
const YELLOW_TIME := 2.0
const ALL_RED := 1.0

enum Phase { NS_GO, NS_YELLOW, ALL_RED_1, EW_GO, EW_YELLOW, ALL_RED_2 }

var phase := Phase.NS_GO
var remaining := GREEN_TIME
var _heads: Array[Dictionary] = []  # {axis, lamps: [red, yellow, green], counter}


static func durations() -> Dictionary:
	return {
		Phase.NS_GO: GREEN_TIME, Phase.NS_YELLOW: YELLOW_TIME, Phase.ALL_RED_1: ALL_RED,
		Phase.EW_GO: GREEN_TIME, Phase.EW_YELLOW: YELLOW_TIME, Phase.ALL_RED_2: ALL_RED,
	}


## Start at `start_phase` with `left` seconds remaining (levels use this to set up the dilemma).
func setup(start_phase: Phase, left: float) -> void:
	phase = start_phase
	remaining = left
	_refresh()


## "green" / "yellow" / "red" for traffic moving along `axis` ("ns" or "ew").
func state(axis: String) -> String:
	return state_of(phase, axis)


static func state_of(p: Phase, axis: String) -> String:
	match p:
		Phase.NS_GO:
			return "green" if axis == "ns" else "red"
		Phase.NS_YELLOW:
			return "yellow" if axis == "ns" else "red"
		Phase.EW_GO:
			return "green" if axis == "ew" else "red"
		Phase.EW_YELLOW:
			return "yellow" if axis == "ew" else "red"
	return "red"


func is_red(axis: String) -> bool:
	return state(axis) == "red"


func _physics_process(delta: float) -> void:
	remaining -= delta
	if remaining <= 0.0:
		phase = ((phase + 1) % 6) as Phase
		remaining += durations()[phase]
	_refresh()


## A signal head on a pole at `pos` for traffic travelling in `travel_dir`;
## the lamps face back toward the approaching riders.
func add_head(pos: Vector3, axis: String, travel_dir: Vector3) -> void:
	var pole := Node3D.new()
	add_child(pole)
	pole.position = pos
	pole.rotation.y = atan2(travel_dir.x, travel_dir.z)  # local +Z = travel direction
	var dark := Color(0.15, 0.15, 0.15)
	RoadKit.box(pole, Vector3(0.2, 5.0, 0.2), Vector3(0, 2.5, 0), dark)
	RoadKit.box(pole, Vector3(0.5, 1.5, 0.35), Vector3(0, 4.6, 0), dark)
	var lamps: Array[MeshInstance3D] = []
	for i in 3:
		var lamp := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.17
		sphere.height = 0.34
		lamp.mesh = sphere
		lamp.material_override = StandardMaterial3D.new()
		# Lamps sit on the face pointing against travel (toward riders approaching).
		lamp.position = Vector3(0, 5.1 - i * 0.45, -0.2)
		pole.add_child(lamp)
		lamps.append(lamp)
	var counter := Label3D.new()
	counter.font = RoadKit.font()
	counter.font_size = 96
	counter.pixel_size = 0.006
	counter.position = Vector3(0, 3.6, -0.2)
	counter.rotation.y = PI
	counter.outline_size = 12
	pole.add_child(counter)
	_heads.append({"axis": axis, "lamps": lamps, "counter": counter})
	_refresh()


func _refresh() -> void:
	for head in _heads:
		var s := state(head["axis"])
		var on: int = {"red": 0, "yellow": 1, "green": 2}[s]
		var colors := [Color(1, 0.15, 0.1), Color(1, 0.75, 0.1), Color(0.1, 1, 0.4)]
		for i in 3:
			var mat: StandardMaterial3D = head["lamps"][i].material_override
			if i == on:
				mat.albedo_color = colors[i]
				mat.emission_enabled = true
				mat.emission = colors[i]
				mat.emission_energy_multiplier = 2.0
			else:
				mat.albedo_color = colors[i].darkened(0.8)
				mat.emission_enabled = false
		var label: Label3D = head["counter"]
		label.text = str(ceili(_seconds_until_change(head["axis"])))
		label.modulate = colors[on]


## Seconds until this axis's light changes color (what the countdown display shows).
func _seconds_until_change(axis: String) -> float:
	var d := durations()
	var t := remaining
	var p := phase
	var current := state(axis)
	# Walk forward through phases until the color for this axis changes.
	for i in 6:
		p = ((p + 1) % 6) as Phase
		if state_of(p, axis) != current:
			return t
		t += d[p]
	return t
