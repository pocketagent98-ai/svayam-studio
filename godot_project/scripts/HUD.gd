extends CanvasLayer
## In-race HUD: speed, lap, position, time, best lap, nitro bar, countdown,
## and a live minimap.

var speed_label: Label
var lap_label: Label
var place_label: Label
var time_label: Label
var best_label: Label
var hint_label: Label
var countdown_label: Label
var nitro_bg: ColorRect
var nitro_fill: ColorRect

var map: Control
var map_points := PackedVector3Array()
var map_cars: Array = []
var map_player: Node3D

func _ready() -> void:
	speed_label = _mk(Vector2(30, 24), 44, HORIZONTAL_ALIGNMENT_LEFT)
	lap_label = _mk(Vector2(30, 80), 24, HORIZONTAL_ALIGNMENT_LEFT)
	place_label = _mk(Vector2(30, 112), 24, HORIZONTAL_ALIGNMENT_LEFT)
	time_label = _mk(Vector2(30, 144), 24, HORIZONTAL_ALIGNMENT_LEFT)
	best_label = _mk(Vector2(30, 176), 24, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label = _mk(Vector2(30, 660), 18, HORIZONTAL_ALIGNMENT_LEFT)
	hint_label.text = "W/Up gas   S/Down brake   A/D steer   Shift nitro   C autopilot   Space handbrake   R restart   Esc menu"

	countdown_label = _mk(Vector2(0, 240), 110, HORIZONTAL_ALIGNMENT_CENTER)
	countdown_label.size = Vector2(1280, 140)
	countdown_label.add_theme_color_override("font_color", Color(1, 0.85, 0.1))

	nitro_bg = ColorRect.new()
	nitro_bg.color = Color(0, 0, 0, 0.5)
	nitro_bg.position = Vector2(30, 214)
	nitro_bg.size = Vector2(260, 18)
	add_child(nitro_bg)
	nitro_fill = ColorRect.new()
	nitro_fill.color = Color(0.2, 0.8, 1.0)
	nitro_fill.position = Vector2(32, 216)
	nitro_fill.size = Vector2(256, 14)
	add_child(nitro_fill)

	map = Control.new()
	map.position = Vector2(1040, 24)
	map.size = Vector2(220, 220)
	map.draw.connect(_on_map_draw)
	add_child(map)

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

func setup_minimap(centerline: PackedVector3Array) -> void:
	map_points = centerline

func set_countdown(text: String) -> void:
	countdown_label.text = text

func update(speed_kmh: float, lap: int, total_laps: int, place: int, total_cars: int,
		race_time: float, best_lap: float, nitro: float, boosting: bool) -> void:
	speed_label.text = "%d km/h" % int(speed_kmh)
	lap_label.text = "LAP %d / %d" % [min(lap + 1, total_laps), total_laps]
	place_label.text = "POSITION %d / %d" % [place, total_cars]
	time_label.text = "TIME %s" % _fmt(race_time)
	best_label.text = "BEST LAP %s" % _fmt(best_lap)
	nitro_fill.size.x = 256.0 * clampf(nitro, 0.0, 1.0)
	nitro_fill.color = Color(1.0, 0.6, 0.1) if boosting else Color(0.2, 0.8, 1.0)

func update_minimap(cars: Array, player: Node3D) -> void:
	map_cars = cars
	map_player = player
	map.queue_redraw()

func _on_map_draw() -> void:
	if map_points.is_empty():
		return
	var mn := Vector2(1e9, 1e9)
	var mx := Vector2(-1e9, -1e9)
	for p in map_points:
		mn.x = minf(mn.x, p.x); mn.y = minf(mn.y, p.z)
		mx.x = maxf(mx.x, p.x); mx.y = maxf(mx.y, p.z)
	var span := maxf(mx.x - mn.x, mx.y - mn.y)
	if span < 1.0:
		span = 1.0
	var pad := 16.0
	var scale := (map.size.x - pad * 2.0) / span

	map.draw_rect(Rect2(Vector2.ZERO, map.size), Color(0, 0, 0, 0.35))

	var pts := PackedVector2Array()
	for p in map_points:
		pts.append(Vector2(pad + (p.x - mn.x) * scale, pad + (p.z - mn.y) * scale))
	map.draw_polyline(pts, Color(0.8, 0.8, 0.8), 2.0)

	for c in map_cars:
		var gp: Vector3 = c.global_position
		var pos := Vector2(pad + (gp.x - mn.x) * scale, pad + (gp.z - mn.y) * scale)
		var col: Color = c.color
		var r := 5.0 if c == map_player else 3.5
		map.draw_circle(pos, r, col)
		if c == map_player:
			map.draw_arc(pos, r + 3.0, 0, TAU, 20, Color.WHITE, 2.0)

func _fmt(t: float) -> String:
	if t < 0.0:
		return "--"
	var m := int(t) / 60
	var s := int(t) % 60
	var cs := int((t - floor(t)) * 100.0)
	return "%d:%02d.%02d" % [m, s, cs]
