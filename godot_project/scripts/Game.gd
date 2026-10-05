extends Node3D
## RAGE SPEED — top-level state machine: MENU -> GARAGE -> RACE -> RESULTS.

const RaceScript := preload("res://scripts/Race.gd")

const CARS := [
	{"name": "Blue Lightning", "color": Color(0.12, 0.40, 0.95)},
	{"name": "Red Comet", "color": Color(0.86, 0.12, 0.12)},
	{"name": "Green Phantom", "color": Color(0.10, 0.72, 0.32)},
	{"name": "Yellow Bolt", "color": Color(0.95, 0.80, 0.10)},
	{"name": "Purple Storm", "color": Color(0.52, 0.22, 0.86)},
	{"name": "White Ghost", "color": Color(0.92, 0.92, 0.95)},
]

var state := "menu"
var ui: CanvasLayer
var race: Node3D
var car_index := 0
var total_laps := 3
var last_summary := ""

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

func _bg() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.05, 0.06, 0.10, 1.0)
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	ui.add_child(r)
	return r

func _title(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 64)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	l.position = Vector2(-400, 60)
	l.size = Vector2(800, 90)
	ui.add_child(l)
	return l

func _button(text: String, y: float, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 28)
	b.set_anchors_preset(Control.PRESET_CENTER_TOP)
	b.position = Vector2(-160, y)
	b.size = Vector2(320, 56)
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
	var sub := Label.new()
	sub.text = "SVAYAM Racing"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 22)
	sub.set_anchors_preset(Control.PRESET_CENTER_TOP)
	sub.position = Vector2(-400, 150)
	sub.size = Vector2(800, 40)
	ui.add_child(sub)
	_button("START RACE", 260, _start_race)
	_button("GARAGE", 330, _show_garage)
	_button("QUIT", 400, func(): get_tree().quit())

# ---------------------------------------------------------------- garage
func _show_garage() -> void:
	state = "garage"
	_new_ui()
	_bg()
	_title("GARAGE")
	var y := 200.0
	for i in range(CARS.size()):
		var idx := i
		var b := _button(CARS[i]["name"], y, func(): _select_car(idx))
		b.add_theme_color_override("font_color", CARS[i]["color"])
		y += 60.0
	_button("BACK", y + 20.0, _show_menu)

func _select_car(idx: int) -> void:
	car_index = idx
	_show_menu()

# ---------------------------------------------------------------- race
func _start_race() -> void:
	state = "race"
	_clear_ui()
	_clear_race()
	race = RaceScript.new()
	race.car_color = CARS[car_index]["color"]
	race.car_name = CARS[car_index]["name"]
	race.total_laps = total_laps
	race.race_finished.connect(_on_race_finished)
	add_child(race)

func _on_race_finished(summary: String) -> void:
	last_summary = summary
	state = "results"
	_clear_race()
	_new_ui()
	_bg()
	_title("FINISHED")
	var l := Label.new()
	l.text = summary
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 24)
	l.set_anchors_preset(Control.PRESET_CENTER_TOP)
	l.position = Vector2(-400, 200)
	l.size = Vector2(800, 200)
	ui.add_child(l)
	_button("RACE AGAIN", 440, _start_race)
	_button("MAIN MENU", 510, _show_menu)
