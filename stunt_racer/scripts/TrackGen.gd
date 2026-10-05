extends Node3D
## Endless procedural track. A centreline that keeps growing ahead of the car
## (Catmull-Rom-smoothed in the sampling sense), extruded into a road mesh with
## barrier walls. Geometry behind the car is dropped so memory stays flat.

const ModelUtil := preload("res://scripts/ModelUtil.gd")
const MODELS := "res://models/kenney/"

const STEP := 6.0
const HALF_W := 7.0
const AHEAD := 70
const BEHIND := 14
const ROAD_Y := 0.02
const WALL_H := 1.4

var points := PackedVector3Array()
var heading := 0.0
var curve := 0.0
var rng := RandomNumberGenerator.new()
var car_index := 0

var road_mi: MeshInstance3D
var wall_l: MeshInstance3D
var wall_r: MeshInstance3D
var ground: Node3D
var prop_root: Node3D
var last_built := -1
var prop_cursor := 0

func build(seed_val: int) -> void:
	rng.seed = seed_val
	points.clear()
	heading = 0.0
	curve = 0.0
	car_index = 0
	last_built = -1
	prop_cursor = 0
	for i in range(40):
		_extend(false)
	_build_ground()
	road_mi = _new_mesh()
	wall_l = _new_mesh()
	wall_r = _new_mesh()
	prop_root = Node3D.new()
	add_child(prop_root)
	_rebuild_mesh()
	_place_props_up_to(points.size())

# ------------------------------------------------------------- generation
func _extend(with_props: bool = true) -> void:
	var dir := Vector3(-sin(heading), 0.0, -cos(heading))
	if points.is_empty():
		points.append(Vector3.ZERO)
	else:
		points.append(points[points.size() - 1] + dir * STEP)
	heading += curve
	if rng.randf() < 0.10:
		curve = rng.randf_range(-0.075, 0.075)
	curve = clampf(curve, -0.09, 0.09)
	if with_props:
		_place_props_up_to(points.size())

func update(car_pos: Vector3) -> void:
	var n := points.size()
	while car_index < n - 1 and car_pos.distance_to(points[car_index + 1]) < car_pos.distance_to(points[car_index]):
		car_index += 1
	while points.size() < car_index + AHEAD:
		_extend()
	if points.size() - last_built > 8:
		_rebuild_mesh()
	if ground != null:
		ground.position.x = snappedf(car_pos.x, 50.0)
		ground.position.z = snappedf(car_pos.z, 50.0)

# ------------------------------------------------------------- helpers
func _tangent(i: int) -> Vector3:
	var n := points.size()
	var a := points[maxi(i - 1, 0)]
	var b := points[mini(i + 1, n - 1)]
	var t := b - a
	t.y = 0.0
	if t.length() < 0.001:
		return Vector3(0, 0, -1)
	return t.normalized()

func _right(i: int) -> Vector3:
	return _tangent(i).cross(Vector3.UP).normalized()

func lateral_offset(car_pos: Vector3) -> float:
	if points.size() < 2:
		return 0.0
	var i := clampi(car_index, 0, points.size() - 2)
	var a := points[i]
	var b := points[i + 1]
	var ab := b - a
	var t := clampf((car_pos - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
	return car_pos.distance_to(a + ab * t)

func point_ahead(idx: int) -> Vector3:
	return points[clampi(idx, 0, points.size() - 1)]

# ------------------------------------------------------------- meshes
func _new_mesh() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	add_child(mi)
	return mi

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	return m

func _build_ground() -> void:
	ground = Node3D.new()
	var mi := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	mi.mesh = pm
	mi.material_override = _mat(Color(0.16, 0.38, 0.20))
	ground.add_child(mi)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(400, 1.0, 400)
	cs.shape = box
	cs.position = Vector3(0, -0.5, 0)
	body.add_child(cs)
	ground.add_child(body)
	add_child(ground)

func _rebuild_mesh() -> void:
	var start := maxi(0, car_index - BEHIND)
	var n := points.size()
	if n - start < 2:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(start, n - 1):
		var ri := _right(i)
		var rj := _right(i + 1)
		var a := points[i] - ri * HALF_W; a.y = ROAD_Y
		var b := points[i] + ri * HALF_W; b.y = ROAD_Y
		var c := points[i + 1] - rj * HALF_W; c.y = ROAD_Y
		var d := points[i + 1] + rj * HALF_W; d.y = ROAD_Y
		st.add_vertex(a); st.add_vertex(c); st.add_vertex(b)
		st.add_vertex(b); st.add_vertex(c); st.add_vertex(d)
	st.generate_normals()
	st.set_material(_mat(Color(0.13, 0.13, 0.15)))
	road_mi.mesh = st.commit()

	_wall_mesh(wall_l, start, n, -1.0)
	_wall_mesh(wall_r, start, n, 1.0)
	last_built = n

func _wall_mesh(mi: MeshInstance3D, start: int, n: int, side: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(start, n - 1):
		var ri := _right(i)
		var rj := _right(i + 1)
		var a := points[i] + ri * side * (HALF_W + 0.4); a.y = 0.0
		var b := points[i + 1] + rj * side * (HALF_W + 0.4); b.y = 0.0
		var a2 := a + Vector3(0, WALL_H, 0)
		var b2 := b + Vector3(0, WALL_H, 0)
		st.add_vertex(a); st.add_vertex(b); st.add_vertex(b2)
		st.add_vertex(a); st.add_vertex(b2); st.add_vertex(a2)
	st.generate_normals()
	st.set_material(_mat(Color(0.85, 0.20, 0.20)))
	mi.mesh = st.commit()

# ------------------------------------------------------------- scenery
func _place_props_up_to(n: int) -> void:
	while prop_cursor < n:
		var i := prop_cursor
		if i > 6 and i % 6 == 0:
			var r := _right(i)
			var side := -1.0 if (i / 6) % 2 == 0 else 1.0
			_add_prop("lightPostModern.glb", 8.0, points[i] + r * side * (HALF_W + 3.0))
		if i > 10 and i % 9 == 0:
			var r2 := _right(i)
			var side2 := 1.0 if (i / 9) % 2 == 0 else -1.0
			var off := 14.0 + float(i % 4) * 4.0
			var tree := "treeLarge.glb" if i % 2 == 0 else "treeSmall.glb"
			_add_prop(tree, 6.5, points[i] + r2 * side2 * off)
		if i > 20 and i % 40 == 0:
			_add_prop("grandStand.glb", 7.0, points[i] + _right(i) * (HALF_W + 12.0))
		prop_cursor += 1

func _add_prop(path: String, height: float, pos: Vector3) -> void:
	var prop := ModelUtil.make_prop(MODELS + path, height)
	prop_root.add_child(prop)
	prop.global_position = Vector3(pos.x, 0.0, pos.z)
