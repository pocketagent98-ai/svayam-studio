extends CanvasLayer
## In-race heads-up display: speed, lap, position, time, and a hint line.

var speed_label: Label
var lap_label: Label
var place_label: Label
var time_label: Label
var hint_label: Label
var _t := 0.0

func _ready() -> void:
	speed_label = _mk(Vector2(30, 24), 44, HORIZONTAL_ALIGNMENT_LEFT)
	lap_label = _mk(Vector2(30, 80), 24, HORIZONTAL_ALIGNMENT_LEFT)
	place_label = _mk(Vector2(30, 112), 24, HORIZONTAL_ALIGNMENT_LEFT)
	time_label = _mk(Vector2(30, 144), 24, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label = _mk(Vector2(30, 660), 18, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label.text = "W/Up accelerate   S/Down brake   A/D steer   Space handbrake   R restart   Esc menu"

func _mk(pos: Vector2, size: int, align: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	l.position = pos
	l.horizontal_alignment = align
	l.size = Vector2(700, 60)
	add_child(l)
	return l

func update(speed_kmh: float, lap: int, total_laps: int, place: int, total_cars: int, race_time: float) -> void:
	speed_label.text = "%d km/h" % int(speed_kmh)
	lap_label.text = "LAP %d / %d" % [min(lap + 1, total_laps), total_laps]
	place_label.text = "POSITION %d / %d" % [place, total_cars]
	time_label.text = "TIME %s" % _fmt(race_time)

func _fmt(t: float) -> String:
	var m := int(t) / 60
	var s := int(t) % 60
	var cs := int((t - floor(t)) * 100.0)
	return "%d:%02d.%02d" % [m, s, cs]
