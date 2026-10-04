extends RefCounted
## Oyuncu eylemleri komuttur: {type, ...args}. Doğrular, uygular ya da {ok=false, error} döner.

const Nav := preload("res://sim/nav.gd")


static func apply(state, cmd: Dictionary) -> Dictionary:
	if state.event_active:
		return _fail("locked_during_event")
	match cmd.get("type", ""):
		"place_item": return _place_item(state, cmd)
		"remove_item": return _remove_item(state, cmd)
		"add_wall": return _add_wall(state, cmd)
		"remove_wall": return _remove_wall(state, cmd)
	return _fail("unknown_command")


## Yerleştirme geçerli mi? "" = evet, değilse hata kodu. Durumu değiştirmez (önizleme için).
static func check_place(state, def_id: String, origin: Vector2i, rot: int) -> String:
	var data = state.data
	var venue = state.venue
	if state.event_active:
		return "locked_during_event"
	if not data.has_def(def_id):
		return "unknown_item"
	if not data.ROTATIONS.has(rot):
		return "bad_rotation"
	var def: Dictionary = data.defs[def_id]
	if int(def["tier_unlock"]) > state.level:
		return "locked"
	if state.cash < int(def["price"]):
		return "not_enough_cash"
	var cells: Array[Vector2i] = []
	for off in data.footprint(def_id, rot):
		cells.append(origin + off)
	for c in cells:
		if not venue.in_bounds(c):
			return "out_of_bounds"
		if venue.occupant(c) != 0:
			return "occupied"
	for a in cells:
		for d in Nav.DIRS:
			if cells.has(a + d) and venue.has_wall_between(a, a + d):
				return "wall_in_way"
	if cells.has(venue.entrance) and data.blocks_movement(def_id):
		return "blocks_entrance"
	return ""


static func _place_item(state, cmd: Dictionary) -> Dictionary:
	var def_id: String = cmd.get("def", "")
	var rot: int = int(cmd.get("rot", 0))
	var origin := Vector2i(int(cmd.get("x", 0)), int(cmd.get("y", 0)))
	var err := check_place(state, def_id, origin, rot)
	if err != "":
		return _fail(err)
	var venue = state.venue
	var def: Dictionary = state.data.defs[def_id]
	var cells: Array[Vector2i] = []
	for off in state.data.footprint(def_id, rot):
		cells.append(origin + off)
	var id: int = venue.next_id
	venue.next_id += 1
	venue.items[id] = {"id": id, "def": def_id, "x": origin.x, "y": origin.y,
			"rot": rot, "cond": 1.0, "cells": cells}
	for c in cells:
		venue.set_occupant(c, id)
	state.cash -= int(def["price"])
	return {"ok": true, "id": id}


static func _remove_item(state, cmd: Dictionary) -> Dictionary:
	var venue = state.venue
	var id: int = int(cmd.get("id", 0))
	if not venue.items.has(id):
		return _fail("no_such_item")
	var item: Dictionary = venue.items[id]
	var def: Dictionary = state.data.defs[item["def"]]
	var ratio: float = float(state.data.tuning["default_sell_ratio"])
	for c in item["cells"]:
		venue.set_occupant(c, 0)
	venue.items.erase(id)
	state.cash += int(int(def["price"]) * ratio)
	return {"ok": true}


static func _add_wall(state, cmd: Dictionary) -> Dictionary:
	var venue = state.venue
	var x: int = int(cmd.get("x", 0))
	var y: int = int(cmd.get("y", 0))
	var edge: int = int(cmd.get("edge", 0))
	if not venue.is_inner_edge(x, y, edge):
		return _fail("not_buildable")
	var key := Vector3i(x, y, edge)
	if venue.walls.has(key):
		return _fail("wall_exists")
	var cost: int = int(state.data.tuning["wall_cost"])
	if state.cash < cost:
		return _fail("not_enough_cash")
	var a := Vector2i(x, y)
	var b := a + (Vector2i(1, 0) if edge == venue.E else Vector2i(0, -1))
	var ia: int = venue.occupant(a)
	if ia > 0 and ia == venue.occupant(b):
		return _fail("item_in_way")
	venue.walls[key] = "plain"
	state.cash -= cost
	return {"ok": true}


static func _remove_wall(state, cmd: Dictionary) -> Dictionary:
	var venue = state.venue
	var key := Vector3i(int(cmd.get("x", 0)), int(cmd.get("y", 0)), int(cmd.get("edge", 0)))
	if not venue.walls.has(key):
		return _fail("no_such_wall")
	venue.walls.erase(key)
	state.cash += int(int(state.data.tuning["wall_cost"]) * float(state.data.tuning["wall_refund_ratio"]))
	return {"ok": true}


static func _fail(reason: String) -> Dictionary:
	return {"ok": false, "error": reason}
