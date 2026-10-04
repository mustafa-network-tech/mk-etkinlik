extends "res://tests/test_case.gd"

const EventRun := preload("res://sim/event_run.gd")
const WAITER := [{"role": "waiter", "speed": 1.0}]
const WAITER_COOK := [{"role": "waiter", "speed": 1.0}, {"role": "cook", "speed": 1.0}]


## Girişe yakın servis masası, uzakta WC, ortada pist+DJ.
func _venue(with_wc: bool = true, with_serve: bool = true):
	var s = new_state()
	for i in 12:
		place(s, "chair_basic", 6 + i, 4)
	if with_serve:
		place(s, "service_table", 3, 8)
	if with_wc:
		place(s, "wc_basic", 30, 3)
	place(s, "dance_floor", 20, 12)
	place(s, "dj_basic", 25, 12)
	return s


func _run(s, guests: int, staff: Array, seed_value: int = 1) -> Dictionary:
	var r = EventRun.new().setup(s, {"guests": guests, "seed": seed_value, "staff": staff})
	r.run_to_end()
	return r.result()


func test_event_locks_building_and_unlocks_after() -> void:
	var s = _venue()
	var r = EventRun.new().setup(s, {"guests": 2, "seed": 1, "staff": WAITER})
	eq(place(s, "chair_basic", 1, 1)["error"], "locked_during_event", "etkinlikte yapı kilitli")
	r.run_to_end()
	check(not s.event_active, "bitince kilit açılır")
	check(place(s, "chair_basic", 1, 1)["ok"], "yapı yeniden açık")


func test_balanced_venue_serves_guests() -> void:
	var res := _run(_venue(), 10, WAITER_COOK)
	eq(res["guests"], 10, "10 misafir geldi")
	check(res["meals"] >= 10, "yemekler servis edildi")
	check(res["dances"] > 0, "dans edildi")
	check(res["wc_uses"] > 0, "WC kullanıldı")
	check(res["guest_sat"] > 0.75, "memnuniyet yüksek")
	check(res["avg_order_wait_s"] > 0.0, "sipariş bekleme süresi ölçüldü")


func test_no_waiter_means_orders_go_unserved() -> void:
	var good := _run(_venue(), 10, WAITER)
	var bad := _run(_venue(), 10, [])
	eq(bad["meals"], 0, "garson yoksa yemek yok")
	check(bad["abandon_count"] > good["abandon_count"], "terk artar")
	check(bad["guest_sat"] < good["guest_sat"], "memnuniyet düşer")
	var late := 0
	for e in bad["log"]:
		if e["kind"] == "ORDER_LATE":
			late += 1
	check(late > 0, "ORDER_LATE olayı kaydedildi")


func test_cook_speeds_up_kitchen() -> void:
	var waiters := [{"role": "waiter", "speed": 1.0}, {"role": "waiter", "speed": 1.0}]
	var no_cook := _run(_venue(), 25, waiters)
	var with_cook := _run(_venue(), 25, waiters + [{"role": "cook", "speed": 1.0}])
	check(with_cook["meals"] > no_cook["meals"], "aşçıyla daha çok yemek (%d > %d)" % [with_cook["meals"], no_cook["meals"]])
	check(with_cook["avg_order_wait_s"] < no_cook["avg_order_wait_s"], "aşçıyla sipariş daha kısa sürer")
	check(with_cook["guest_sat"] > no_cook["guest_sat"], "aşçıyla memnuniyet yüksek")


func test_no_service_table_is_equivalent_to_no_service() -> void:
	var res := _run(_venue(true, false), 10, WAITER)
	eq(res["meals"], 0, "servis masası yoksa garson sipariş alamaz")


func test_missing_wc_hurts_satisfaction() -> void:
	var with_wc := _run(_venue(true), 10, WAITER)
	var without := _run(_venue(false), 10, WAITER)
	eq(without["wc_uses"], 0, "WC yok")
	check(without["guest_sat"] < with_wc["guest_sat"], "WC'siz mekân daha az memnun")


func test_overcrowding_causes_queues_and_abandons() -> void:
	var res := _run(_venue(), 30, WAITER)
	check(res["max_queue_wc"] >= 2, "tek WC'de kuyruk oluştu")
	check(res["abandon_count"] > 0, "12 koltuk ve tek garson 30 misafire yetmez")


func test_same_seed_is_deterministic_and_seeds_differ() -> void:
	var a := _run(_venue(), 15, WAITER, 7)
	var b := _run(_venue(), 15, WAITER, 7)
	a.erase("log")
	b.erase("log")
	eq(a, b, "aynı tohum aynı sonuç")
	var c := _run(_venue(), 15, WAITER, 8)
	c.erase("log")
	check(a != c, "farklı tohum farklı sonuç")


func test_unreachable_station_is_not_used() -> void:
	var s = new_state()
	for i in 4:
		place(s, "chair_basic", 6 + i, 4)
	# WC'yi kapalı odaya koy
	for x in [30, 31]:
		Command.apply(s, {"type": "add_wall", "x": x, "y": 5, "edge": 0})
		Command.apply(s, {"type": "add_wall", "x": x, "y": 7, "edge": 0})
	Command.apply(s, {"type": "add_wall", "x": 29, "y": 5, "edge": 1})
	Command.apply(s, {"type": "add_wall", "x": 29, "y": 6, "edge": 1})
	Command.apply(s, {"type": "add_wall", "x": 31, "y": 5, "edge": 1})
	Command.apply(s, {"type": "add_wall", "x": 31, "y": 6, "edge": 1})
	place(s, "wc_basic", 30, 5)
	var res := _run(s, 4, WAITER)
	eq(res["wc_uses"], 0, "erişilemeyen WC kullanılmaz")
