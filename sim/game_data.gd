extends RefCounted
## Katalog ve ayarlar (data/*.json). Kayda girmez; def_id ile anılır.

const ROTATIONS := [0, 90, 180, 270]

var defs: Dictionary = {}
var tuning: Dictionary = {}
var event_types: Dictionary = {}
var names: Array = []


func load_from(items_path: String, tuning_path: String,
		event_types_path: String = "res://data/event_types.json",
		names_path: String = "res://data/names.json") -> bool:
	var items = _read_json(items_path)
	var tun = _read_json(tuning_path)
	var types = _read_json(event_types_path)
	var nm = _read_json(names_path)
	if typeof(items) != TYPE_DICTIONARY or typeof(tun) != TYPE_DICTIONARY \
			or typeof(types) != TYPE_DICTIONARY or typeof(nm) != TYPE_DICTIONARY:
		return false
	tuning = tun
	event_types = types
	names = nm["first"]
	defs.clear()
	for id in items:
		var def: Dictionary = items[id]
		var cells: Array[Vector2i] = []
		for c in def["footprint"]:
			cells.append(Vector2i(int(c[0]), int(c[1])))
		def["footprint"] = cells
		def["id"] = id
		defs[id] = def
	return true


func has_def(def_id: String) -> bool:
	return defs.has(def_id)


## Ayak izi hücreleri, 90° adımlarla döndürülmüş ve sol-üst köşesi (0,0)'a oturtulmuş.
func footprint(def_id: String, rot: int) -> Array[Vector2i]:
	var turns := int(rot / 90.0)
	var out: Array[Vector2i] = []
	var min_x := 1 << 30
	var min_y := 1 << 30
	for c in defs[def_id]["footprint"]:
		var v: Vector2i = c
		for i in turns:
			v = Vector2i(-v.y, v.x)
		out.append(v)
		min_x = mini(min_x, v.x)
		min_y = mini(min_y, v.y)
	for i in out.size():
		out[i] -= Vector2i(min_x, min_y)
	return out


func blocks_movement(def_id: String) -> bool:
	return bool(defs[def_id]["blocks_movement"])


func _read_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return null
	return JSON.parse_string(f.get_as_text())
