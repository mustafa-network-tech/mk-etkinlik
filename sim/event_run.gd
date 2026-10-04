extends RefCounted
## Etkinlik günü simülasyonu (docs/04). Sabit adımlı, tohumlu rastgelelik; mekânı yalnız okur.

const Nav := preload("res://sim/nav.gd")
const AStar := preload("res://sim/astar.gd")
const Guest := preload("res://sim/guest.gd")
const Waiter := preload("res://sim/waiter.gd")
const G := Guest.State

var state
var cfg: Dictionary
var rng_persona := RandomNumberGenerator.new()
var rng_decide := RandomNumberGenerator.new()

var step_count := 0
var total_steps := 0
var guest_total := 0
var finished := false
var music_on := false

var guests: Array = [] ## id-1 indeksli; çıkanlar da kalır (metrik için)
var stations: Array = [] ## {item_id, kind, slots, use_s, occupants, queue, cells}
var waiters: Array = []
var cooks := 0
## id -> {guest, placed_step, state: PLACED|TAKEN|READY|BLOCKED, cook: QUEUED|COOKING|DONE, cook_left}
var orders: Dictionary = {}
var event_log: Array = [] ## {minute, guest, kind, where}
var metrics := {"abandon_count": 0, "meals": 0, "dances": 0, "wc_uses": 0,
		"order_waits_s": [], "max_queue_wc": 0, "max_queue_dance": 0}

var _step_min := 0.0
var _dt := 0.0
var _spawned := 0
var _next_order := 1
var _reach: Dictionary = {}
var _gap_min := 0.0


## config: {guests, seed, duration_min?, staff: [{role, speed}]}
func setup(p_state, config: Dictionary):
	state = p_state
	cfg = state.data.tuning["sim"]
	var seed_value := int(config.get("seed", 1))
	rng_persona.seed = seed_value
	rng_decide.seed = seed_value + 1
	guest_total = int(config["guests"])
	_dt = float(cfg["step_s"])
	_step_min = _dt * float(cfg["game_min_per_real_s"])
	_gap_min = float(cfg["arrival_gap_min"])
	total_steps = int(ceil(float(config.get("duration_min", cfg["default_duration_min"])) / _step_min))
	_reach = Nav.reachable_from_entrance(state)
	_build_stations()
	for s in config.get("staff", []):
		if s["role"] == "waiter":
			var w := Waiter.new()
			w.id = waiters.size() + 1
			w.speed = float(s.get("speed", 1.0))
			w.place_at(state.venue.entrance)
			waiters.append(w)
		elif s["role"] == "cook":
			cooks += 1
	state.event_active = true
	return self


func minute() -> float:
	return step_count * _step_min


func run_to_end() -> void:
	while not finished:
		step()


func step() -> void:
	if finished:
		return
	_spawn()
	_update_needs()
	_decide()
	_act()
	_update_queues()
	_update_kitchen()
	_update_waiters()
	_accumulate_satisfaction()
	step_count += 1
	if step_count >= total_steps:
		_finish()


func result() -> Dictionary:
	var sum := 0.0
	for g in guests:
		var steps: int = maxi(g.sat_steps, 1)
		var s: float = g.sat_acc / steps / 100.0
		if g.abandoned:
			s -= float(cfg["abandon_penalty"])
		sum += clampf(s, 0.0, 1.0)
	var waits: Array = metrics["order_waits_s"]
	var avg_wait := 0.0
	for w in waits:
		avg_wait += w
	if not waits.is_empty():
		avg_wait /= waits.size()
	return {
		"guests": guests.size(),
		"guest_sat": sum / maxf(guests.size(), 1),
		"abandon_count": metrics["abandon_count"],
		"meals": metrics["meals"], "dances": metrics["dances"], "wc_uses": metrics["wc_uses"],
		"avg_order_wait_s": avg_wait,
		"max_queue_wc": metrics["max_queue_wc"], "max_queue_dance": metrics["max_queue_dance"],
		"log": event_log,
	}


# --- kurulum ---------------------------------------------------------------

func _build_stations() -> void:
	var venue = state.venue
	var ids: Array = venue.items.keys()
	ids.sort()
	for id in ids:
		var item: Dictionary = venue.items[id]
		var def: Dictionary = state.data.defs[item["def"]]
		if def.get("music", false):
			music_on = true
		if def["station"] == null:
			continue
		var kind: String = def["station"]["kind"]
		if not ["seat", "dance", "wc", "serve"].has(kind):
			continue
		var cells: Array[Vector2i] = []
		if kind == "seat" or kind == "dance":
			for c in item["cells"]:
				if _reach.has(c):
					cells.append(c)
		else:
			var access := _access_cell(item)
			if access.x >= 0:
				cells.append(access)
		if cells.is_empty():
			continue
		var use_s := 0.0
		if kind == "dance":
			use_s = float(cfg["dance_time_s"])
		elif kind == "wc":
			use_s = float(cfg["wc_time_s"])
		stations.append({"item_id": id, "kind": kind, "slots": int(def["station"]["slots"]),
				"use_s": use_s, "occupants": [], "queue": [], "cells": cells})


func _access_cell(item: Dictionary) -> Vector2i:
	var venue = state.venue
	for c in item["cells"]:
		for d in Nav.DIRS:
			var nb: Vector2i = c + d
			if _reach.has(nb) and not venue.has_wall_between(c, nb) and venue.occupant(nb) != item["id"]:
				return nb
	return Vector2i(-1, -1)


# --- adım parçaları --------------------------------------------------------

func _spawn() -> void:
	while _spawned < guest_total and minute() >= _spawned * _gap_min:
		var g := Guest.new()
		g.id = _spawned + 1
		g.place_at(state.venue.entrance)
		g.hunger = rng_persona.randf_range(0.0, 25.0)
		g.fun = rng_persona.randf_range(0.0, 25.0)
		g.bladder = rng_persona.randf_range(0.0, 20.0)
		for k in g.persona:
			g.persona[k] = rng_persona.randf_range(float(cfg["persona_min"]), float(cfg["persona_max"]))
		guests.append(g)
		_spawned += 1


func _update_needs() -> void:
	var fun_rate: float = float(cfg["fun_rate_music"]) if music_on else float(cfg["fun_rate_silent"])
	for g in guests:
		if g.state == G.GONE:
			continue
		g.hunger = minf(100.0, g.hunger + float(cfg["hunger_rate"]) * g.persona["hunger"] * _step_min)
		g.fun = minf(100.0, g.fun + fun_rate * g.persona["fun"] * _step_min)
		g.bladder = minf(100.0, g.bladder + float(cfg["bladder_rate"]) * g.persona["bladder"] * _step_min)
		var waiting: bool = g.state == G.QUEUEING or (g.state == G.SEATED and g.order_id > 0) \
				or (g.state == G.DECIDING and g.no_seat)
		if waiting:
			g.patience -= float(cfg["patience_drain"]) * g.persona["patience"] * _step_min
			if g.patience <= 0.0:
				_abandon(g)


func _decide() -> void:
	var period := int(cfg["decision_period_steps"])
	for g in guests:
		if (g.state != G.DECIDING and g.state != G.SEATED) or g.id % period != step_count % period:
			continue
		_decide_one(g)


func _decide_one(g) -> void:
	var thr := float(cfg["need_threshold"])
	if g.state == G.SEATED:
		if g.order_id > 0:
			return
		if g.hunger >= thr:
			_place_order(g)
			return
	var best := -1
	var best_u := 0.0
	var wants_seat: bool = g.hunger >= thr and g.seat_station < 0 # koltuk hiç yoksa da sabır erir
	for si in stations.size():
		var st: Dictionary = stations[si]
		if g.bad_stations.has(si):
			continue
		var need := 0.0
		match st["kind"]:
			"seat":
				if g.seat_station >= 0:
					continue
				need = maxf(g.hunger, float(cfg["seek_seat_need"])) # gelen misafir önce oturmak ister
				if st["occupants"].size() >= st["slots"]:
					continue
			"dance":
				need = g.fun
			"wc":
				need = g.bladder
			_:
				continue
		if need < thr:
			continue
		var dist: int = absi(g.cell.x - st["cells"][0].x) + absi(g.cell.y - st["cells"][0].y)
		var crowd: float = 1.0 / (1.0 + float(st["queue"].size()) / float(st["slots"]))
		var u: float = pow(need / 100.0, 2.0) / (1.0 + dist / float(cfg["distance_d0_cells"])) * crowd \
				+ rng_decide.randf() * float(cfg["decision_noise"])
		if best < 0 or u > best_u:
			best = si
			best_u = u
	g.no_seat = wants_seat and g.seat_station < 0 and (best < 0 or stations[best]["kind"] != "seat") \
			and _no_free_seat()
	if g.no_seat and not g.no_seat_logged:
		g.no_seat_logged = true
		_log(g, "NO_SEAT", g.cell)
	if best < 0:
		return
	_go_to(g, best)


func _no_free_seat() -> bool:
	for st in stations:
		if st["kind"] == "seat" and st["occupants"].size() < st["slots"]:
			return false
	return true


func _go_to(g, si: int) -> void:
	var st: Dictionary = stations[si]
	var target: Vector2i = st["cells"][g.id % st["cells"].size()] if st["kind"] == "dance" else st["cells"][0]
	var route := AStar.find_path(state, g.cell, target)
	if route.is_empty() and g.cell != target:
		g.bad_stations.append(si)
		_log(g, "NO_PATH", target)
		return
	if g.state == G.SEATED:
		_release(g)
	g.path = route
	g.station = si
	g.state = G.MOVING
	if st["kind"] == "seat":
		st["occupants"].append(g.id) # koltuk gidilirken rezerve edilir
		g.no_seat = false
		g.seat_station = si


func _place_order(g) -> void:
	orders[_next_order] = {"guest": g.id, "placed_step": step_count, "state": "PLACED",
			"cook": "QUEUED", "cook_left": 0.0}
	g.order_id = _next_order
	_next_order += 1


func _act() -> void:
	var walk := float(cfg["walk_cells_per_s"])
	for g in guests:
		match g.state:
			G.MOVING:
				if g.advance(walk, _dt):
					_arrive(g)
			G.USING:
				g.timer -= _dt
				if g.timer <= 0.0:
					_finish_use(g)
			G.EATING:
				g.timer -= _dt
				if g.timer <= 0.0:
					g.hunger = maxf(0.0, g.hunger - float(cfg["eat_relief"]))
					g.patience = minf(100.0, g.patience + float(cfg["patience_relief"]))
					g.order_id = 0
					g.state = G.SEATED
					metrics["meals"] += 1
			G.LEAVING:
				if g.advance(walk, _dt):
					g.state = G.GONE


func _arrive(g) -> void:
	var st: Dictionary = stations[g.station]
	if st["kind"] == "seat":
		g.state = G.SEATED
		return
	if st["occupants"].size() < st["slots"]:
		st["occupants"].append(g.id)
		g.state = G.USING
		g.timer = st["use_s"]
	else:
		st["queue"].append(g.id)
		g.state = G.QUEUEING


func _finish_use(g) -> void:
	var st: Dictionary = stations[g.station]
	if st["kind"] == "dance":
		g.fun = maxf(0.0, g.fun - float(cfg["dance_relief"]))
		metrics["dances"] += 1
	else:
		g.bladder = maxf(0.0, g.bladder - float(cfg["wc_relief"]))
		metrics["wc_uses"] += 1
	st["occupants"].erase(g.id)
	g.station = -1
	g.state = G.DECIDING


func _update_queues() -> void:
	for st in stations:
		var k: String = st["kind"]
		if k != "dance" and k != "wc":
			continue
		while st["occupants"].size() < st["slots"] and not st["queue"].is_empty():
			var g = guests[st["queue"].pop_front() - 1]
			st["occupants"].append(g.id)
			g.state = G.USING
			g.timer = st["use_s"]
		var key := "max_queue_wc" if k == "wc" else "max_queue_dance"
		metrics[key] = maxi(metrics[key], st["queue"].size())


func _update_waiters() -> void:
	for w in waiters:
		if w.state != Waiter.State.IDLE and not orders.has(w.order_id):
			w.state = Waiter.State.IDLE
			w.order_id = 0
		match w.state:
			Waiter.State.IDLE:
				_waiter_take_order(w)
			Waiter.State.TO_PICKUP:
				if w.advance(float(cfg["waiter_cells_per_s"]) * w.speed, _dt):
					w.state = Waiter.State.PICKING
					w.timer = float(cfg["pickup_time_s"])
			Waiter.State.PICKING: # yemek hazır değilse servis masasında bekler
				if orders[w.order_id]["cook"] == "DONE":
					w.timer -= _dt
					if w.timer <= 0.0:
						_waiter_start_delivery(w)
			Waiter.State.TO_DELIVER:
				if w.advance(float(cfg["waiter_cells_per_s"]) * w.speed, _dt):
					_deliver(w)


## Siparişler geliş sırasıyla pişer. Her aşçı birkaç tabağı paralel hazırlar;
## aşçı yoksa tek tezgâhta çok yavaş (docs/04 §5).
func _update_kitchen() -> void:
	var slots: int = cooks * int(cfg["prep_slots_per_cook"]) if cooks > 0 else 1
	var prep: float = float(cfg["prep_time_cook_s"]) if cooks > 0 else float(cfg["prep_time_no_cook_s"])
	var busy := 0
	for id in orders:
		var o: Dictionary = orders[id]
		if o["cook"] == "COOKING":
			o["cook_left"] -= _dt
			if o["cook_left"] <= 0.0:
				o["cook"] = "DONE"
			else:
				busy += 1
	for id in orders:
		if busy >= slots:
			break
		var o: Dictionary = orders[id]
		if o["cook"] == "QUEUED":
			o["cook"] = "COOKING"
			o["cook_left"] = prep
			busy += 1


func _waiter_take_order(w) -> void:
	var oid := 0
	for id in orders:
		if orders[id]["state"] == "PLACED" and (oid == 0 or id < oid):
			oid = id
	if oid == 0:
		return
	var serve := _nearest_serve(w.cell)
	if serve < 0:
		return # servis masası yok: sipariş beklemede kalır, misafir sabrı biter
	var target: Vector2i = stations[serve]["cells"][0]
	var route := AStar.find_path(state, w.cell, target)
	if route.is_empty() and w.cell != target:
		orders[oid]["state"] = "BLOCKED"
		_log(guests[orders[oid]["guest"] - 1], "NO_PATH", target)
		return
	orders[oid]["state"] = "TAKEN"
	w.order_id = oid
	w.path = route
	w.state = Waiter.State.TO_PICKUP


func _nearest_serve(from: Vector2i) -> int:
	var best := -1
	var best_d := 1 << 30
	for si in stations.size():
		if stations[si]["kind"] != "serve":
			continue
		var c: Vector2i = stations[si]["cells"][0]
		var d: int = absi(from.x - c.x) + absi(from.y - c.y)
		if d < best_d:
			best_d = d
			best = si
	return best


func _waiter_start_delivery(w) -> void:
	var order: Dictionary = orders[w.order_id]
	order["state"] = "READY"
	var g = guests[order["guest"] - 1]
	var route := AStar.find_path(state, w.cell, g.cell)
	if route.is_empty() and w.cell != g.cell:
		order["state"] = "BLOCKED"
		_log(g, "NO_PATH", g.cell)
		w.state = Waiter.State.IDLE
		w.order_id = 0
		return
	w.path = route
	w.state = Waiter.State.TO_DELIVER
	if route.is_empty():
		_deliver(w)


func _deliver(w) -> void:
	var order: Dictionary = orders[w.order_id]
	var g = guests[order["guest"] - 1]
	if g.state == G.SEATED and g.order_id == w.order_id:
		g.state = G.EATING
		g.timer = float(cfg["eat_time_s"])
		metrics["order_waits_s"].append((step_count - order["placed_step"]) * _dt)
		orders.erase(w.order_id)
	w.state = Waiter.State.IDLE
	w.order_id = 0


func _accumulate_satisfaction() -> void:
	for g in guests:
		if g.state == G.GONE or g.state == G.LEAVING:
			continue
		g.sat_acc += _satisfaction(g)
		g.sat_steps += 1


func _satisfaction(g) -> float:
	var tol := float(cfg["sat_tolerance"])
	var e := float(cfg["sat_exponent"])
	var pen := pow(maxf(0.0, g.hunger - tol), e) + pow(maxf(0.0, g.fun - tol), e) \
			+ pow(maxf(0.0, g.bladder - tol), e) + pow(maxf(0.0, (100.0 - g.patience) - tol), e)
	return clampf(100.0 - float(cfg["sat_k"]) * pen, 0.0, 100.0)


# --- ayrılma ---------------------------------------------------------------

func _abandon(g) -> void:
	var kind := "NO_SEAT"
	if g.state == G.QUEUEING:
		kind = "QUEUE_ABANDON"
	elif g.state == G.SEATED:
		kind = "ORDER_LATE"
	_log(g, kind, g.cell)
	g.abandoned = true
	metrics["abandon_count"] += 1
	_release(g)
	g.path = AStar.find_path(state, g.cell, state.venue.entrance)
	g.state = G.LEAVING if not g.path.is_empty() else G.GONE


func _release(g) -> void:
	for si in [g.station, g.seat_station]:
		if si >= 0:
			stations[si]["occupants"].erase(g.id)
			stations[si]["queue"].erase(g.id)
	g.station = -1
	g.seat_station = -1
	if g.order_id > 0:
		orders.erase(g.order_id)
		g.order_id = 0


func _log(g, kind: String, where: Vector2i) -> void:
	event_log.append({"minute": minute(), "guest": g.id, "kind": kind, "where": where})


func _finish() -> void:
	finished = true
	state.event_active = false
