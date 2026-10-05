extends RigidBody3D
## Arcade stunt car — RigidBody3D + RayCast3D suspension + Ackermann-style
## steering + downforce + lateral grip (drift). Built to the TRD's spec.

const ModelUtil := preload("res://scripts/ModelUtil.gd")

const ENGINE_FORCE := 13000.0
const BRAKE_FORCE := 22000.0
const MAX_STEER := 0.5
const STEER_RATE := 0.25
const YAW_RATE := 2.6
const GRIP := 0.85
const DRIFT_GRIP := 0.35
const DOWNFORCE := 34.0
const SUSP_STIFF := 40000.0
const SUSP_DAMP := 6000.0
const SUSP_REST := 0.75
const SUSP_LEN := 0.9
const MAX_SPEED := 72.0
const BOOST_MULT := 1.55
const NITRO_DRAIN := 0.45
const NITRO_REGEN := 0.14
const STEER_SIGN := -1.0
const CAR_LENGTH := 4.4
const WHEEL_R := 0.35

const WHEEL_POS := [
	Vector3(-0.95, 0.0, -1.35), Vector3(0.95, 0.0, -1.35),
	Vector3(-0.95, 0.0, 1.35), Vector3(0.95, 0.0, 1.35),
]

var model_path := "res://models/kenney/raceCarRed.glb"
var color := Color(0.86, 0.12, 0.12)

var is_ai := false
var waypoints := PackedVector3Array()
var wp := 0

var steer := 0.0
var throttle := 0.0
var brake_in := 0.0
var drifting := false
var boosting := false
var nitro := 1.0
var crashed := false
var finished := false
var distance := 0.0
var coins := 0
var grounded := false
var autopilot := false
var touch_steer := 0.0

var wheel_nodes: Array = []
var rays: Array = []

func _ready() -> void:
	mass = 1000.0
	can_sleep = false
	_build()

func _build() -> void:
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.0, 0.8, CAR_LENGTH)
	cs.shape = bs
	cs.position = Vector3(0, 0.8, 0)
	add_child(cs)

	for p in WHEEL_POS:
		var ray := RayCast3D.new()
		ray.position = p + Vector3(0, 0.4, 0)
		ray.target_position = Vector3(0, -(SUSP_REST + 0.35), 0)
		ray.enabled = true
		add_child(ray)
		rays.append(ray)

	var model := ModelUtil.make_model(model_path, CAR_LENGTH, true)
	model.position = Vector3(0, -0.18, 0)
	add_child(model)
	wheel_nodes = ModelUtil.find_all(model, "wheel", [])

func _physics_process(delta: float) -> void:
	if crashed:
		return
	if is_ai or autopilot:
		_ai_drive()
	else:
		_read_input(delta)
	_apply_suspension()
	_apply_drive()
	_apply_grip()
	_track_distance(delta)
	if global_position.y < -12.0:
		crashed = true

# ---------------------------------------------------------------- input
func _read_input(delta: float) -> void:
	var kb := Input.get_axis("steer_left", "steer_right")
	var target := touch_steer if absf(touch_steer) > 0.02 else kb
	steer = lerp(steer, target, STEER_RATE)
	throttle = Input.get_action_strength("accelerate")
	brake_in = Input.get_action_strength("brake")
	drifting = Input.is_action_pressed("handbrake")
	boosting = Input.is_action_pressed("nitro") and nitro > 0.02
	if boosting:
		nitro = maxf(0.0, nitro - NITRO_DRAIN * delta)
	else:
		nitro = minf(1.0, nitro + NITRO_REGEN * delta)

func _input(event: InputEvent) -> void:
	# one-finger touch steering: hold left/right of the screen centre
	if event is InputEventScreenTouch:
		if event.pressed:
			touch_steer = _touch_to_steer(event.position.x)
		else:
			touch_steer = 0.0
	elif event is InputEventScreenDrag:
		touch_steer = _touch_to_steer(event.position.x)

func _touch_to_steer(x: float) -> float:
	var w := float(get_viewport().get_visible_rect().size.x)
	if w < 1.0:
		return 0.0
	return clampf((x - w * 0.5) / (w * 0.35), -1.0, 1.0)

func _ai_drive() -> void:
	if waypoints.is_empty():
		throttle = 0.0
		return
	var ahead := waypoints[(wp + 6) % waypoints.size()]
	var to := ahead - global_position
	to.y = 0.0
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	var ang := fwd.signed_angle_to(to.normalized(), Vector3.UP)
	steer = clampf(ang * 2.0, -1.0, 1.0)
	throttle = 1.0
	brake_in = 0.0
	if global_position.distance_to(waypoints[wp]) < 12.0:
		wp = (wp + 1) % waypoints.size()

# ---------------------------------------------------------------- physics
func _apply_suspension() -> void:
	grounded = false
	var up := global_transform.basis.y
	for ray in rays:
		if not ray.is_colliding():
			continue
		grounded = true
		var hit: Vector3 = ray.get_collision_point()
		var wheel_pos: Vector3 = ray.global_position
		var dist := wheel_pos.distance_to(hit)
		var compression := clampf(SUSP_REST - dist, 0.0, SUSP_REST)
		var r := wheel_pos - global_position
		var v := linear_velocity + angular_velocity.cross(r)
		var spring := compression * SUSP_STIFF
		var damp := v.dot(up) * SUSP_DAMP
		apply_force((spring - damp) * up, r)

func _apply_drive() -> void:
	if not grounded:
		return
	var fwd := -global_transform.basis.z
	var speed := linear_velocity.length()
	var mult := BOOST_MULT if boosting else 1.0
	if throttle > 0.01 and speed < MAX_SPEED * mult:
		apply_central_force(fwd * throttle * ENGINE_FORCE * mult)
	if brake_in > 0.01:
		var fs := linear_velocity.dot(fwd)
		if fs > 0.5:
			apply_central_force(-fwd * brake_in * BRAKE_FORCE)
		else:
			apply_central_force(-fwd * brake_in * ENGINE_FORCE * 0.6)
	if speed > 0.5:
		var fs2 := linear_velocity.dot(fwd)
		angular_velocity.y = steer * STEER_SIGN * YAW_RATE * clampf(speed / 14.0, 0.0, 1.0) * signf(fs2)
	apply_central_force(-global_transform.basis.y * DOWNFORCE * speed)

func _apply_grip() -> void:
	var fwd := -global_transform.basis.z
	var right := global_transform.basis.x
	var v := linear_velocity
	var f := v.dot(fwd)
	var l := v.dot(right)
	var keep := DRIFT_GRIP if drifting else GRIP
	linear_velocity = fwd * f + right * l * (1.0 - keep) + Vector3(0, v.y, 0)

func _track_distance(delta: float) -> void:
	var fwd := -global_transform.basis.z
	var fs := linear_velocity.dot(fwd)
	if fs > 0.0:
		distance += fs * delta
	var spin := fs * delta / WHEEL_R
	for w in wheel_nodes:
		if is_instance_valid(w):
			w.rotate_x(spin)

func speed_kmh() -> float:
	return linear_velocity.length() * 3.6
