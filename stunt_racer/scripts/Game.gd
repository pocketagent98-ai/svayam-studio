extends Node3D
## Finite-state app flow: MAIN_MENU -> GARAGE -> RACE -> (PAUSED) -> RESULTS.
## One enum-like `state` string tracks the mode, as the App Flow phase suggests.

const RaceScript := preload("res://scripts/Race.gd")

const CARS := [
	{"name": "Red Comet", "model": "res://models/kenney/raceCarRed.glb", "color": Color(0.86, 0.12, 0.12)},
	{"name": "Green Phantom", "model": "res://models/kenney/raceCarGreen.glb", "color": Color(0.10, 0.72, 0.32)},
	{"name": "Orange Bolt", "model": "res://models/kenney/raceCarOrange.glb", "color": Color(0.95, 0.55, 0.10)},
	{"name": "White Ghost", "model": "res://models/kenney/raceCarWhite.glb", "color": Color(0.92, 0.92, 0.95)},
]

var state := "menu"
var ui: CanvasLayer
var race: Node3D
var car_index := 0
var last_result: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_register_actions()
	if "--autoplay" in OS.get_cmdline_user_args():
		_start_race()
	else:
		_show_menu()

# ---------------------------------------------------------------- input
func _register_actions() -> void:
	_add("accelerate", [KEY_W, KEY_UP])
	_add("brake", [KEY_S, KEY_DOWN])
	_add("steer_left", [KEY_A, KEY_LEFT])
	_add("steer_right", [KEY_D, KEY_RIGHT])
	_add("handbrake", [KEY_SPACE])
	_add("nitro", [KEY_SHIFT])
	_add("pause", [KEY_P])
	_add("restart", [KEY_R])
	_add("back", [KEY_ESCAPE])

func _add(action: String, keys: Array) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == "race":
			_pause()
		elif state == "paused":
			_resume()

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

func _title(t: String, y: float = 120.0) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", 56)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(720, 80)
	ui.add_child(l)

func _label(t: String, y: float, size: int = 26) -> void:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.position = Vector2(0, y)
	l.size = Vector2(720, 60)
	ui.add_child(l)

func _button(t: String, y: float, cb: Callable, col: Color = Color.WHITE) -> Button:
	var b := Button.new()
	b.text = t
	b.add_theme_font_size_override("font_size", 30)
	b.position = Vector2(180, y)
	b.size = Vector2(360, 70)
	b.add_theme_color_override("font_color", col)
	b.pressed.connect(cb)
	ui.add_child(b)
	return b

# ---------------------------------------------------------------- menu
func _show_menu() -> void:
	state = "menu"
	_clear_race()
	_new_ui()
	_bg()
	_title("STUNT RACER", 150.0)
	_label("SVAYAM Racing", 230.0, 22)
	_label("Coins: %d" % Global.coins(), 290.0, 24)
	_button("QUICK RACE", 380.0, _start_race)
	_button("GARAGE", 470.0, _show_garage)
	_button("QUIT", 560.0, func(): get_tree().quit())

# ---------------------------------------------------------------- garage
func _show_garage() -> void:
	state = "garage"
	_new_ui()
	_bg()
	_title("GARAGE", 90.0)
	_label("Coins: %d" % Global.coins(), 170.0, 24)
	var y := 250.0
	for i in range(CARS.size()):
		var idx := i
		var b := _button(CARS[i]["name"], y, func(): _select_car(idx), CARS[i]["color"])
		if i == car_index:
			b.add_theme_color_override("font_color", Color(1, 0.85, 0.1))
		y += 80.0
	_button("RACE", y + 20.0, _start_race)
	_button("BACK", y + 110.0, _show_menu)

func _select_car(idx: int) -> void:
	car_index = idx
	Global.data["player_data"]["current_car"] = CARS[idx]["name"]
	Global.save_game()
	_show_garage()

# ---------------------------------------------------------------- race
func _start_race() -> void:
	get_tree().paused = false
	state = "race"
	_clear_ui()
	_clear_race()
	race = RaceScript.new()
	race.car_model = CARS[car_index]["model"]
	race.car_color = CARS[car_index]["color"]
	race.race_finished.connect(_on_race_finished)
	add_child(race)
	race.process_mode = Node.PROCESS_MODE_PAUSABLE

func _pause() -> void:
	state = "paused"
	get_tree().paused = true
	_new_ui()
	ui.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	_bg()
	_title("PAUSED", 300.0)
	_button("RESUME", 460.0, _resume)
	_button("MAIN MENU", 550.0, func():
		get_tree().paused = false
		_show_menu())

func _resume() -> void:
	get_tree().paused = false
	_clear_ui()
	state = "race"

func _on_race_finished(result: Dictionary) -> void:
	get_tree().paused = false
	last_result = result
	state = "results"
	_clear_race()
	_new_ui()
	_bg()
	_title("CRASHED!", 130.0)
	_label("Distance: %d m" % int(result.get("distance", 0.0)), 260.0, 30)
	_label("Coins: %d" % int(result.get("coins", 0)), 320.0, 30)
	_label("Best: %d m" % int(result.get("best", 0.0)), 380.0, 30)
	_label("Total coins: %d" % Global.coins(), 440.0, 24)
	_button("RACE AGAIN", 540.0, _start_race)
	_button("GARAGE", 630.0, _show_garage)
	_button("MAIN MENU", 720.0, _show_menu)
