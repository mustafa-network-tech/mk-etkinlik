extends "res://tests/test_case.gd"

const EventRun := preload("res://sim/event_run.gd")
const Result := preload("res://sim/event_result.gd")
const Customers := preload("res://sim/customers.gd")
const SaveGame := preload("res://sim/save_game.gd")


func _staff(waiters: int) -> Array:
	var out := []
	for i in waiters:
		out.append({"role": "waiter", "speed": 1.0})
	return out


## Dengeli: koltuk, masa, servis, WC, pist+DJ. Zayıf: yalnız birkaç koltuk.
func _venue(strong: bool):
	var s = new_state()
	s.cash = 1000000
	s.level = 5
	for i in (65 if strong else 10):
		place(s, "chair_basic", 2 + i % 30, 2 + i / 30)
	if strong:
		for i in 4:
			place(s, "table_round_8", 3 + i * 4, 20)
		place(s, "service_table", 3, 8)
		place(s, "wc_basic", 30, 10)
		place(s, "wc_basic", 33, 10)
		place(s, "dance_floor", 20, 12)
		place(s, "dj_basic", 25, 12)
		place(s, "speaker_pro", 5, 15)
		place(s, "speaker_pro", 6, 15)
	return s


func _run(s, staff: Array, guests: int, type_id: String = "engagement") -> Dictionary:
	var r = EventRun.new().setup(s, {"guests": guests, "seed": 3, "staff": staff})
	r.run_to_end()
	return Result.compute(s, r, {"event_type": type_id, "agreed_price": 46000}, staff)


func test_better_venue_earns_more_stars_than_weak_one() -> void:
	var good := _run(_venue(true), _staff(3), 65)
	var weak := _run(_venue(false), _staff(1), 65)
	check(good["stars"] > weak["stars"], "güçlü mekân daha çok yıldız alır (%d > %d)" % [good["stars"], weak["stars"]])
	check(good["match"] > weak["match"], "beklenti eşleşmesi yüksek")
	check(good["reputation_delta"] > weak["reputation_delta"], "itibar farkı")


func test_decor_only_without_staff_is_punished() -> void:
	var s = new_state()
	s.cash = 1000000
	s.level = 5
	for i in 6:
		place(s, "speaker_pro", 5 + i, 3)
	var res := _run(s, [], 40)
	check(res["stars"] <= 2, "personelsiz dekor ≤2 yıldız")
	check(res["reputation_delta"] < 0, "itibar düşer")
	var discounted := false
	for e in res["income"]:
		if e["kind"] == "low_star_discount":
			discounted = true
	check(discounted, "düşük yıldızda indirim uygulanır")
	eq(res["achieved"]["service"], 0.0, "servis 0")


func test_ledger_adds_up_and_apply_updates_state() -> void:
	var s = _venue(true)
	var staff := _staff(3)
	var res := _run(s, staff, 65)
	var tin := 0
	for e in res["income"]:
		tin += e["amount"]
	var tout := 0
	for e in res["expenses"]:
		tout += e["amount"]
	eq(res["net"], tin - tout, "net = gelir - gider")
	eq(res["expenses"][0]["amount"], 65 * 190, "catering = kişi × baş maliyeti")
	eq(res["expenses"][1]["amount"], 3 * 280 * 5, "personel = saat ücreti × (4 saat + 1 hazırlık)")
	var cash0: int = s.cash
	Result.apply(s, res)
	eq(s.cash, cash0 + res["net"], "kasa güncellenir")
	eq(s.reputation, clampi(res["reputation_delta"], 0, 1000), "itibar 0..1000 aralığında")


func test_reputation_tiers_and_save_roundtrip() -> void:
	var s = new_state()
	eq(s.tier(), 0, "başlangıç: mahalle salonu")
	s.reputation = 300
	eq(s.tier(), 1, "300: popüler mekân")
	s.reputation = 700
	eq(s.tier(), 2, "700: prestijli")
	var path := "user://test_rep.json"
	SaveGame.write(s, path)
	var loaded = SaveGame.read(s.data, path)["state"]
	eq(loaded.reputation, 700, "itibar kayıttan döner")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func test_event_types_cover_five_values() -> void:
	var s = new_state()
	eq(s.data.event_types.size(), 5, "5 etkinlik türü")
	for id in s.data.event_types:
		for k in ["prestige", "comfort", "fun", "service", "safety"]:
			check(s.data.event_types[id]["weights"].has(k) and s.data.event_types[id]["base_expect"].has(k), id + "/" + k)


func test_generated_requests_are_valid_and_deterministic() -> void:
	var s = new_state()
	var a := RandomNumberGenerator.new()
	a.seed = 5
	var b := RandomNumberGenerator.new()
	b.seed = 5
	for i in 20:
		var ra := Customers.generate_request(s, a, 1)
		var rb := Customers.generate_request(s, b, 1)
		eq(ra, rb, "aynı tohum aynı talep")
		var type: Dictionary = s.data.event_types[ra["event_type"]]
		check(ra["guests"] >= type["guests"][0] and ra["guests"] <= type["guests"][1], "misafir sayısı aralıkta")
		check(ra["budget"] > 0 and ra["expectations"].size() == 2, "bütçe ve 2 beklenti")


func test_higher_tier_asks_for_more() -> void:
	var low = new_state()
	var high = new_state()
	high.reputation = 800
	var r1 := RandomNumberGenerator.new()
	r1.seed = 9
	var r2 := RandomNumberGenerator.new()
	r2.seed = 9
	var a := Customers.generate_request(low, r1, 1)
	var b := Customers.generate_request(high, r2, 1)
	check(b["budget"] > a["budget"], "yüksek basamakta bütçe artar")
	for k in a["expectations"]:
		check(b["expectations"][k] > a["expectations"][k], "beklenti artar: " + k)


func test_offer_acceptance_probability_behaves() -> void:
	var s = new_state()
	var req := {"budget": 48000, "frugality": 0.5, "pickiness": 0.5}
	var wtp := Customers.willing_to_pay(req)
	check(absf(Customers.accept_probability(s, req, int(wtp)) - 0.5) < 0.01, "WTP'de ~%50")
	check(Customers.accept_probability(s, req, int(wtp * 0.85)) > 0.95, "ucuz teklif neredeyse kesin kabul")
	check(Customers.accept_probability(s, req, int(wtp * 1.15)) < 0.05, "pahalı teklif neredeyse kesin ret")
	var p1 := Customers.accept_probability(s, req, 42000)
	var p2 := Customers.accept_probability(s, req, 46000)
	check(p1 > p2, "fiyat arttıkça kabul olasılığı düşer")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var accepted := 0
	for i in 200:
		if Customers.decide(s, req, int(wtp), rng):
			accepted += 1
	check(accepted > 70 and accepted < 130, "WTP'de ~yarısı kabul eder (%d/200)" % accepted)
