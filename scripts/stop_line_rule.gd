class_name StopLineRule
extends Node
## How a red light is actually enforced at a stop line (警政署說明, see docs/laws.md):
##   rear of the scooter past the line          -> 闖紅燈 (red_light, 1,800)
##   stopped with the front wheel past the line -> 不遵守標線 (stop_line, 900)
##   stopped with only the nose past the line   -> 勸導, no fine
## Only armed while the scooter is still behind the line, so riders already in the
## intersection when the light changes are not ticketed.

const NOSE := 0.9  # scooter front end, meters ahead of its origin
const FRONT_WHEEL := 0.6
const REAR := 0.9

var level: LevelBase
var sig: TrafficSignal
var axis := "ns"
var travel := Vector3.FORWARD  # direction of travel toward the line
var line_pos := 0.0  # dot(point, travel) of the stop line
var lateral_min := 0.0  # band across the approach, measured along `side`
var lateral_max := 0.0

var _armed := false
var _warned := false


static func make(lvl: LevelBase, s: TrafficSignal, ax: String, dir: Vector3, line_point: Vector3, lat_min: float, lat_max: float) -> StopLineRule:
	var r := StopLineRule.new()
	r.level = lvl
	r.sig = s
	r.axis = ax
	r.travel = dir.normalized()
	r.line_pos = line_point.dot(r.travel)
	r.lateral_min = lat_min
	r.lateral_max = lat_max
	lvl.add_child(r)
	return r


func _physics_process(_delta: float) -> void:
	var s := level.scooter
	if s == null or s.frozen:
		return
	var side := Vector3(-travel.z, 0, travel.x)  # right-hand perpendicular... sign irrelevant, band uses both ends
	var lat := s.global_position.dot(side)
	if lat < minf(lateral_min, lateral_max) or lat > maxf(lateral_min, lateral_max):
		return
	var forward := -s.global_transform.basis.z
	var heading_ok := forward.dot(travel) > 0.5
	var along := s.global_position.dot(travel) - line_pos  # > 0 means past the line
	var rear_past := along - REAR * maxf(forward.dot(travel), 0.0) > 0.0
	if not rear_past and along < 2.0:
		_armed = true
	if not _armed or not heading_ok or not sig.is_red(axis):
		if rear_past and not sig.is_red(axis):
			_armed = false  # went through on green/yellow
		return
	if rear_past:
		Game.report("red_light", "car_speeding",
			"整台車過了停止線＝闖紅燈 1,800；汽車超速 20 公里以內只要 1,600。")
		return
	if s.speed > 0.3:
		return
	if along + FRONT_WHEEL > 0.0:
		Game.report("stop_line", "car_in_box",
			"前輪壓過停止線 900＝一台汽車整台停在機車停等區 900。")
	elif along + NOSE > 0.0 and not _warned:
		_warned = true
		level.toast("警察：車頭凸出停止線，但輪子沒過線，勸導一次。")
