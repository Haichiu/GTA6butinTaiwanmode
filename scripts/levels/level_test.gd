extends LevelBase
## M0 test intersection: a 3+3 lane north-south arterial crossing a 2+2 lane street.
## Northbound lanes (x > 0): lane 1 inner [0, 3.5], lane 2 [3.5, 7], lane 3 outer [7, 10.5].

const NS_HALF := 10.5  # 3 lanes * 3.5
const EW_HALF := 7.0  # 2 lanes * 3.5
const WALK := 4.0  # sidewalk width
const REACH := 160.0  # how far roads extend from the center
const CROSSWALK := 3.0
const K = preload("res://scripts/road_kit.gd")


func spawn_transform() -> Transform3D:
	# Outer northbound lane, well south of the intersection, heading north.
	return Transform3D(Basis.IDENTITY, Vector3(8.75, 0.1, 90.0))


func build() -> void:
	# Asphalt.
	K.surface(self, Vector2(-NS_HALF, -REACH), Vector2(NS_HALF, REACH))
	K.surface(self, Vector2(-REACH, -EW_HALF), Vector2(REACH, EW_HALF))
	# Sidewalks on the four blocks' road-facing edges.
	var outer := NS_HALF + WALK
	var outer_ew := EW_HALF + WALK
	for sx in [-1, 1]:
		K.surface(self, Vector2(minf(sx * NS_HALF, sx * outer), -REACH), Vector2(maxf(sx * NS_HALF, sx * outer), -outer_ew), K.SIDEWALK, 0.03)
		K.surface(self, Vector2(minf(sx * NS_HALF, sx * outer), outer_ew), Vector2(maxf(sx * NS_HALF, sx * outer), REACH), K.SIDEWALK, 0.03)
	for sz in [-1, 1]:
		K.surface(self, Vector2(-REACH, minf(sz * EW_HALF, sz * outer_ew)), Vector2(-NS_HALF, maxf(sz * EW_HALF, sz * outer_ew)), K.SIDEWALK, 0.03)
		K.surface(self, Vector2(NS_HALF, minf(sz * EW_HALF, sz * outer_ew)), Vector2(REACH, maxf(sz * EW_HALF, sz * outer_ew)), K.SIDEWALK, 0.03)

	_paint_arterial()
	_paint_street()
	_paint_intersection()
	_place_props()
	_add_rules()


func _add_rules() -> void:
	var stop := EW_HALF + CROSSWALK + 1.5
	# Inner two northbound lanes are 禁行機車 on the approach.
	ViolationZone.make(self, Vector2(0.3, stop), Vector2(7.0, REACH), "lane_ban", "sidewalk",
		"騎在沒車的車道，跟騎上人行道嚇行人，罰一樣多。", Vector3.FORWARD)
	# Sidewalks along the arterial.
	var outer := NS_HALF + WALK
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			var z_near := EW_HALF + WALK
			ViolationZone.make(self, Vector2(minf(sx * NS_HALF, sx * outer), minf(sz * z_near, sz * REACH)),
				Vector2(maxf(sx * NS_HALF, sx * outer), maxf(sz * z_near, sz * REACH)), "sidewalk", "lane_ban",
				"騎上人行道，跟騎進空的禁行機車車道，罰一樣多。")
	goal(Vector2(7.0, -70.0), Vector2(NS_HALF, -60.0))


func _paint_arterial() -> void:
	var stop := EW_HALF + CROSSWALK + 1.5  # stop line distance from center
	for sz in [-1, 1]:
		var z0: float = sz * stop
		var z1: float = sz * REACH
		# Double yellow median.
		K.line(self, Vector2(-0.2, z0), Vector2(-0.2, z1), K.YELLOW)
		K.line(self, Vector2(0.2, z0), Vector2(0.2, z1), K.YELLOW)
		# Lane dividers and edge lines, both directions.
		for sx in [-1, 1]:
			K.line(self, Vector2(sx * 3.5, z0), Vector2(sx * 3.5, z1), K.WHITE, K.LINE_W, 4.0)
			K.line(self, Vector2(sx * 7.0, z0), Vector2(sx * 7.0, z1), K.WHITE, K.LINE_W, 4.0)
			K.line(self, Vector2(sx * (NS_HALF - 0.3), z0), Vector2(sx * (NS_HALF - 0.3), z1), K.WHITE)
	# Northbound approach (south side, z > 0): stop line, 禁行機車 in lanes 1-2, 機車停等區 in lane 3.
	K.line(self, Vector2(0.2, stop), Vector2(NS_HALF, stop), K.WHITE, 0.4)
	for lane_center in [1.75, 5.25]:
		for z in [stop + 25.0, stop + 60.0]:
			K.ground_text(self, "禁\n行\n機\n車", Vector2(lane_center, z), K.YELLOW)
	K.outline(self, Vector2(7.2, stop + 0.2), Vector2(NS_HALF - 0.3, stop + 4.5))
	K.ground_text(self, "機\n車", Vector2(8.75, stop + 2.4), K.WHITE, 0.0, 0.006)
	# Southbound approach mirrors it (north side, z < 0).
	K.line(self, Vector2(-NS_HALF, -stop), Vector2(-0.2, -stop), K.WHITE, 0.4)


func _paint_street() -> void:
	var stop := NS_HALF + CROSSWALK + 1.5
	for sx in [-1, 1]:
		var x0: float = sx * stop
		var x1: float = sx * REACH
		K.line(self, Vector2(x0, -0.2), Vector2(x1, -0.2), K.YELLOW)
		K.line(self, Vector2(x0, 0.2), Vector2(x1, 0.2), K.YELLOW)
		for sz in [-1, 1]:
			K.line(self, Vector2(x0, sz * 3.5), Vector2(x1, sz * 3.5), K.WHITE, K.LINE_W, 4.0)
			K.line(self, Vector2(x0, sz * (EW_HALF - 0.3)), Vector2(x1, sz * (EW_HALF - 0.3)), K.WHITE)
	K.line(self, Vector2(-stop, 0.2), Vector2(-stop, EW_HALF), K.WHITE, 0.4)  # eastbound
	K.line(self, Vector2(stop, -EW_HALF), Vector2(stop, -0.2), K.WHITE, 0.4)  # westbound


func _paint_intersection() -> void:
	# Crosswalks on all four sides.
	K.zebra(self, Vector2(-NS_HALF, EW_HALF + 0.5), Vector2(NS_HALF, EW_HALF + 0.5 + CROSSWALK), "x")
	K.zebra(self, Vector2(-NS_HALF, -EW_HALF - 0.5 - CROSSWALK), Vector2(NS_HALF, -EW_HALF - 0.5), "x")
	K.zebra(self, Vector2(NS_HALF + 0.5, -EW_HALF), Vector2(NS_HALF + 0.5 + CROSSWALK, EW_HALF), "z")
	K.zebra(self, Vector2(-NS_HALF - 0.5 - CROSSWALK, -EW_HALF), Vector2(-NS_HALF - 0.5, EW_HALF), "z")
	# 機車待轉區 for northbound scooters turning left (west): far-right corner, facing west.
	var box_min := Vector2(NS_HALF - 3.2, -EW_HALF + 0.3)
	var box_max := Vector2(NS_HALF - 0.3, -EW_HALF + 3.2)
	K.outline(self, box_min, box_max)
	K.ground_text(self, "機車\n待轉", (box_min + box_max) / 2.0, K.WHITE, PI / 2.0, 0.005)


func _place_props() -> void:
	var roads := "res://assets/kenney/roads/Models/GLB format/"
	var cars := "res://assets/kenney/cars/Models/GLB format/"
	var city := "res://assets/kenney/commercial/Models/GLB format/"
	# Traffic lights at the four corners.
	var corner := Vector2(NS_HALF + 1.0, EW_HALF + 1.0)
	model(roads + "traffic-light.glb", Vector3(corner.x, 0, corner.y), 0.0, 1.5)
	model(roads + "traffic-light.glb", Vector3(-corner.x, 0, -corner.y), PI, 1.5)
	model(roads + "traffic-light.glb", Vector3(corner.x, 0, -corner.y), PI / 2.0, 1.5)
	model(roads + "traffic-light.glb", Vector3(-corner.x, 0, corner.y), -PI / 2.0, 1.5)
	# Parked delivery truck blocking the outer lane: the classic reason to swerve inward.
	model(cars + "delivery.glb", Vector3(8.9, 0, 45.0), 0.0, 6.0, true)
	model(cars + "sedan.glb", Vector3(8.9, 0, 60.0), 0.0, 4.5, true)
	# Buildings lining the blocks.
	var names := ["building-a", "building-b", "building-c", "building-d", "building-e", "building-f", "building-g", "building-h"]
	var i := 0
	for sz in [-1, 1]:
		for sx in [-1, 1]:
			var z := EW_HALF + WALK + 9.0
			while z < REACH - 10.0:
				var x: float = sx * (NS_HALF + WALK + 8.0)
				var facing := -PI / 2.0 if sx > 0 else PI / 2.0
				model(city + names[i % names.size()] + ".glb", Vector3(x, 0, sz * z), facing, 14.0, true)
				i += 1
				z += 16.0
