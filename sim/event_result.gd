extends RefCounted
## Etkinlik sonucu: beklenti eşleşmesi, yıldız, gelir/gider, itibar (docs/06 §3-7).

const Stats := preload("res://sim/venue_stats.gd")


## contract: {event_type, agreed_price, expectations?}; staff: etkinlikte çalışanlar [{role, speed}]
static func compute(state, run, contract: Dictionary, staff: Array) -> Dictionary:
	var eco: Dictionary = state.data.tuning["economy"]
	var type: Dictionary = state.data.event_types[contract["event_type"]]
	var run_res: Dictionary = run.result()
	var n: int = run_res["guests"]

	var achieved := Stats.estimate(state, n, staff)
	var expect: Dictionary = type["base_expect"].duplicate()
	for k in contract.get("expectations", {}):
		expect[k] = contract["expectations"][k]
	var match_score := _match(achieved, expect, type["weights"], float(eco["match_span"]))

	var guest_sat: float = run_res["guest_sat"]
	var incident_pen := minf(float(eco["incident_pen_max"]),
			float(eco["incident_pen_per_abandon"]) * run_res["abandon_count"])
	var final_score: float = float(eco["match_weight"]) * match_score + float(eco["sat_weight"]) * guest_sat - incident_pen
	var stars := clampi(roundi(1.0 + 4.0 * final_score), 1, 5)

	var hours: float = float(type["hours"])
	var income: Array = [{"kind": "contract", "amount": int(contract["agreed_price"])}]
	if eco["low_star_discount"].has(str(stars)):
		income.append({"kind": "low_star_discount",
				"amount": -int(int(contract["agreed_price"]) * float(eco["low_star_discount"][str(stars)]))})
	var expenses: Array = [
		{"kind": "catering", "amount": n * int(type["head_cost"])},
		{"kind": "staff", "amount": _staff_cost(eco, staff, hours)},
		{"kind": "electricity", "amount": _electricity(state, eco, hours)},
	]
	var total_in := 0
	for e in income:
		total_in += e["amount"]
	var total_out := 0
	for e in expenses:
		total_out += e["amount"]

	var size_factor := clampf(n / float(eco["guests_size_ref"]), float(eco["guests_size_min"]), float(eco["guests_size_max"]))
	var rep_delta := roundi((stars - 3) * float(eco["rep_per_star"]) * size_factor)
	if stars <= 2:
		rep_delta -= int(eco["low_star_extra_rep"])

	return {
		"event_type": contract["event_type"], "guests": n,
		"achieved": achieved, "expected": expect,
		"match": match_score, "guest_sat": guest_sat, "incident_pen": incident_pen,
		"final": final_score, "stars": stars,
		"income": income, "expenses": expenses,
		"total_income": total_in, "total_expenses": total_out, "net": total_in - total_out,
		"reputation_delta": rep_delta,
		"issues": _issues(achieved, expect, type["weights"], run_res["log"]),
		"abandon_count": run_res["abandon_count"],
	}


## Kasa ve itibarı günceller.
static func apply(state, result: Dictionary) -> void:
	state.cash += result["net"]
	var cap := int(state.data.tuning["economy"]["rep_max"])
	state.reputation = clampi(state.reputation + result["reputation_delta"], 0, cap)


static func _match(achieved: Dictionary, expect: Dictionary, weights: Dictionary, span: float) -> float:
	var num := 0.0
	var den := 0.0
	for k in Stats.KEYS:
		var m := clampf(0.5 + (achieved[k] - float(expect[k])) / span, 0.0, 1.0)
		num += float(weights[k]) * m
		den += float(weights[k])
	return num / den


static func _staff_cost(eco: Dictionary, staff: Array, hours: float) -> int:
	var total := 0.0
	for s in staff:
		total += float(eco["wages_per_hour"].get(s["role"], 0)) * (hours + float(eco["setup_hours"]))
	return int(total)


static func _electricity(state, eco: Dictionary, hours: float) -> int:
	var units := 0
	for id in state.venue.items:
		units += int(state.data.defs[state.venue.items[id]["def"]]["power"])
	return int(units * hours * float(eco["electricity_per_unit_hour"]))


## Sonuç ekranının "en büyük sorun" listesi: ağırlıklı değer açığı + en sık şikâyet.
static func _issues(achieved: Dictionary, expect: Dictionary, weights: Dictionary, log: Array) -> Array:
	var out: Array = []
	for k in Stats.KEYS:
		var gap: float = float(expect[k]) - achieved[k]
		if gap > 0.0:
			out.append({"kind": "stat", "key": k, "gap": gap * float(weights[k])})
	var counts := {}
	for e in log:
		counts[e["kind"]] = counts.get(e["kind"], 0) + 1
	for kind in counts:
		out.append({"kind": "log", "key": kind, "count": counts[kind], "gap": float(counts[kind]) * 10.0})
	out.sort_custom(func(a, b): return a["gap"] > b["gap"])
	return out
