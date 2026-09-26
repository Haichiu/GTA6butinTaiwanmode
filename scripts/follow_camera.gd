class_name FollowCamera
extends Camera3D
## Elevated chase camera: behind and above the target, looking a little ahead of it.

@export var distance := 7.5
@export var height := 5.5
@export var look_ahead := 4.0
@export var smoothing := 6.0

var target: Node3D


func _ready() -> void:
	top_level = true
	fov = 60.0
	if target:
		global_position = _desired_position()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	global_position = global_position.lerp(_desired_position(), clampf(smoothing * delta, 0.0, 1.0))
	# Rough road: the whole view shakes.
	var rough: float = target.get("bump") if target.get("bump") != null else 0.0
	if rough > 0.0:
		global_position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * 0.06 * rough
	var forward := -target.global_transform.basis.z
	look_at(target.global_position + forward * look_ahead + Vector3.UP * 0.5)


func _desired_position() -> Vector3:
	var back := target.global_transform.basis.z
	return target.global_position + back * distance + Vector3.UP * height
