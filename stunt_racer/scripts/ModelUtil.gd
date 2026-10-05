extends RefCounted
## Helpers for using real .glb models (Kenney CC0 kits) inside the game.
## Everything is auto-scaled / auto-oriented from the model's own bounding
## box, so it works even though the kits ship at their own scale.

static func instance_model(path: String) -> Node3D:
	var ps: PackedScene = load(path)
	if ps == null:
		push_warning("model not found: " + path)
		return null
	var n := ps.instantiate()
	return n as Node3D

## Local AABB of a whole node tree, relative to `root`'s own transform.
static func model_aabb(root: Node3D) -> AABB:
	var acc := {"has": false, "box": AABB()}
	_walk(root, Transform3D.IDENTITY, acc)
	return acc["box"]

static func _walk(n: Node, xf: Transform3D, acc: Dictionary) -> void:
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D:
		var b: AABB = t * (n as MeshInstance3D).get_aabb()
		if acc["has"]:
			acc["box"] = (acc["box"] as AABB).merge(b)
		else:
			acc["box"] = b
			acc["has"] = true
	for c in n.get_children():
		_walk(c, t, acc)

static func find_node(root: Node, needle: String) -> Node3D:
	for c in root.get_children():
		if c is Node3D and needle.to_lower() in String(c.name).to_lower():
			return c as Node3D
		var deeper := find_node(c, needle)
		if deeper != null:
			return deeper
	return null

static func find_all(root: Node, needle: String, out: Array) -> Array:
	for c in root.get_children():
		if c is Node3D and needle.to_lower() in String(c.name).to_lower():
			out.append(c)
		find_all(c, needle, out)
	return out

## Wrap a model so it: (1) has its long axis along Z, (2) for cars, faces -Z,
## (3) is scaled to `target_long`, (4) is centred in X/Z and grounded at Y=0.
static func make_model(path: String, target_long: float, is_car: bool) -> Node3D:
	var wrapper := Node3D.new()
	var m := instance_model(path)
	if m == null:
		return wrapper
	wrapper.add_child(m)

	# 1. long axis to Z
	var b := model_aabb(m)
	if b.size.x > b.size.z:
		m.rotate_y(PI * 0.5)
		b = model_aabb(m)

	# 2. cars: make the front wheels sit at -Z (our forward)
	if is_car:
		var front := find_node(m, "front")
		if front != null and front.position.z > 0.0:
			m.rotate_y(PI)

	# 3. scale to the target longest dimension
	b = model_aabb(m)
	var longest := maxf(b.size.x, maxf(b.size.y, b.size.z))
	if longest > 0.0001:
		var s := target_long / longest
		m.scale = m.scale * s

	# 4. centre in X/Z, ground at Y=0
	b = model_aabb(m)
	m.position -= Vector3(b.position.x + b.size.x * 0.5, b.position.y, b.position.z + b.size.z * 0.5)
	return wrapper

## A scenery prop: scaled so its HEIGHT matches `target_height`, centred, grounded.
static func make_prop(path: String, target_height: float) -> Node3D:
	var wrapper := Node3D.new()
	var m := instance_model(path)
	if m == null:
		return wrapper
	wrapper.add_child(m)
	var b := model_aabb(m)
	if b.size.y > 0.0001:
		m.scale = m.scale * (target_height / b.size.y)
	b = model_aabb(m)
	m.position -= Vector3(b.position.x + b.size.x * 0.5, b.position.y, b.position.z + b.size.z * 0.5)
	return wrapper
