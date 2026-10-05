extends Node3D
## Builds the world, spawns the player + AI opponents, runs a countdown,
## the race loop, records, and a simple procedural engine sound.

signal race_finished(result: Dictionary)

const TrackScript := preload("res://scripts/Track.gd")
const CarScript := preload("res://scripts/Car.gd")
const HudScript := preload("res://scripts/HUD.gd")
const CamScript := preload("res://scripts/ChaseCamera.gd")

const RECORDS_PATH := "user://records.json"

const AI_MODELS := [
	"res://models/kenney/raceCarGreen.glb",
	"res://models/kenney/raceCarOrange.glb",
	"res://models/kenney/raceCarWhite.glb",
	"res://models/kenney/sedan-sports.glb",
	"res://models/kenney/hatchback-sports.glb",
]

var car_color := Color(0.86, 0.12, 0.12)
var car_name := "Red Comet"
var car_model := "res://models/kenney/raceCarRed.glb"
var car_stats := {"top": 1.0, "accel": 1.0, "grip": 1.0, "boost": 1.0}
var track_index := 0
var total_laps := 3
var num_cars := 6

var track: Node3D
var cars: Array = []
var player: CharacterBody3D
var hud: CanvasLayer
var engine_player: AudioStreamPlayer
var race_time := 0.0
var countdown := 3.2
var started := false
var finished := false

func _ready() -> void:
	_setup_environment()
	track = TrackScript.new()
	track.track_index = track_index
	add_child(track)
	track.build()
	_spawn_cars()
	if "--autoplay" in OS.get_cmdline_user_args():
		total_laps = 1
		player.is_ai = true
		countdown = 0.5
		var n: int = track.centerline.size()
		player.global_position = track.centerline[n - 8]
		player.look_at(track.centerline[n - 8] + track._tangent(n - 8), Vector3.UP)
		player.wp = n - 8
	_setup_camera()
	hud = HudScript.new()
	add_child(hud)
	hud.setup_minimap(track.centerline)
	_setup_audio()

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
		if i == 0:
			car.color = car_color
			car.stats = car_stats
			car.model_path = car_model
		else:
			car.color = Color.from_hsv(fmod(0.15 * i, 1.0), 0.7, 0.9)
			car.model_path = AI_MODELS[(i - 1) % AI_MODELS.size()]
			car.stats = {
				"top": 0.94 + 0.02 * i, "accel": 0.96 + 0.015 * i,
				"grip": 0.98 + 0.01 * i, "boost": 1.0,
			}
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

# ------------------------------------------------------------- audio
func _setup_audio() -> void:
	engine_player = AudioStreamPlayer.new()
	engine_player.stream = _make_engine_wav()
	engine_player.volume_db = -18.0
	add_child(engine_player)
	engine_player.play()

func _make_engine_wav() -> AudioStreamWAV:
	var rate := 22050
	var n := int(rate * 0.4)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(rate)
		var f := 70.0 + 30.0 * sin(t * 6.283 * 4.0)
		var s := sin(t * 6.283 * f) * 0.5 + (randf() - 0.5) * 0.15
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = n
	return wav

# ------------------------------------------------------------- loop
func _process(delta: float) -> void:
	if finished:
		return
	if not started:
		countdown -= delta
		hud.set_countdown(str(int(ceil(maxf(countdown, 0.0)))) if countdown > 0.0 else "GO!")
		if countdown <= 0.0:
			started = true
			hud.set_countdown("")
			for c in cars:
				c.can_drive = true
		_update_hud()
		return
	race_time += delta
	for c in cars:
		c.race_clock = race_time
	if is_instance_valid(engine_player):
		engine_player.pitch_scale = 0.7 + player.speed / maxf(player.max_speed(), 1.0) * 0.9
	var order := _compute_order()
	_update_hud()
	if not finished and player.lap >= total_laps:
		_finish()

func _compute_order() -> Array:
	var n: int = track.centerline.size()
	var scored := []
	for c in cars:
		scored.append({"car": c, "score": c.lap * n + c.wp})
	scored.sort_custom(func(a, b): return a["score"] > b["score"])
	for i in range(scored.size()):
		scored[i]["car"].place = i + 1
	return scored

func _update_hud() -> void:
	hud.update(
		player.speed * 3.6, player.lap, total_laps, player.place, num_cars,
		race_time, player.best_lap(), player.nitro, player.boosting
	)
	hud.update_minimap(cars, player)

func _finish() -> void:
	finished = true
	for c in cars:
		c.finished = true
	var bl: float = player.best_lap()
	var rec := _load_records()
	var key: String = track.track_name
	var note := ""
	if not rec.has(key) or race_time < rec[key]["best_total"]:
		rec[key] = {"best_total": race_time, "best_lap": bl}
		_save_records(rec)
		note = "\nNEW RECORD!"
	var summary := "%s\nTrack: %s\n\nYou finished P%d of %d\nTotal %s\nBest lap %s%s" % [
		car_name, track.track_name, player.place, num_cars,
		_fmt(race_time), _fmt(bl), note
	]
	race_finished.emit({
		"summary": summary, "place": player.place, "time": race_time,
		"track": track.track_name, "laps": total_laps, "record": note != "",
	})

func _load_records() -> Dictionary:
	if not FileAccess.file_exists(RECORDS_PATH):
		return {}
	var f := FileAccess.open(RECORDS_PATH, FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data if data is Dictionary else {}

func _save_records(rec: Dictionary) -> void:
	var f := FileAccess.open(RECORDS_PATH, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(rec))

func _fmt(t: float) -> String:
	if t < 0.0:
		return "--"
	var m := int(t) / 60
	var s := int(t) % 60
	var cs := int((t - floor(t)) * 100.0)
	return "%d:%02d.%02d" % [m, s, cs]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("autopilot"):
		player.autopilot = not player.autopilot
	if event.is_action_pressed("restart"):
		race_finished.emit({"summary": "Restarted", "place": 0, "time": 0.0, "track": track.track_name})
	if event.is_action_pressed("back"):
		race_finished.emit({"summary": "Back to menu", "place": 0, "time": 0.0, "track": track.track_name})
