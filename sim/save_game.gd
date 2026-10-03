extends RefCounted
## Kaydet/yükle (docs/07-SAVE-LOAD.md). Dosya: ilk satır zarf JSON, kalanı durum JSON'u;
## zarftaki checksum durum metninin SHA-256'sıdır (float/int yeniden yazım farkından kaçınmak için).

const GameState := preload("res://sim/game_state.gd")

const CURRENT_VERSION := 1
const GAME_VERSION := "0.1.0"

## Her giriş from -> from+1 dönüştürür. Henüz taşınacak sürüm yok.
static var MIGRATIONS: Array[Callable] = []


static func to_dict(state) -> Dictionary:
	var venue = state.venue
	var walls := []
	for key in venue.walls:
		walls.append({"x": key.x, "y": key.y, "edge": key.z, "kind": venue.walls[key]})
	walls.sort_custom(func(a, b): return [a.y, a.x, a.edge] < [b.y, b.x, b.edge])
	var ids: Array = venue.items.keys()
	ids.sort()
	var items := []
	for id in ids:
		var it: Dictionary = venue.items[id]
		items.append({"id": id, "def": it["def"], "x": it["x"], "y": it["y"],
				"rot": it["rot"], "cond": it["cond"]})
	return {
		"cash": state.cash,
		"level": state.level,
		"venue": {"width": venue.width, "height": venue.height, "walls": walls,
				"items": items, "next_id": venue.next_id},
	}


## {ok, state, warnings[]} | {ok=false, error}. Cells ve doluluk katalogdan yeniden kurulur.
static func from_dict(game_data, d: Dictionary) -> Dictionary:
	var state = GameState.new(game_data)
	var v: Dictionary = d.get("venue", {})
	if int(v.get("width", -1)) != state.venue.width or int(v.get("height", -1)) != state.venue.height:
		return {"ok": false, "error": "grid_mismatch"}
	state.cash = int(d.get("cash", 0))
	state.level = int(d.get("level", 1))
	var venue = state.venue
	for w in v.get("walls", []):
		var x := int(w["x"])
		var y := int(w["y"])
		var edge := int(w["edge"])
		if not venue.is_inner_edge(x, y, edge):
			return {"ok": false, "error": "corrupt_wall"}
		venue.walls[Vector3i(x, y, edge)] = String(w.get("kind", "plain"))
	var warnings: Array[String] = []
	for it in v.get("items", []):
		var def_id := String(it["def"])
		if not game_data.has_def(def_id):
			warnings.append("unknown_item:" + def_id)
			continue
		var id := int(it["id"])
		var rot := int(it["rot"])
		if not game_data.ROTATIONS.has(rot) or venue.items.has(id):
			return {"ok": false, "error": "corrupt_item"}
		var origin := Vector2i(int(it["x"]), int(it["y"]))
		var cells: Array[Vector2i] = []
		for off in game_data.footprint(def_id, rot):
			var c: Vector2i = origin + off
			if not venue.in_bounds(c) or venue.occupant(c) != 0:
				return {"ok": false, "error": "corrupt_item"}
			cells.append(c)
		for c in cells:
			venue.set_occupant(c, id)
		venue.items[id] = {"id": id, "def": def_id, "x": origin.x, "y": origin.y,
				"rot": rot, "cond": float(it.get("cond", 1.0)), "cells": cells}
	venue.next_id = maxi(int(v.get("next_id", 1)), _max_id(venue) + 1)
	return {"ok": true, "state": state, "warnings": warnings}


static func migrate(d: Dictionary, from: int, migrations: Array = MIGRATIONS, target: int = CURRENT_VERSION) -> Dictionary:
	while from < target:
		d = migrations[from - 1].call(d)
		from += 1
	return d


## Atomik yazma: .tmp'ye yaz, eski kaydı .bak yap, .tmp'yi yerine koy.
static func write(state, path: String) -> bool:
	var body := JSON.stringify(to_dict(state), "", true)
	var env := JSON.stringify({"schema_version": CURRENT_VERSION, "game_version": GAME_VERSION,
			"checksum": body.sha256_text()}, "", true)
	var tmp := path + ".tmp"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(env + "\n" + body)
	f.close()
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path), ProjectSettings.globalize_path(path + ".bak"))
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(path)) == OK


## Bozuk/eksik dosyada .bak denenir; sonuçta from_backup işaretlenir. Sessiz silme yok.
static func read(game_data, path: String) -> Dictionary:
	var r := _read_one(game_data, path)
	if r["ok"]:
		return r
	if FileAccess.file_exists(path + ".bak"):
		var b := _read_one(game_data, path + ".bak")
		if b["ok"]:
			b["from_backup"] = true
			return b
	return r


static func _read_one(game_data, path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"ok": false, "error": "not_found"}
	var text := f.get_as_text()
	var nl := text.find("\n")
	if nl < 0:
		return {"ok": false, "error": "corrupt"}
	var parser := JSON.new() # parse_string bozuk dosyada motor hatası basar
	var body := text.substr(nl + 1)
	if parser.parse(text.substr(0, nl)) != OK or typeof(parser.data) != TYPE_DICTIONARY:
		return {"ok": false, "error": "corrupt"}
	var env: Dictionary = parser.data
	if env.get("checksum", "") != body.sha256_text():
		return {"ok": false, "error": "checksum"}
	var version := int(env.get("schema_version", 0))
	if version > CURRENT_VERSION:
		return {"ok": false, "error": "newer_version"}
	var d = JSON.parse_string(body)
	if typeof(d) != TYPE_DICTIONARY or version < 1:
		return {"ok": false, "error": "corrupt"}
	return from_dict(game_data, migrate(d, version))


static func _max_id(venue) -> int:
	var m := 0
	for id in venue.items:
		m = maxi(m, id)
	return m
