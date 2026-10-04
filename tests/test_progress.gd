extends "res://tests/test_case.gd"
## Başlangıç koşullarında oynanabilirlik, XP/seviye, kira/borç/iflas (docs/06 §7-9).

const EventRun := preload("res://sim/event_run.gd")
const Result := preload("res://sim/event_result.gd")
const Session := preload("res://sim/session.gd")

const STAFF := [{"role": "waiter", "speed": 1.0}, {"role": "waiter", "speed": 1.0}, {"role": "cook", "speed": 1.0}]


## Başlangıç kasası ve seviyesiyle alınabilen dengeli düzen (50 misafir). Her yerleştirme başarılı olmalı.
func _starter_venue():
	var s = new_state()
	var ok := true
	for i in 50:
		ok = place(s, "chair_basic", 4 + i % 25, 3 + (i / 25) * 2)["ok"] and ok
	ok = place(s, "table_round_8", 5, 7)["ok"] and ok
	ok = place(s, "service_table", 3, 10)["ok"] and ok
	ok = place(s, "wc_basic", 34, 2)["ok"] and ok
	ok = place(s, "wc_basic", 34, 20)["ok"] and ok
	ok = place(s, "dance_floor", 20, 14)["ok"] and ok
	ok = place(s, "dance_floor", 24, 14)["ok"] and ok
	ok = place(s, "dj_basic", 21, 19)["ok"] and ok
	for i in 3:
		ok = place(s, "flower_stand", 1 + i, 1)["ok"] and ok
	check(ok, "başlangıç düzeni başlangıç kasası ve seviyesiyle alınabilir")
	return s


## Türün taban beklentisi; en ağır iki değer ortalama rastgele payla (+5) yükseltilir (customers.gd).
func _contract(s, type_id: String) -> Dictionary:
	var type: Dictionary = s.data.event_types[type_id]
	var keys: Array = type["weights"].keys()
	keys.sort_custom(func(a, b): return type["weights"][a] > type["weights"][b] or (type["weights"][a] == type["weights"][b] and a < b))
	var ex := {}
	for k in keys.slice(0, 2):
		ex[k] = float(type["base_expect"][k]) + 5.0
	var per_guest: float = (float(type["budget_per_guest"][0]) + float(type["budget_per_guest"][1])) / 2.0
	return {"event_type": type_id, "agreed_price": int(50 * per_guest), "expectations": ex}


func test_starter_layout_earns_three_stars_for_every_event_type() -> void:
	eq(new_state().cash, 60000, "başlangıç kasası")
	eq(new_state().level, 1, "başlangıç seviyesi")
	# Simülasyon etkinlik türüne bakmaz: bir kez koşup her türün sözleşmesiyle değerlendiririz.
	var s = _starter_venue()
	var r = EventRun.new().setup(s, {"guests": 50, "seed": 5, "staff": STAFF})
	r.run_to_end()
	for type_id in s.data.event_types:
		var res := Result.compute(s, r, _contract(s, type_id), STAFF)
		check(res["stars"] >= 3, "%s: başlangıç düzeni en az 3 yıldız (%d)" % [type_id, res["stars"]])
		check(res["net"] > 0, "%s: başlangıç düzeni kâr eder (%d)" % [type_id, res["net"]])


func _fake_result(net: int, xp_gain: int = 0) -> Dictionary:
	return {"net": net, "reputation_delta": 0, "xp_gain": xp_gain}


func test_xp_levels_up_and_unlocks_items() -> void:
	var s = new_state()
	eq(s.xp_to_next(), 100, "1→2 için 100 XP")
	Result.apply(s, _fake_result(0, 130))
	eq(s.level, 2, "seviye atlandı")
	eq(s.xp, 30, "artan XP sonraki seviyeye kalır")
	eq(s.xp_to_next(), 135, "eşik ×1.35 büyür")
	s.cash = 1000000
	eq(place(s, "speaker_pro", 5, 5)["error"], "locked", "seviye 2'de hoparlör kilitli")
	var res := _fake_result(0, 2000)
	Result.apply(s, res)
	check(s.level >= 5, "çok XP birden çok seviye atlatır (%d)" % s.level)
	eq(res["levels_gained"], s.level - 2, "kazanılan seviye sayısı sonuçta")
	check(place(s, "speaker_pro", 5, 5)["ok"], "seviye 5'te profesyonel hoparlör açılır")


func test_real_event_gives_xp_by_formula() -> void:
	var s = _starter_venue()
	var r = EventRun.new().setup(s, {"guests": 50, "seed": 5, "staff": STAFF})
	r.run_to_end()
	var res := Result.compute(s, r, _contract(s, "engagement"), STAFF)
	eq(res["xp_gain"], int(res["stars"] * 10 + 50 / 5.0 + maxf(0.0, res["net"]) / 1000.0), "XP = yıldız·10 + misafir/5 + net/1000")


func _expense(res: Dictionary, kind: String) -> int:
	for e in res["expenses"]:
		if e["kind"] == kind:
			return e["amount"]
	return -1


func test_rent_always_and_interest_only_when_in_debt() -> void:
	var s = _starter_venue()
	var r = EventRun.new().setup(s, {"guests": 10, "seed": 1, "staff": STAFF})
	r.run_to_end()
	var res := Result.compute(s, r, _contract(s, "engagement"), STAFF)
	eq(_expense(res, "rent"), 600, "günlük kira")
	eq(_expense(res, "interest"), -1, "borç yokken faiz yok")
	s.cash = -10000
	res = Result.compute(s, r, _contract(s, "engagement"), STAFF)
	eq(_expense(res, "interest"), 200, "10.000 TL borca %2 günlük faiz")


func test_debt_blocks_buying_and_closes_business_after_seven_bad_days() -> void:
	var s = new_state()
	s.cash = -500
	eq(place(s, "chair_basic", 5, 5)["error"], "not_enough_cash", "borçluyken satın alma yok")
	s.cash = -150000
	check(s.over_debt_limit(), "100.000 TL sınırı aşıldı")
	for i in 3:
		Result.apply(s, _fake_result(-1000))
	eq(s.insolvent_days, 3, "kârsız gün sayılır")
	Result.apply(s, _fake_result(5000))
	eq(s.insolvent_days, 0, "kârlı etkinlik sayacı sıfırlar")
	var res := {}
	for i in 7:
		check(not s.is_closed(), "7. günden önce açık")
		res = _fake_result(-1000)
		Result.apply(s, res)
	check(s.is_closed() and res["closed"], "7 kârsız günde kapanır")
	var sess = Session.new(s, 1)
	check(not sess.offer(1), "kapalı işletme teklif veremez")


func test_session_offers_only_waiter_and_cook() -> void:
	eq(Session.ROLES, ["waiter", "cook"], "barmen simülasyonda yok, listede de yok")
	var sess = Session.new(new_state(), 1)
	sess.set_staff("bartender", 3)
	eq(sess.staff_list(), [], "bilinmeyen rol eklenmez")
