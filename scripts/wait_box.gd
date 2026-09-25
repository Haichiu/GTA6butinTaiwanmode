class_name WaitBox
extends Area3D
## 待轉區: remembers whether the scooter actually stopped inside it (two-stage turn, stage one).

var waited := false
var _still_time := 0.0


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
