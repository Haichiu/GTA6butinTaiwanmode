class_name ViolationZone
extends Area3D
## Box on the road; the scooter entering it (optionally only while heading a given way) gets a ticket.

var law_id := ""
var contrast_id := ""
var caption := ""
## If non-zero, only trigger when the scooter's forward vector points within ~60° of this direction.
var heading := Vector3.ZERO
## Optional extra gate, e.g. "only while the light is red". Returns bool.
var condition := Callable()


## Convenience: create a zone covering [min_xz, max_xz] on the ground.
static func make(parent: Node3D, min_xz: Vector2, max_xz: Vector2, law: String, contrast := "", text := "", dir := Vector3.ZERO) -> ViolationZone:
	var zone := ViolationZone.new()
	zone.law_id = law
	zone.contrast_id = contrast
	zone.caption = text
	zone.heading = dir.normalized()
	var size := max_xz - min_xz
	var center := (min_xz + max_xz) / 2.0
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(size.x, 3.0, size.y)
	shape.shape = box
	zone.add_child(shape)
	zone.position = Vector3(center.x, 1.5, center.y)
	parent.add_child(zone)
	return zone


## Chainable: only trigger while `c` returns true.
func when(c: Callable) -> ViolationZone:
	condition = c
	return self


func _ready() -> void:
	monitorable = false


# Polled rather than body_entered: conditions (lights, flags) can flip while the scooter is inside.
func _physics_process(_delta: float) -> void:
	for body in get_overlapping_bodies():
		var scooter := body as Scooter
		if scooter == null or scooter.frozen:
			continue
		if heading != Vector3.ZERO:
			var forward := -scooter.global_transform.basis.z
			if forward.dot(heading) < 0.5:
				continue
		if condition.is_valid() and not condition.call():
			continue
		Game.report(law_id, contrast_id, caption)
