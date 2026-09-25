class_name LevelBase
extends Node3D
## Shared level setup: lighting, ground, scooter, camera, HUD.
## Subclasses override build() to lay out roads, and spawn_transform() for the start.

var scooter: Scooter
var camera: FollowCamera
var _speed_label: Label
var _fine_label: Label
var _message: Label
var _ended := false
var _can_restart := false


func _ready() -> void:
	_setup_environment()
	build()
	scooter = Scooter.new()
	scooter.name = "Scooter"
	add_child(scooter)
	scooter.global_transform = spawn_transform()
	camera = FollowCamera.new()
	camera.target = scooter
	add_child(camera)
	camera.make_current()
	_setup_hud()
	Game.violated.connect(_on_violated)


func build() -> void:
	pass


func spawn_transform() -> Transform3D:
	return Transform3D.IDENTITY


func _process(_delta: float) -> void:
	_speed_label.text = "%d km/h" % roundi(scooter.speed_kmh())
	_fine_label.text = "今日罰款 NT$ %s" % Ticket._money(Game.total_fine)


func _unhandled_input(event: InputEvent) -> void:
	if _can_restart and event.is_action_pressed("restart"):
		get_tree().reload_current_scene()


## Area that ends the level successfully when the scooter reaches it.
func goal(min_xz: Vector2, max_xz: Vector2, text := "抵達目的地") -> void:
	var area := Area3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var size := max_xz - min_xz
	box.size = Vector3(size.x, 3.0, size.y)
	shape.shape = box
	area.add_child(shape)
	var center := (min_xz + max_xz) / 2.0
	area.position = Vector3(center.x, 1.5, center.y)
	area.body_entered.connect(func(body: Node3D) -> void:
		if body == scooter and not _ended:
			_end()
			_show_message("%s！\n按 R／Enter／空白鍵 再玩一次" % text))
	add_child(area)
	# Visible marker: a translucent green column.
	var marker := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(size.x, 0.05, size.y)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.9, 0.4, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh.material = mat
	marker.mesh = mesh
	marker.position = Vector3(center.x, 0.06, center.y)
	add_child(marker)


func _on_violated(law_id: String, contrast_id: String, caption: String) -> void:
	if _ended:
		return
	_end()
	var ticket := Ticket.new()
	add_child(ticket)
	ticket.show_ticket(law_id, contrast_id, caption)


func _end() -> void:
	_ended = true
	scooter.frozen = true
	# Short grace period so a held key doesn't skip the ticket instantly.
	get_tree().create_timer(0.6).timeout.connect(func() -> void: _can_restart = true)


func _show_message(text: String) -> void:
	_message.text = text
	_message.visible = true


## Place a Kenney GLB, uniformly scaled so its largest horizontal extent equals `size` meters.
func model(path: String, pos: Vector3, rot_y := 0.0, size := 0.0, collide := false) -> Node3D:
	var inst: Node3D = load(path).instantiate()
	var holder := Node3D.new()
	holder.add_child(inst)
	if size > 0.0:
		var aabb := _aabb(inst)
		var extent := maxf(aabb.size.x, aabb.size.z)
		if extent > 0.0:
			holder.scale = Vector3.ONE * (size / extent)
	if collide:
		var body := StaticBody3D.new()
		var shape := CollisionShape3D.new()
		var box_shape := BoxShape3D.new()
		var aabb := _aabb(inst)
		box_shape.size = aabb.size
		shape.shape = box_shape
		shape.position = aabb.get_center()
		body.add_child(shape)
		holder.add_child(body)
	holder.position = pos
	holder.rotation.y = rot_y
	add_child(holder)
	return holder


func _aabb(node: Node) -> AABB:
	var result := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		var xf := _relative_transform(mi, node)
		var box := xf * mi.get_aabb()
		result = box if first else result.merge(box)
		first = false
	return result


func _relative_transform(node: Node3D, root: Node) -> Transform3D:
	var xf := node.transform
	var p := node.get_parent()
	while p != null and p != root:
		if p is Node3D:
			xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.45, 0.65, 0.9)
	sky_mat.sky_horizon_color = Color(0.85, 0.88, 0.9)
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.fog_enabled = true
	env.fog_light_color = Color(0.85, 0.88, 0.9)
	env.fog_density = 0.004
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -30, 0)
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)

	# Ground plane with collision; top surface at y=0.
	RoadKit.box(self, Vector3(600, 1, 600), Vector3(0, -0.5, 0), RoadKit.GRASS, true)


func _setup_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	_speed_label = Label.new()
	_speed_label.position = Vector2(24, 650)
	_speed_label.add_theme_font_size_override("font_size", 32)
	_speed_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_speed_label.add_theme_constant_override("outline_size", 6)
	layer.add_child(_speed_label)
	_fine_label = _speed_label.duplicate()
	_fine_label.position = Vector2(900, 20)
	_fine_label.add_theme_font_size_override("font_size", 26)
	layer.add_child(_fine_label)
	_message = _speed_label.duplicate()
	_message.set_anchors_preset(Control.PRESET_CENTER)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.position = Vector2(340, 300)
	_message.size = Vector2(600, 120)
	_message.add_theme_font_size_override("font_size", 40)
	_message.visible = false
	layer.add_child(_message)
