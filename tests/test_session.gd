extends "res://tests/test_case.gd"

const Session := preload("res://sim/session.gd")


func _session(seed_value: int = 1):
	return Session.new(new_state(), seed_value)


func test_new_session_has_a_request_and_no_contract() -> void:
	var s = _session()
	check(not s.request.is_empty(), "talep var")
	check(s.contract.is_empty(), "sözleşme yok")
	check(not s.can_start(), "sözleşmesiz başlatılamaz")


func test_cheap_offer_is_accepted_and_expensive_two_times_replaces_request() -> void:
	var s = _session()
	check(s.offer(int(s.request["budget"] * 0.5)), "ucuz teklif kabul")
	check(s.request.is_empty(), "kabulde talep kapanır")
	check(s.contract["agreed_price"] > 0, "sözleşme fiyatı pozitif")
	var t = _session(2)
	var req_before: Dictionary = t.request
	check(not t.offer(req_before["budget"] * 5), "çok pahalı teklif reddedilir")
	check(not t.offer(req_before["budget"] * 5), "ikinci ret")
	check(t.request != req_before, "iki ret sonrası yeni talep")
	eq(t.rejections, 0, "sayaç sıfırlanır")


func test_full_day_loop_updates_cash_day_and_reputation() -> void:
	var s = _session(3)
	var st = s.state
	st.cash = 1000000
	st.level = 5
	for i in 40:
		place(st, "chair_basic", 2 + i % 30, 2 + i / 30)
	place(st, "service_table", 3, 8)
	place(st, "wc_basic", 30, 10)
	place(st, "dance_floor", 20, 12)
	place(st, "dj_basic", 25, 12)
	check(s.offer(int(s.request["budget"] * 0.4)), "teklif kabul")
	s.set_staff("waiter", 3)
	check(s.can_start(), "başlatılabilir")
	var cash0: int = st.cash
	check(s.start_event(), "başladı")
	check(st.event_active, "yapı kilitli")
	s.run.run_to_end()
	var res: Dictionary = s.finish_event()
	check(not res.is_empty(), "sonuç var")
	eq(st.cash, cash0 + res["net"], "kasa net kadar değişti")
	eq(st.day, 2, "gün ilerledi")
	check(s.contract.is_empty() and not s.request.is_empty(), "yeni talep geldi")
	check(not st.event_active, "kilit açıldı")


func test_cannot_start_twice_or_without_finish() -> void:
	var s = _session(4)
	s.offer(1)
	check(s.start_event(), "ilk başlatma")
	check(not s.start_event(), "ikinci başlatma yok")
	eq(s.finish_event(), {}, "bitmeden sonuç yok")
