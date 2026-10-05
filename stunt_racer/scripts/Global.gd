extends Node
## Global save/load. Binary FileAccess (store_var/get_var), atomic swap,
## and a .bak backup — as specified in the save-schema phase of the TRD.

const SAVE_PATH := "user://save.dat"
const BACKUP_PATH := "user://save.bak"

var data: Dictionary = {}

func _ready() -> void:
	if OS.has_method("set_use_file_access_save_and_swap"):
		OS.set_use_file_access_save_and_swap(true)
	load_game()

func default_data() -> Dictionary:
	return {
		"metadata": {"schema_version": 1, "game_version": "0.1.0"},
		"player_data": {
			"coins": 0,
			"unlocked_cars": ["raceCarRed", "raceCarGreen"],
			"current_car": "raceCarRed",
			"paint": "red",
		},
		"garage_data": {"upgrades": {"engine": 0, "handling": 0, "nitro": 0}},
		"race_progress": {"best_distance": 0.0, "races": 0},
	}

func load_game() -> void:
	data = default_data()
	for path in [SAVE_PATH, BACKUP_PATH]:
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			if f != null:
				var loaded = f.get_var()
				if loaded is Dictionary:
					data = loaded
					return

func save_game() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f != null:
		f.store_var(data)
	if FileAccess.file_exists(SAVE_PATH):
		var src := FileAccess.open(SAVE_PATH, FileAccess.READ)
		var dst := FileAccess.open(BACKUP_PATH, FileAccess.WRITE)
		if src != null and dst != null:
			dst.store_buffer(src.get_buffer(src.get_length()))

# ---- convenience ----
func coins() -> int:
	return int(data.get("player_data", {}).get("coins", 0))

func unlocked_cars() -> Array:
	return data.get("player_data", {}).get("unlocked_cars", [])

func current_car() -> String:
	return String(data.get("player_data", {}).get("current_car", "raceCarRed"))

func best_distance() -> float:
	return float(data.get("race_progress", {}).get("best_distance", 0.0))

func report_run(dist: float, earned: int) -> void:
	var rp: Dictionary = data.get("race_progress", {})
	rp["races"] = int(rp.get("races", 0)) + 1
	if dist > float(rp.get("best_distance", 0.0)):
		rp["best_distance"] = dist
	data["race_progress"] = rp
	data["player_data"]["coins"] = coins() + earned
	save_game()
