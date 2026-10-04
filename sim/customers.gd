extends RefCounted
## Müşteri talebi üretimi ve teklif kabulü (docs/06 §6).


static func generate_request(state, rng: RandomNumberGenerator, day: int) -> Dictionary:
	var eco: Dictionary = state.data.tuning["economy"]
	var types: Array = state.data.event_types.keys()
	types.sort()
	var type_id: String = types[rng.randi() % types.size()]
	var type: Dictionary = state.data.event_types[type_id]
	var tier: int = state.tier()
	var guests := rng.randi_range(int(type["guests"][0]), int(type["guests"][1]))
	var per_guest := rng.randf_range(float(type["budget_per_guest"][0]), float(type["budget_per_guest"][1]))
	var budget := int(round(guests * per_guest * (1.0 + float(eco["budget_tier_gain"]) * tier) / 100.0)) * 100
	# Beklenti: türün en ağırlıklı iki değeri, basamakla yükselir.
	var keys: Array = type["weights"].keys()
	keys.sort_custom(func(a, b): return type["weights"][a] > type["weights"][b] or (type["weights"][a] == type["weights"][b] and a < b))
	var expectations := {}
	for k in keys.slice(0, 2):
		expectations[k] = float(type["base_expect"][k]) + float(eco["expect_tier_gain"]) * tier + rng.randf_range(0.0, 10.0)
	var names: Array = state.data.names
	var a: String = names[rng.randi() % names.size()]
	var b: String = names[rng.randi() % names.size()]
	return {
		"name": "%s & %s" % [a, b], "event_type": type_id, "guests": guests, "budget": budget,
		"expectations": expectations, "date_day": day + rng.randi_range(3, 10),
		"frugality": rng.randf(), "pickiness": rng.randf(),
	}


static func willing_to_pay(req: Dictionary) -> float:
	return float(req["budget"]) * (1.0 + 0.15 * (1.0 - req["frugality"]) - 0.10 * req["pickiness"])


static func accept_probability(state, req: Dictionary, offer: int) -> float:
	var slope: float = float(state.data.tuning["economy"]["haggle_slope"]) * float(req["budget"])
	return 1.0 / (1.0 + exp((float(offer) - willing_to_pay(req)) / slope))


static func decide(state, req: Dictionary, offer: int, rng: RandomNumberGenerator) -> bool:
	return rng.randf() < accept_probability(state, req, offer)
