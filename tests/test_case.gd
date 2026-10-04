extends RefCounted
## Test tabanı: check/eq başarısızlıkları toplar.

const GameData := preload("res://sim/game_data.gd")
const GameState := preload("res://sim/game_state.gd")
const Command := preload("res://commands/command.gd")

var failures: Array[String] = []


func new_state():
	var data := GameData.new()
	assert(data.load_from("res://data/items.json", "res://data/tuning.json"))
	return GameState.new(data)


func check(cond: bool, msg: String) -> void:
	if not cond:
		failures.append(msg)


func eq(actual: Variant, expected: Variant, msg: String) -> void:
	if actual != expected:
		failures.append("%s (beklenen %s, gelen %s)" % [msg, str(expected), str(actual)])


func place(state, def: String, x: int, y: int, rot: int = 0) -> Dictionary:
	return Command.apply(state, {"type": "place_item", "def": def, "x": x, "y": y, "rot": rot})
