extends Node3D
## RAGE SPEED — state machine: MENU -> GARAGE (car + track) -> RACE -> RESULTS.

const RaceScript := preload("res://scripts/Race.gd")

const CARS := [
	{"name": "Blue Lightning", "color": Color(0.12, 0.40, 0.95),
	 "stats": {"top": 1.00, "accel": 1.00, "grip": 1.00, "boost": 1.0}},
	{"name": "Red Comet", "color": Color(0.86, 0.12, 0.12),
	 "stats": {"top": 1.14, "accel": 0.94, "grip": 0.93, "boost": 1.0}},
	{"name": "Green Phantom", "color": Color(0.10, 0.72, 0.32),
	 "stats": {"top": 0.94, "accel": 1.12, "grip": 1.12, "boost": 1.0}},
	{"name": "Yellow Bolt", "color": Color(0.95, 0.80, 0.10),
	 "stats": {"top": 1.05, "accel": 1.05, "grip": 0.90, "boost": 1.25}},
	{"name": "Purple Storm", "color": Color(0.52, 0.22, 0.86),
	 "stats": {"top": 1.00, "accel": 1.00, "grip": 1.18, "boost": 0.90}},
	{"name": "White Ghost", "color": Color(0.92, 0.92, 0.95),
	 "stats": {"top": 1.09, "accel": 0.90, "grip": 1.02, "boost": 1.05}},
]

const TRACK_NAMES := ["Coastal Loop", "City Circuit", "Mountain Pass"]

var state := "menu"
var ui: CanvasLayer
var race: Node3D
var car_index := 0
var track_index := 0
var total_laps := 3

func _ready() -> void:
	_register_actions()
	if "--autoplay" in OS.get_cmdline_user_args():
		_start_race()
	else:
		_show_menu()

# ---------------------------------------------------------------- input
func _register_actions() -> void:
	_add_action("accelerate", [KEY_W, KEY_UP])
	_add_action("brake", [KEY_S, KEY_DOWN])
	_add_action("steer_left", [KEY_A, KEY_LEFT])
	_add_action("steer_right", [KEY_D, KEY_RIGHT])
	_add_action("handbrake", [KEY_SPACE])
	_add_action("nitro", [KEY_SHIFT])
	_add_action("restart", [KEY_R])
	_add_action("back", [KEY_ESCAPE])

func _add_action(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

# ---------------------------------------------------------------- ui helpers
func _new_ui() -> void:
	_clear_ui()
	ui = CanvasLayer.new()
	add_child(ui)

func _clear_ui() -> void:
	if is_instance_valid(ui):
		ui.queue_free()
	ui = null

func _clear_race() -> void:
	if is_instance_valid(race):
		race.queue_free()
	race = null

func _bg() -> void:
	var r := ColorRect.new()
	r.color = Color(0.05, 0.06, 0.10, 1.0)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(r)

func _title(text: String) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 56)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	l.position = Vector2(-400, 40)
	l.size = Vector2(800, 80)
	ui.add_child(l)

func _label(text: String, pos: Vector2, size: int, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.position = pos
	l.horizontal_alignment = align
	l.size = Vector2(760, 40)
	ui.add_child(l)
	return l

func _button(text: String, pos: Vector2, sz: Vector2, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 22)
	b.position = pos
	b.size = sz
	b.pressed.connect(cb)
	ui.add_child(b)
	return b

# ---------------------------------------------------------------- menu
func _show_menu() -> void:
	state = "menu"
	_clear_race()
	_new_ui()
	_bg()
	_title("RAGE SPEED")
	_label("SVAYAM Racing", Vector2(260, 130), 22, HORIZONTAL_ALIGNMENT_CENTER)
	_button("START RACE", Vector2(480, 250), Vector2(320, 56), _start_race)
	_button("GARAGE", Vector2(480, 320), Vector2(320, 56), _show_garage)
	_button("QUIT", Vector2(480, 390), Vector2(320, 56), func(): get_tree().quit())

# ---------------------------------------------------------------- garage
func _show_garage() -> void:
	state = "garage"
	_new_ui()
	_bg()
	_title("GARAGE")
	_label("CARS", Vector2(80, 130), 26)
	_label("TRACKS", Vector2(760, 130), 26)
	var y := 180.0
	for i in range(CARS.size()):
		var idx := i
		var b := _button(CARS[i]["name"], Vector2(80, y), Vector2(340, 44), func(): _select_car(idx))
		if i == car_index:
			b.add_theme_color_override("font_color", CARS[i]["color"])
		y += 50.0
	y = 180.0
	for i in range(TRACK_NAMES.size()):
		var idx2 := i
		var b2 := _button(TRACK_NAMES[i], Vector2(760, y), Vector2(340, 44), func(): _select_track(idx2))
		if i == track_index:
			b2.add_theme_color_override("font_color", Color(1, 0.85, 0.1))
		y += 50.0
	_button("START RACE", Vector2(480, 540), Vector2(320, 56), _start_race)
	_button("BACK", Vector2(480, 606), Vector2(320, 44), _show_menu)

func _select_car(idx: int) -> void:
	car_index = idx
	_show_garage()

func _select_track(idx: int) -> void:
	track_index = idx
	_show_garage()

# ---------------------------------------------------------------- race
func _start_race() -> void:
	state = "race"
	_clear_ui()
	_clear_race()
	race = RaceScript.new()
	race.car_color = CARS[car_index]["color"]
	race.car_name = CARS[car_index]["name"]
	race.car_stats = CARS[car_index]["stats"]
	race.track_index = track_index
	race.total_laps = total_laps
	race.race_finished.connect(_on_race_finished)
	add_child(race)

func _on_race_finished(summary: String) -> void:
	state = "results"
	_clear_race()
	_new_ui()
	_bg()
	_title("FINISHED")
	var l := _label(summary, Vector2(340, 170), 24, HORIZONTAL_ALIGNMENT_CENTER)
	l.size = Vector2(600, 260)
	_button("RACE AGAIN", Vector2(480, 470), Vector2(320, 56), _start_race)
	_button("GARAGE", Vector2(480, 536), Vector2(320, 44), _show_garage)
	_button("MAIN MENU", Vector2(480, 590), Vector2(320, 44), _show_menu)
