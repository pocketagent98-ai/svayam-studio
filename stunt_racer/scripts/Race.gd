extends Node3D
## Runs one endless run: builds the track, the car, obstacles, coins and the
## HUD; detects a crash and reports the result.

signal race_finished(result: Dictionary)

const TrackGenScript := preload("res://scripts/TrackGen.gd")
const CarScript := preload("res://scripts/Car.gd")
const HudScript := preload("res://scripts/HUD.gd")
const CamScript := preload("res://scripts/ChaseCamera.gd")

const HALF_W := 7.0
const SPAWN_AHEAD := 60

var car_model := "res://models/kenney/raceCarRed.glb"
var car_color := Color(0.86, 0.12, 0.12)

var track: Node3D
var car: RigidBody3D
var hud: CanvasLayer
var obstacles_root: Node3D
var spawned: Array = []
var spawned_upto := 0
var coins_collected := 0
var running := true

func _ready() -> void:
	_setup_env()
	track = TrackGenScript.new()
	add_child(track)
	track.build(randi())
	car = CarScript.new()
	car.model_path = car_model
	car.color = car_color
	add_child(car)
	car.waypoints = track.points
	car.global_position = track.points[8] + Vector3(0, 1.2, 0)
	car.look_at(track.points[14], Vector3.UP)
	if "--autoplay" in OS.get_cmdline_user_args():
		car.is_ai = true
	var cam := CamScript.new()
	cam.target = car
	add_child(cam)
	cam.global_position = car.global_position + Vector3(0, 4.5, 9.0)
	hud = HudScript.new()
	add_child(hud)
	obstacles_root = Node3D.new()
	add_child(obstacles_root)

func _setup_env() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	sky.sky_material = ProceduralSkyMaterial.new()
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.6
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_energy = 1.1
	add_child(sun)

func _process(_delta: float) -> void:
	if not running:
		return
	track.update(car.global_position)
	_spawn_ahead()
	_check_crash()
	hud.update(car.speed_kmh(), car.distance, car.nitro, car.boosting, coins_collected, Global.best_distance())

func _spawn_ahead() -> void:
	var limit: int = track.car_index + SPAWN_AHEAD
	while spawned_upto < limit and spawned_upto < track.points.size() - 2:
		spawned_upto += 1
		var p: Vector3 = track.point_ahead(spawned_upto)
		var r: Vector3 = track._right(spawned_upto)
		if spawned_upto % 5 == 0:
			_add_coin(p + r * randf_range(-3.5, 3.5))
		if spawned_upto % 14 == 0:
			_add_hazard(p + r * randf_range(-3.0, 3.0), spawned_upto)
		if spawned_upto % 9 == 0:
			_add_block(p + r * randf_range(-4.0, 4.0), spawned_upto)
	_free_behind()

func _add_coin(pos: Vector3) -> void:
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var sp := SphereShape3D.new()
	sp.radius = 1.1
	cs.shape = sp
	area.add_child(cs)
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5
	cyl.bottom_radius = 0.5
	cyl.height = 0.12
	mi.mesh = cyl
	mi.rotation_degrees = Vector3(90, 0, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.82, 0.1)
	mat.metallic = 0.9
	mi.material_override = mat
	area.add_child(mi)
	obstacles_root.add_child(area)
	area.global_position = pos + Vector3(0, 1.0, 0)
	area.body_entered.connect(func(b):
		if b == car and is_instance_valid(area):
			coins_collected += 1
			area.queue_free())
	spawned.append({"node": area, "idx": spawned_upto})

func _add_hazard(pos: Vector3, idx: int) -> void:
	var area := Area3D.new()
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.2, 2.2, 1.2)
	cs.shape = box
	area.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(3.2, 2.2, 1.2)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.15, 0.15)
	mi.material_override = mat
	area.add_child(mi)
	obstacles_root.add_child(area)
	area.global_position = pos + Vector3(0, 1.1, 0)
	area.body_entered.connect(func(b):
		if b == car:
			_crash())
	spawned.append({"node": area, "idx": idx})

func _add_block(pos: Vector3, idx: int) -> void:
	var body := RigidBody3D.new()
	body.mass = 60.0
	var cs := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 1.6, 1.6)
	cs.shape = box
	body.add_child(cs)
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(2.4, 1.6, 1.6)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.85, 0.55, 0.15)
	mi.material_override = mat
	body.add_child(mi)
	obstacles_root.add_child(body)
	body.global_position = pos + Vector3(0, 0.9, 0)
	spawned.append({"node": body, "idx": idx})

func _free_behind() -> void:
	var keep := []
	for d in spawned:
		if int(d["idx"]) < track.car_index - 6:
			if is_instance_valid(d["node"]):
				d["node"].queue_free()
		else:
			keep.append(d)
	spawned = keep

func _check_crash() -> void:
	if track.lateral_offset(car.global_position) > HALF_W + 1.5:
		_crash()
	elif car.global_position.y < -10.0:
		_crash()

func _crash() -> void:
	if not running:
		return
	running = false
	car.crashed = true
	Global.report_run(car.distance, coins_collected)
	race_finished.emit({
		"distance": car.distance,
		"coins": coins_collected,
		"best": Global.best_distance(),
	})

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart") or event.is_action_pressed("back"):
		if running:
			running = false
			race_finished.emit({"distance": car.distance, "coins": coins_collected, "best": Global.best_distance()})
