extends CanvasLayer
## Portrait HUD: speed + distance (top left), coins + best (top right),
## nitro bar, and a centre message line. Top zone only, per the UX brief.

var speed_label: Label
var dist_label: Label
var coin_label: Label
var best_label: Label
var nitro_bg: ColorRect
var nitro_fill: ColorRect
var msg_label: Label

func _ready() -> void:
	speed_label = _mk(Vector2(30, 40), 52, HORIZONTAL_ALIGNMENT_LEFT)
	dist_label = _mk(Vector2(30, 100), 26, HORIZONTAL_ALIGNMENT_LEFT)
	coin_label = _mk(Vector2(360, 40), 40, HORIZONTAL_ALIGNMENT_RIGHT)
	best_label = _mk(Vector2(360, 90), 22, HORIZONTAL_ALIGNMENT_RIGHT)
	coin_label.size = Vector2(330, 60)
	best_label.size = Vector2(330, 40)

	nitro_bg = ColorRect.new()
	nitro_bg.color = Color(0, 0, 0, 0.45)
	nitro_bg.position = Vector2(30, 140)
	nitro_bg.size = Vector2(300, 22)
	add_child(nitro_bg)
	nitro_fill = ColorRect.new()
	nitro_fill.color = Color(0.2, 0.8, 1.0)
	nitro_fill.position = Vector2(33, 143)
	nitro_fill.size = Vector2(294, 16)
	add_child(nitro_fill)

	msg_label = _mk(Vector2(0, 480), 90, HORIZONTAL_ALIGNMENT_CENTER)
	msg_label.size = Vector2(720, 140)
	msg_label.add_theme_color_override("font_color", Color(1, 0.85, 0.1))

func _mk(pos: Vector2, size: int, align: int) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	l.add_theme_constant_override("outline_size", 6)
	l.position = pos
	l.horizontal_alignment = align
	l.size = Vector2(400, 70)
	add_child(l)
	return l

func set_message(t: String) -> void:
	msg_label.text = t

func update(kmh: float, dist: float, nitro: float, boosting: bool, coins: int, best: float) -> void:
	speed_label.text = "%d" % int(kmh)
	dist_label.text = "%d m" % int(dist)
	coin_label.text = "%d" % coins
	best_label.text = "best %d m" % int(best)
	nitro_fill.size.x = 294.0 * clampf(nitro, 0.0, 1.0)
	nitro_fill.color = Color(1.0, 0.6, 0.1) if boosting else Color(0.2, 0.8, 1.0)
