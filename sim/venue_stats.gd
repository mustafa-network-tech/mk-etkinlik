extends RefCounted
## Beş değerin statik tahmini (docs/06-ECONOMY.md §1-2). Yapı modunda canlı gösterilir.

const Nav := preload("res://sim/nav.gd")

const KEYS := ["prestige", "comfort", "fun", "service", "safety"]


## staff: [{role, speed}] — waiter, cook ve security okunur.
static func estimate(state, guests: int, staff: Array = []) -> Dictionary:
	var t: Dictionary = state.data.tuning
	var st: Dictionary = t["stats"]
	var raw := _raw_sums(state)
	var caps := _capacities(state)
	var crowd := _crowd_penalty(state, guests)

	var seat_ratio := _ratio(caps["seats"], guests)
	var wc_ratio := _ratio(caps["wc_slots"], guests / float(st["guests_per_wc_slot"]))
	var dance_ratio := _ratio(caps["dance_slots"], guests * float(st["dancers_ratio"]))
	var waiters := 0.0
	var cooks := 0.0
	var security := 0
	for s in staff:
		if s["role"] == "waiter":
			waiters += float(s.get("speed", 1.0))
		elif s["role"] == "cook":
			cooks += float(s.get("speed", 1.0))
		elif s["role"] == "security":
			security += 1
	# Servis hızı garson ile mutfaktan yavaş olanıdır; aşçısız mutfak çok yavaş (docs/04 §5).
	var kitchen: float = cooks * float(st["service_per_cook"]) if cooks > 0.0 else float(st["kitchen_service_no_cook"])
	var service_ratio := _ratio(minf(waiters * float(st["service_per_waiter"]), kitchen),
			guests * float(st["service_demand_per_guest"]))

	var eff := {
		"prestige": raw["prestige"],
		"comfort": raw["comfort"] * seat_ratio * wc_ratio * (1.0 - crowd),
		"fun": raw["fun"] * dance_ratio,
		"service": (raw["service"] + waiters * float(st["waiter_service_points"])) * service_ratio,
		"safety": maxf(0.0, raw["safety"] + float(st["exit_bonus"]) + security * float(st["security_bonus"])) * (1.0 - crowd),
	}
	var out := {}
	for k in KEYS:
		out[k] = 100.0 * (1.0 - exp(-eff[k] / float(st["scale"][k])))
	return out


## Ham toplam: aynı türün j. kopyası stack_decay^j ile, durabiliteyle çarpılır.
static func _raw_sums(state) -> Dictionary:
	var raw := {}
	for k in KEYS:
		raw[k] = 0.0
	var by_def := {}
	var ids: Array = state.venue.items.keys()
	ids.sort()
	for id in ids:
		var item: Dictionary = state.venue.items[id]
		var def: Dictionary = state.data.defs[item["def"]]
		var n: int = by_def.get(item["def"], 0)
		by_def[item["def"]] = n + 1
		var decay: float = float(def.get("stack_decay", state.data.tuning["default_stack_decay"]))
		var w: float = pow(decay, n) * float(item["cond"])
		for k in KEYS:
			raw[k] += float(def["stats"][k]) * w
	return raw


static func _capacities(state) -> Dictionary:
	var caps := {"seats": 0, "wc_slots": 0, "dance_slots": 0}
	for id in state.venue.items:
		var c: Dictionary = state.data.defs[state.venue.items[id]["def"]]["capacity"]
		for k in caps:
			caps[k] += int(c.get(k, 0))
	return caps


## Kişi başı kullanılabilir alan 1.2 m²'nin altına inince ceza.
static func _crowd_penalty(state, guests: int) -> float:
	if guests <= 0:
		return 0.0
	var st: Dictionary = state.data.tuning["stats"]
	var free_cells := 0
	for y in state.venue.height:
		for x in state.venue.width:
			if Nav.is_passable(state, Vector2i(x, y)):
				free_cells += 1
	var per_guest: float = free_cells * float(st["cell_area_m2"]) / guests
	var p: float = (float(st["min_area_per_guest_m2"]) - per_guest) * float(st["crowd_penalty_slope"])
	return clampf(p, 0.0, float(st["crowd_penalty_max"]))


static func _ratio(have: float, need: float) -> float:
	if need <= 0.0:
		return 1.0
	return minf(1.0, have / need)
