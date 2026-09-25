class_name WaitBox
extends Area3D
## 待轉區: remembers whether the scooter actually stopped inside it (two-stage turn, stage one).

var waited := false
var _still_time := 0.0
## Area where stopping to wait counts as "waiting outside the 待轉區" (set by the level).
var turn_area := Rect2()
var _outside_time := 0.0
var _fined_outside := false


static func make(parent: Node3D, min_xz: Vector2, max_xz: Vector2) -> WaitBox:
	var box := WaitBox.new()
	var size := max_xz - min_xz
	var center := (min_xz + max_xz) / 2.0
	var shape := CollisionShape3D.new()
	var b := BoxShape3D.new()
	b.size = Vector3(size.x, 3.0, size.y)
	shape.shape = b
	box.add_child(shape)
	box.position = Vector3(center.x, 1.5, center.y)
	parent.add_child(box)
	return box


func _physics_process(delta: float) -> void:
	var inside := false
	for body in get_overlapping_bodies():
		var scooter := body as Scooter
		if scooter != null and scooter.speed < 0.8:
			inside = true
	_still_time = _still_time + delta if inside else 0.0
	if _still_time > 0.3:
		waited = true
	_check_outside(delta)


func _check_outside(delta: float) -> void:
	if turn_area.size == Vector2.ZERO or _fined_outside:
		return
	var scooter := get_tree().get_first_node_in_group("scooter") as Scooter
	if scooter == null or scooter.frozen:
		return
	var p := Vector2(scooter.global_position.x, scooter.global_position.z)
	var shape_box := ((get_child(0) as CollisionShape3D).shape as BoxShape3D).size
	var mine := Rect2(Vector2(position.x, position.z) - Vector2(shape_box.x, shape_box.z) / 2.0, Vector2(shape_box.x, shape_box.z)).grow(0.2)
	var waiting := scooter.speed < 0.2 and turn_area.has_point(p) and not mine.has_point(p)
	_outside_time = _outside_time + delta if waiting else 0.0
	if _outside_time > 1.0:
		_fined_outside = true
		Game.report("wait_outside_box", "car_in_box",
			"待轉要停在格子裡：停在格子外罰 600。\n汽車整台停進機車停等區，也才 900。")
