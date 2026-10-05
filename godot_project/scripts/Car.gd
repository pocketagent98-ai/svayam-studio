extends CharacterBody3D
## Arcade race car (player + AI) with per-car stats, a nitro boost, and a
## real 3D model (Kenney CC0 kit). Falls back to a simple box if the model
## cannot be loaded.

const ModelUtil := preload("res://scripts/ModelUtil.gd")

const BASE_SPEED := 52.0
const BASE_ACCEL := 20.0
const BASE_TURN := 2.2
const BRAKE := 34.0
const FRICTION := 10.0
const STEER_SIGN := -1.0
const GRAVITY := 26.0
const BOOST_MULT := 1.45
const NITRO_DRAIN := 0.5
const NITRO_REGEN := 0.12
const CAR_LENGTH := 4.4

var is_ai := false
var is_player := false
var color := Color(0.12, 0.40, 0.95)
var stats := {"top": 1.0, "accel": 1.0, "grip": 1.0, "boost": 1.0}
var model_path := "res://models/kenney/raceCarRed.glb"

var waypoints := PackedVector3Array()
var wp := 0
var lap := 0
var finished := false
var place := 1
var total_laps := 3

var speed := 0.0
var steer_target := 0.0
var can_drive := false
var race_clock := 0.0
var lap_start := 0.0
var lap_times: Array = []
var nitro := 1.0
var boosting := false
var wheel_nodes: Array = []

func _ready() -> void:
	_build_body()

func max_speed() -> float:
	return BASE_SPEED * stats["top"]
func accel() -> float:
	return BASE_ACCEL * stats["accel"]
func turn_rate() -> float:
	return BASE_TURN * stats["grip"]

func _build_body() -> void:
	# --- collision (physics) ---
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.0, 0.9, CAR_LENGTH)
	cs.shape = bs
	cs.position = Vector3(0, 0.5, 0)
	add_child(cs)

	# --- visual: real 3D model ---
	var model := ModelUtil.make_model(model_path, CAR_LENGTH, true)
	var has_mesh := false
	for c in model.get_children():
		if c is Node3D:
			has_mesh = true
	if has_mesh:
		add_child(model)
		wheel_nodes = ModelUtil.find_all(model, "wheel", [])
	else:
		_build_fallback_box()

func _build_fallback_box() -> void:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = color
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.9, 0.6, CAR_LENGTH)
	body.mesh = bm
	body.material_override = paint
	body.position = Vector3(0, 0.6, 0)
	add_child(body)

# ------------------------------------------------------------- driving
func _physics_process(delta: float) -> void:
	if finished:
		speed = move_toward(speed, 0.0, BRAKE * delta)
	elif not can_drive:
		speed = 0.0
		steer_target = 0.0
	elif is_ai:
		_ai_drive(delta)
	else:
		_player_drive(delta)

	if not boosting:
		nitro = clampf(nitro + NITRO_REGEN * delta, 0.0, 1.0)

	var mult := BOOST_MULT if boosting else 1.0
	var turn := steer_target * STEER_SIGN * turn_rate() * delta * clampf(absf(speed) / 8.0, 0.0, 1.0)
	if speed < 0.0:
		turn = -turn
	rotate_y(turn)

	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	velocity.x = fwd.x * speed * mult
	velocity.z = fwd.z * speed * mult
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= GRAVITY * delta
	move_and_slide()

	var spin := speed * delta / 0.35
	for w in wheel_nodes:
		if is_instance_valid(w):
			w.rotate_x(spin)

	_track_progress()

func _player_drive(delta: float) -> void:
	var acc := Input.get_action_strength("accelerate")
	var br := Input.get_action_strength("brake")
	steer_target = Input.get_axis("steer_left", "steer_right")
	boosting = Input.is_action_pressed("nitro") and nitro > 0.02
	if boosting:
		nitro = maxf(0.0, nitro - NITRO_DRAIN * delta)
	if Input.is_action_pressed("handbrake"):
		br = 1.0
	if acc > 0.01:
		speed += accel() * acc * delta
	elif br > 0.01:
		speed -= BRAKE * br * delta
	else:
		speed = move_toward(speed, 0.0, FRICTION * delta)
	speed = clampf(speed, -max_speed() * 0.3, max_speed())

func _ai_drive(delta: float) -> void:
	if waypoints.is_empty():
		return
	var ahead := _wp_ahead(6)
	var to := ahead - global_position
	to.y = 0.0
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	var ang := fwd.signed_angle_to(to.normalized(), Vector3.UP)
	steer_target = clampf(-ang * 1.6, -1.0, 1.0)
	if absf(ang) > 0.55:
		speed -= BRAKE * 0.8 * delta
	else:
		speed += accel() * 0.95 * delta
	speed = clampf(speed, 0.0, max_speed() * 0.95)

func _wp_ahead(k: int) -> Vector3:
	var n := waypoints.size()
	return waypoints[(wp + k) % n]

func _track_progress() -> void:
	if waypoints.is_empty():
		return
	if global_position.distance_to(waypoints[wp]) < 14.0:
		wp += 1
		if wp >= waypoints.size():
			wp = 0
			lap += 1
			lap_times.append(race_clock - lap_start)
			lap_start = race_clock

func best_lap() -> float:
	var b := -1.0
	for t in lap_times:
		if b < 0.0 or t < b:
			b = t
	return b
