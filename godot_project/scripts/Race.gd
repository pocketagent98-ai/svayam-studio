extends Node3D
## Builds the world, spawns the player + AI opponents, and runs the race loop.

signal race_finished(summary: String)

const TrackScript := preload("res://scripts/Track.gd")
const CarScript := preload("res://scripts/Car.gd")
const HudScript := preload("res://scripts/HUD.gd")
const CamScript := preload("res://scripts/ChaseCamera.gd")

var car_color := Color(0.12, 0.40, 0.95)
var car_name := "Blue Lightning"
var total_laps := 3
var num_cars := 6

var track: Node3D
var cars: Array = []
var player: CharacterBody3D
var hud: CanvasLayer
var race_time := 0.0
var racing := false
var finished := false

func _ready() -> void:
	_setup_environment()
	track = TrackScript.new()
	add_child(track)
	track.build()
	_spawn_cars()
	if "--autoplay" in OS.get_cmdline_user_args():
		total_laps = 1
		player.is_ai = true
	_setup_camera()
	hud = HudScript.new()
	add_child(hud)
	racing = true

func _setup_environment() -> void:
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
	sun.shadow_enabled = true
	add_child(sun)

func _spawn_cars() -> void:
	var cl: PackedVector3Array = track.centerline
	var t: Vector3 = track._tangent(0)
	var right: Vector3 = t.cross(Vector3.UP).normalized()
	for i in range(num_cars):
		var car := CarScript.new()
		car.waypoints = cl
		car.total_laps = total_laps
		car.is_ai = i != 0
		car.is_player = i == 0
		car.lap = 0
		car.wp = 0
		if i == 0:
			car.color = car_color
		else:
			car.color = Color.from_hsv(fmod(0.15 * i, 1.0), 0.7, 0.9)
		var lateral := ((i % 2) * 2.0 - 1.0) * 2.6
		var back := float(i / 2) * 6.5 + 3.0
		var pos: Vector3 = cl[0] + right * lateral - t * back
		pos.y = 0.6
		add_child(car)
		car.global_position = pos
		car.look_at(pos + t, Vector3.UP)
		cars.append(car)
		if i == 0:
			player = car

func _setup_camera() -> void:
	var cam := CamScript.new()
	cam.target = player
	add_child(cam)
	cam.global_position = player.global_position + Vector3(0, 4, 9)

func _process(delta: float) -> void:
	if not racing:
		return
	race_time += delta
	var order := _compute_order()
	_update_hud(order)
	if not finished and player.lap >= total_laps:
		_finish(order)

func _compute_order() -> Array:
	var n: int = track.centerline.size()
	var scored := []
	for c in cars:
		scored.append({"car": c, "score": c.lap * n + c.wp})
	scored.sort_custom(func(a, b): return a["score"] > b["score"])
	for i in range(scored.size()):
		scored[i]["car"].place = i + 1
	return scored

func _update_hud(order: Array) -> void:
	var speed: float = player.speed * 3.6
	hud.update(speed, player.lap, total_laps, player.place, num_cars, race_time)

func _finish(order: Array) -> void:
	finished = true
	racing = false
	for c in cars:
		c.finished = true
	var place: int = player.place
	var summary := "%s\n\nYou finished P%d of %d\nTime %s\nLaps %d" % [
		car_name, place, num_cars, _fmt(race_time), total_laps
	]
	race_finished.emit(summary)

func _fmt(t: float) -> String:
	var m := int(t) / 60
	var s := int(t) % 60
	var cs := int((t - floor(t)) * 100.0)
	return "%d:%02d.%02d" % [m, s, cs]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		race_finished.emit("Restarted")
	if event.is_action_pressed("back"):
		race_finished.emit("Back to menu")
