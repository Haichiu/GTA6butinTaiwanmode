class_name NpcVehicle
extends AnimatableBody3D
## A scripted vehicle (or cyclist/pedestrian) that drives along waypoints at a fixed speed.
## It pushes the scooter physically; levels can react to contact via `touched`.

signal touched

var waypoints: Array[Vector3] = []
var speed := 8.0
var loop := false
## Start moving only once the scooter is within this distance (0 = start immediately).
var trigger_distance := 0.0
var target: Node3D
## While true the vehicle waits in place (e.g. at a red light); the level releases it.
var hold := false
## Ordinary traffic stops for a scooter right in front of it. Scripted "hit you" vehicles don't.
var yields := true
## Remove the vehicle when it reaches the end of its path (traffic streams).
var free_at_end := false
## Signal-controlled traffic: stop short of `stop_point` while `can_go` returns false.
var stop_point := Vector3.INF
var can_go := Callable()

## Seconds to stand still on arriving at a waypoint index (e.g. 老阿伯 stopping mid-lane).
var dwell := {}

var _index := 1
var _active := false
var _done := false
var _wait := 0.0


## Build from a model scene (Kenney vehicles face +Z) scaled to `length` meters.
static func make(parent: Node3D, model_path: String, length: float, points: Array[Vector3], mps: float) -> NpcVehicle:
	var inst: Node3D = load(model_path).instantiate()
	var holder := Node3D.new()
	holder.add_child(inst)
	var aabb := LevelBase.aabb_of(inst)
	var extent := maxf(aabb.size.x, aabb.size.z)
	var s := length / extent if extent > 0.0 else 1.0
	holder.scale = Vector3.ONE * s
	return make_custom(parent, holder, AABB(aabb.position * s, aabb.size * s), points, mps)


## Build from any visual node (facing +Z) whose local bounds are `bounds`.
static func make_custom(parent: Node3D, visual: Node3D, bounds: AABB, points: Array[Vector3], mps: float) -> NpcVehicle:
	var npc := NpcVehicle.new()
	npc.waypoints = points
	npc.speed = mps
	npc.sync_to_physics = false
	npc.add_child(visual)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = bounds.size
	shape.shape = box
	shape.position = bounds.get_center()
	npc.add_child(shape)
	# Slightly larger sensor so contact registers even when the scooter is pushed, not moving.
	var sensor := Area3D.new()
	var sensor_shape := CollisionShape3D.new()
	var grown := BoxShape3D.new()
	# Solid bodies stop just short of each other, so the sensor must reach past the collider.
	grown.size = box.size + Vector3(1.0, 0.4, 1.0)
	sensor_shape.shape = grown
	sensor_shape.position = shape.position
	sensor.add_child(sensor_shape)
	sensor.body_entered.connect(func(body: Node3D) -> void:
		if body is Scooter:
			npc.touched.emit())
	npc.add_child(sensor)
	parent.add_child(npc)
	npc.global_position = points[0]
	if points.size() > 1:
		npc._face(points[1] - points[0])
	return npc


func _physics_process(delta: float) -> void:
	if _done or hold or waypoints.size() < 2:
		return
	if not _active:
		_active = trigger_distance <= 0.0 or (target != null and target.global_position.distance_to(global_position) < trigger_distance)
		if not _active:
			return
	if _wait > 0.0:
		_wait -= delta
		return
	var goal := waypoints[_index]
	var to_goal := goal - global_position
	if yields and _blocked_by_target(to_goal):
		return
	if _held_at_stop_line(to_goal):
		return
	var step := speed * delta
	if to_goal.length() <= step:
		global_position = goal
		_wait = dwell.get(_index, 0.0)
		_index += 1
		if _index >= waypoints.size():
			if loop:
				_index = 0
			else:
				_done = true
				if free_at_end:
					queue_free()
				return
		_face(waypoints[_index] - global_position)
	else:
		global_position += to_goal.normalized() * step


## Is the scooter (or another car in the same stream) just ahead of us?
func _blocked_by_target(to_goal: Vector3) -> bool:
	if to_goal.length() < 0.01:
		return false
	var dir := Vector3(to_goal.x, 0, to_goal.z).normalized()
	if target != null and _just_ahead(target.global_position, dir, 9.0):
		return true
	for other in get_tree().get_nodes_in_group("traffic"):
		if other != self and _just_ahead((other as Node3D).global_position, dir, 7.5):
			return true
	return false


func _just_ahead(pos: Vector3, dir: Vector3, gap: float) -> bool:
	var rel := pos - global_position
	rel.y = 0.0
	var ahead := rel.dot(dir)
	return ahead > 0.0 and ahead < gap and (rel - dir * ahead).length() < 1.8


## Red light ahead and we haven't reached the line yet: wait with our nose at the line.
func _held_at_stop_line(to_goal: Vector3) -> bool:
	if stop_point == Vector3.INF or not can_go.is_valid() or can_go.call():
		return false
	var dir := Vector3(to_goal.x, 0, to_goal.z).normalized()
	var ahead := (stop_point - global_position).dot(dir)
	return ahead > 0.0 and ahead < 3.2  # ~half a car length: stop with the front at the line


func _face(dir: Vector3) -> void:
	if Vector2(dir.x, dir.z).length() > 0.01:
		rotation.y = atan2(dir.x, dir.z)
