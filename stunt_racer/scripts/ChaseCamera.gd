extends Camera3D
## Chase camera. KeepAspect is forced to Keep Height — the TRD calls this out
## as critical for performance in portrait mode.

var target: Node3D
var offset := Vector3(0.0, 4.2, 8.5)
var look_height := 1.2

func _ready() -> void:
	keep_aspect = Camera3D.KEEP_HEIGHT

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		return
	var desired: Vector3 = target.global_transform * offset
	global_position = global_position.lerp(desired, clampf(delta * 4.0, 0.0, 1.0))
	var look_at_point: Vector3 = target.global_position + Vector3(0, look_height, 0)
	if global_position.distance_to(look_at_point) > 0.5:
		look_at(look_at_point, Vector3.UP)
