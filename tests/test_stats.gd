extends "res://tests/test_case.gd"

const Stats := preload("res://sim/venue_stats.gd")


func test_empty_venue_has_only_exit_safety() -> void:
	var s = new_state()
	var v := Stats.estimate(s, 0)
	for k in ["prestige", "comfort", "fun", "service"]:
		eq(v[k], 0.0, k + " boş salonda 0")
	check(v["safety"] > 0.0 and v["safety"] < 20.0, "yalnız çıkış güvenliği var")


func test_stats_are_within_0_100() -> void:
	var s = new_state()
	s.cash = 10000000
	s.level = 5
	for i in 10:
		place(s, "speaker_pro", 5 + i, 3)
	var v := Stats.estimate(s, 50, [{"role": "waiter", "speed": 1.0}])
	for k in Stats.KEYS:
		check(v[k] >= 0.0 and v[k] < 100.0, k + " 0..100 aralığında")


func test_stack_decay_gives_diminishing_returns() -> void:
	var one = new_state()
	place(one, "dj_basic", 5, 5)
	one.cash = 1000000
	var two = new_state()
	two.cash = 1000000
	place(two, "dj_basic", 5, 5)
	place(two, "dj_basic", 5, 8)
	var f1: float = Stats.estimate(one, 0)["fun"]
	var f2: float = Stats.estimate(two, 0)["fun"]
	check(f2 > f1, "ikinci DJ biraz daha eğlence verir")
	check(f2 < 2.0 * f1, "ama iki katı değil")


func test_comfort_needs_seats_for_guests() -> void:
	var few = new_state()
	var many = new_state()
	for i in 5:
		place(few, "chair_basic", 5 + i, 5)
	for i in 10:
		place(many, "chair_basic", 5 + i, 5)
	place(few, "wc_basic", 20, 5)
	place(many, "wc_basic", 20, 5)
	var c5: float = Stats.estimate(few, 10)["comfort"]
	var c10: float = Stats.estimate(many, 10)["comfort"]
	check(c10 > c5, "10 misafire 10 sandalye, 5'ten daha konforlu")
	var c10_few_guests: float = Stats.estimate(few, 5)["comfort"]
	check(c10_few_guests > c5, "aynı sandalye daha az misafire yeter")


func test_service_is_zero_without_waiters() -> void:
	var s = new_state()
	place(s, "service_table", 5, 5)
	eq(Stats.estimate(s, 30)["service"], 0.0, "garson yoksa servis 0")
	var with_waiter := Stats.estimate(s, 30, [{"role": "waiter", "speed": 1.0}])
	check(with_waiter["service"] > 0.0, "garsonla servis var")
	var two_waiters := Stats.estimate(s, 30, [{"role": "waiter", "speed": 1.0}, {"role": "waiter", "speed": 1.0}])
	check(two_waiters["service"] > with_waiter["service"], "ikinci garson artırır")


func test_decor_only_venue_fails_service_and_comfort() -> void:
	# docs/06 §10 senaryo 3: yalnız dekorasyon, personelsiz
	var s = new_state()
	s.cash = 10000000
	s.level = 5
	for i in 4:
		place(s, "speaker_pro", 5 + i, 3)
	var v := Stats.estimate(s, 65)
	check(v["fun"] < 10.0, "pist yoksa eğlence düşük kalır (ses var, dans alanı yok)")
	eq(v["service"], 0.0, "servis 0")
	eq(v["comfort"], 0.0, "oturma yok, konfor 0")
	check(v["prestige"] > 20.0, "prestij yüksek")


func test_crowding_reduces_values() -> void:
	var s = new_state()
	for i in 10:
		place(s, "chair_basic", 5 + i, 5)
	place(s, "wc_basic", 20, 5)
	var calm: float = Stats.estimate(s, 10)["comfort"]
	var packed: float = Stats.estimate(s, 400)["comfort"]
	check(packed < calm, "kalabalıkta konfor düşer")
