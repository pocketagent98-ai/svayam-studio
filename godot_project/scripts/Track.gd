extends Node3D
## Builds a race track procedurally. Three layouts are defined here; the
## selected one is built from a closed Catmull-Rom loop. Real 3D scenery
## (Kenney CC0 racing kit) is placed along the road.

const ModelUtil := preload("res://scripts/ModelUtil.gd")
const MODELS := "res://models/kenney/"

const TRACKS := [
	{
		"name": "Coastal Loop",
		"ctrl": [
			Vector3(0, 0, 0), Vector3(70, 0, 8), Vector3(120, 0, 70),
			Vector3(95, 0, 145), Vector3(30, 0, 165), Vector3(-45, 0, 150),
			Vector3(-100, 0, 95), Vector3(-110, 0, 20), Vector3(-65, 0, -40),
		],
	},
	{
		"name": "City Circuit",
		"ctrl": [
			Vector3(-120, 0, -120), Vector3(120, 0, -120), Vector3(150, 0, -40),
			Vector3(120, 0, 40), Vector3(150, 0, 120), Vector3(60, 0, 160),
			Vector3(-40, 0, 150), Vector3(-150, 0, 120), Vector3(-170, 0, 0),
			Vector3(-150, 0, -80),
		],
	},
	{
		"name": "Mountain Pass",
		"ctrl": [
			Vector3(0, 0, -150), Vector3(95, 0, -105), Vector3(140, 0, -10),
			Vector3(95, 0, 95), Vector3(0, 0, 140), Vector3(-95, 0, 95),
			Vector3(-140, 0, 0), Vector3(-95, 0, -95),
		],
	},
]

var track_index := 0
var centerline := PackedVector3Array()
var road_half_width := 7.0
var track_name := ""

func build() -> void:
	var def: Dictionary = TRACKS[track_index]
	track_name = def["name"]
	centerline = _sample_loop(def["ctrl"], 12)
	_build_ground()
	_build_road()
	_build_walls()
	_build_start_line()
	_place_scenery()

# ------------------------------------------------------------- geometry maths
func _sample_loop(ctrl: Array, steps: int) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var n := ctrl.size()
	for i in range(n):
		var p0: Vector3 = ctrl[(i - 1 + n) % n]
		var p1: Vector3 = ctrl[i]
		var p2: Vector3 = ctrl[(i + 1) % n]
		var p3: Vector3 = ctrl[(i + 2) % n]
		for s in range(steps):
			var t := float(s) / float(steps)
			pts.append(_catmull(p0, p1, p2, p3, t))
	return pts

func _catmull(p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, t: float) -> Vector3:
	var t2 := t * t
	var t3 := t2 * t
	return 0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3)

func _tangent(i: int) -> Vector3:
	var n := centerline.size()
	var t := centerline[(i + 1) % n] - centerline[(i - 1 + n) % n]
	t.y = 0.0
	return t.normalized()

# ------------------------------------------------------------- ground
func _build_ground() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.42, 0.20)
	mat.roughness = 1.0
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(1200, 1200)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = Vector3(0, -0.02, 0)
	add_child(mi)

	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1200, 1.0, 1200)
	cs.shape = box
	cs.position = Vector3(0, -0.5, 0)
	body.add_child(cs)
	add_child(body)

# ------------------------------------------------------------- road
func _build_road() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var n := centerline.size()
	for i in range(n):
		var p := centerline[i]
		var pn := centerline[(i + 1) % n]
		var right := _tangent(i).cross(Vector3.UP).normalized()
		var a := p - right * road_half_width
		var b := p + right * road_half_width
		var rightn := _tangent((i + 1) % n).cross(Vector3.UP).normalized()
		var c := pn - rightn * road_half_width
		var d := pn + rightn * road_half_width
		a.y = 0.02; b.y = 0.02; c.y = 0.02; d.y = 0.02
		st.add_vertex(a); st.add_vertex(c); st.add_vertex(b)
		st.add_vertex(b); st.add_vertex(c); st.add_vertex(d)
	st.generate_normals()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.13, 0.13, 0.15)
	mat.roughness = 0.9
	st.set_material(mat)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	add_child(mi)

# ------------------------------------------------------------- walls
func _build_walls() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.20, 0.20)
	var n := centerline.size()
	for side in [-1.0, 1.0]:
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var faces := PackedVector3Array()
		for i in range(n):
			var j := (i + 1) % n
			var ri := _tangent(i).cross(Vector3.UP).normalized()
			var rj := _tangent(j).cross(Vector3.UP).normalized()
			var a: Vector3 = centerline[i] + ri * side * (road_half_width + 0.4)
			var b: Vector3 = centerline[j] + rj * side * (road_half_width + 0.4)
			a.y = 0.0
			b.y = 0.0
			var a2: Vector3 = a + Vector3(0, 1.5, 0)
			var b2: Vector3 = b + Vector3(0, 1.5, 0)
			for tri in [[a, b, b2], [a, b2, a2]]:
				for v in tri:
					st.add_vertex(v)
					faces.append(v)
		st.generate_normals()
		st.set_material(mat)
		var mi := MeshInstance3D.new()
		mi.mesh = st.commit()
		add_child(mi)

		var body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		cs.shape = shape
		body.add_child(cs)
		add_child(body)

# ------------------------------------------------------------- scenery
func _place(path: String, height: float, pos: Vector3, face_point: Vector3) -> void:
	var prop := ModelUtil.make_prop(MODELS + path, height)
	add_child(prop)
	pos.y = 0.0
	prop.global_position = pos
	if prop.global_position.distance_to(face_point) > 0.5:
		prop.look_at(face_point, Vector3.UP)

func _place_scenery() -> void:
	var n := centerline.size()
	var i := 0
	while i < n:
		var p := centerline[i]
		var t := _tangent(i)
		var right := t.cross(Vector3.UP).normalized()
		var side := 1.0 if (i / 10) % 2 == 0 else -1.0
		_place("lightPostModern.glb", 8.0, p + right * side * (road_half_width + 3.5), p)
		i += 10

	i = 0
	while i < n:
		var p := centerline[i]
		var t := _tangent(i)
		var right := t.cross(Vector3.UP).normalized()
		var side := -1.0 if (i / 6) % 2 == 0 else 1.0
		var off := 14.0 + float(i % 5) * 3.0
		var tree := "treeLarge.glb" if i % 2 == 0 else "treeSmall.glb"
		_place(tree, 6.5 + float(i % 3), p + right * side * off, p)
		i += 6

	i = 0
	while i < n:
		var p := centerline[i]
		var t := _tangent(i)
		var right := t.cross(Vector3.UP).normalized()
		_place("grandStand.glb", 7.0, p + right * (road_half_width + 12.0), p)
		i += 40

	i = 0
	while i < n:
		var p := centerline[i]
		var t := _tangent(i)
		var right := t.cross(Vector3.UP).normalized()
		_place("overhead.glb", 8.5, p + right * 0.0, p + t)
		i += 45

	i = 0
	while i < n:
		var p := centerline[i]
		var t := _tangent(i)
		var right := t.cross(Vector3.UP).normalized()
		var side := 1.0 if (i / 25) % 2 == 0 else -1.0
		_place("billboard.glb", 6.0, p + right * side * (road_half_width + 16.0), p)
		i += 25

	i = 0
	while i < n:
		var p := centerline[i]
		var t := _tangent(i)
		var right := t.cross(Vector3.UP).normalized()
		var side := -1.0 if (i / 22) % 2 == 0 else 1.0
		_place("tent.glb", 3.5, p + right * side * (road_half_width + 8.0), p)
		i += 22

	i = 0
	while i < n:
		var p := centerline[i]
		var t := _tangent(i)
		var right := t.cross(Vector3.UP).normalized()
		var side := 1.0 if (i / 8) % 2 == 0 else -1.0
		_place("pylon.glb", 1.4, p + right * side * (road_half_width + 1.6), p)
		i += 8

	var p0 := centerline[0]
	var t0 := _tangent(0)
	var r0 := t0.cross(Vector3.UP).normalized()
	_place("flagCheckers.glb", 6.0, p0 + r0 * (road_half_width + 6.0), p0)
	_place("bannerTowerRed.glb", 11.0, p0 - r0 * (road_half_width + 6.0), p0)

	# start gantry over the line
	_place("overhead.glb", 9.0, p0, p0 + t0)

	# pit lane: a row of garages just after the start
	var k := 0
	while k < 8:
		var idx := (2 + k * 2) % n
		var p := centerline[idx]
		var t := _tangent(idx)
		var right := t.cross(Vector3.UP).normalized()
		_place("pitsGarage.glb", 5.0, p + right * (road_half_width + 7.5), p)
		k += 1

	_place("grandStandCovered.glb", 8.5, centerline[4] + _tangent(4).cross(Vector3.UP).normalized() * (road_half_width + 11.0), centerline[4])
	_place("bannerTowerGreen.glb", 11.0, centerline[6] - _tangent(6).cross(Vector3.UP).normalized() * (road_half_width + 6.0), centerline[6])
	_place("tentLong.glb", 3.5, centerline[8] + _tangent(8).cross(Vector3.UP).normalized() * (road_half_width + 9.0), centerline[8])

# ------------------------------------------------------------- start line
func _build_start_line() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.95, 0.95)
	var p := centerline[0]
	var t := _tangent(0)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(road_half_width * 2.0, 0.04, 1.2)
	mi.mesh = bm
	mi.material_override = mat
	var tr := Transform3D(Basis(), Vector3(p.x, 0.05, p.z))
	tr = tr.looking_at(Vector3(p.x, 0.05, p.z) + t, Vector3.UP)
	mi.transform = tr
	add_child(mi)
