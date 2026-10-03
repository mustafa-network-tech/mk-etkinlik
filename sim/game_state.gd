extends RefCounted
## Oyun durumunun kökü. Yalnızca komutlarla değişir (commands/command.gd).

const Venue := preload("res://sim/venue.gd")

const SCHEMA_VERSION := 1

var data ## GameData
var venue
var cash: int
var level: int
var event_active := false


func _init(game_data) -> void:
	data = game_data
	var t: Dictionary = data.tuning
	venue = Venue.new(int(t["grid_width"]), int(t["grid_height"]),
			Vector2i(int(t["entrance"][0]), int(t["entrance"][1])))
	cash = int(t["start_cash"])
	level = int(t["start_level"])
