class_name Scooter
extends CharacterBody3D
## Arcade scooter: no physics simulation, just speed + heading.

@export var max_speed := 14.0  # m/s (~50 km/h)
@export var accel := 7.0
@export var brake_decel := 18.0
@export var coast_decel := 2.5
@export var turn_rate := 2.0  # rad/s at full steering authority

const PIVOT_RATE := 1.2  # rad/s when stopped

var speed := 0.0
var frozen := false

var _visual: Node3D
var _lean := 0.0
var _engine: AudioStreamPlayer


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	shape.shape = capsule
	shape.rotation.x = PI / 2.0  # lie along the travel axis
	shape.position.y = 0.45
	add_child(shape)
	_visual = _build_visual()
	add_child(_visual)
	floor_snap_length = 0.3
	_engine = AudioStreamPlayer.new()
	_engine.stream = Game.sfx.streams["engine"]
	_engine.volume_db = -10.0
	add_child(_engine)
	_engine.play()


func speed_kmh() -> float:
	return speed * 3.6


func _physics_process(delta: float) -> void:
	if frozen:
		_engine.stream_paused = true
		return
	_engine.pitch_scale = 0.7 + 1.8 * speed / max_speed
	var throttle := Input.get_action_strength("accelerate")
	var braking := Input.get_action_strength("brake")
	if braking > 0.0:
		speed = move_toward(speed, 0.0, brake_decel * braking * delta)
	elif throttle > 0.0:
		speed = move_toward(speed, max_speed, accel * throttle * delta)
	else:
		speed = move_toward(speed, 0.0, coast_decel * delta)

	var steer := Input.get_axis("steer_right", "steer_left")
	# Full authority from ~15 km/h. At a standstill the rider can still shuffle the scooter
	# around with their feet (slowly), which two-stage turns depend on.
	var authority := clampf(speed / 4.0, 0.0, 1.0)
	var turn := maxf(turn_rate * authority, PIVOT_RATE)
	rotation.y += steer * turn * delta

	var forward := -global_transform.basis.z
	velocity.x = forward.x * speed
	velocity.z = forward.z * speed
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()

	# Hitting a wall or a car bleeds speed instead of sliding along at full pace.
	for i in get_slide_collision_count():
		var n := get_slide_collision(i).get_normal()
		if absf(n.y) < 0.5 and forward.dot(n) < -0.3:
			speed *= 0.5

	_lean = lerpf(_lean, steer * 0.3 * authority, 8.0 * delta)
	_visual.rotation.z = _lean


func _build_visual() -> Node3D:
	var root := Node3D.new()
	root.name = "Visual"
	var body_color := Color(0.9, 0.92, 0.95)
	var trim := Color(0.15, 0.45, 0.8)
	var dark := Color(0.1, 0.1, 0.1)
	# Scooter body: floorboard, rear body, front shield, handlebar.
	RoadKit.box(root, Vector3(0.45, 0.12, 1.1), Vector3(0, 0.35, 0.05), body_color)
	RoadKit.box(root, Vector3(0.5, 0.45, 0.7), Vector3(0, 0.6, 0.45), body_color)
	RoadKit.box(root, Vector3(0.52, 0.12, 0.62), Vector3(0, 0.88, 0.45), dark)  # seat
	RoadKit.box(root, Vector3(0.45, 0.8, 0.15), Vector3(0, 0.75, -0.5), trim)
	RoadKit.box(root, Vector3(0.7, 0.06, 0.06), Vector3(0, 1.2, -0.55), dark)
	for z in [-0.6, 0.65]:
		var wheel := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.25
		cyl.bottom_radius = 0.25
		cyl.height = 0.14
		cyl.material = RoadKit.material(dark)
		wheel.mesh = cyl
		wheel.rotation.z = PI / 2.0
		wheel.position = Vector3(0, 0.25, z)
		root.add_child(wheel)
	# Rider: torso, arms, helmet.
	RoadKit.box(root, Vector3(0.45, 0.6, 0.3), Vector3(0, 1.25, 0.3), Color(0.25, 0.55, 0.35))
	RoadKit.box(root, Vector3(0.12, 0.12, 0.6), Vector3(0.25, 1.35, -0.1), Color(0.25, 0.55, 0.35))
	RoadKit.box(root, Vector3(0.12, 0.12, 0.6), Vector3(-0.25, 1.35, -0.1), Color(0.25, 0.55, 0.35))
	var helmet := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	sphere.material = RoadKit.material(Color(0.98, 0.8, 0.2))
	helmet.mesh = sphere
	helmet.position = Vector3(0, 1.75, 0.25)
	root.add_child(helmet)
	return root
