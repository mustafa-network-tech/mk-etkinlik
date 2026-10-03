extends "res://tests/test_case.gd"

const Nav := preload("res://sim/nav.gd")


func test_empty_venue_fully_reachable() -> void:
	var s = new_state()
	eq(Nav.reachable_from_entrance(s).size(), 1000, "boş salonda tüm hücreler erişilebilir")


func test_blocking_item_not_passable_nonblocking_is() -> void:
	var s = new_state()
	place(s, "table_round_8", 10, 10)
	place(s, "chair_basic", 20, 10)
	var reach := Nav.reachable_from_entrance(s)
	check(not reach.has(Vector2i(11, 11)), "masa hücresine girilmez")
	check(reach.has(Vector2i(20, 10)), "sandalye hücresi geçilebilir")


func test_walled_off_room_makes_station_unreachable() -> void:
	var s = new_state()
	# (30..32, 5..6) kutusunu dört yandan duvarla kapat
	for x in [30, 31, 32]:
		Command.apply(s, {"type": "add_wall", "x": x, "y": 5, "edge": 0}) # üst
		Command.apply(s, {"type": "add_wall", "x": x, "y": 7, "edge": 0}) # alt (y=7'nin kuzeyi)
	for y in [5, 6]:
		Command.apply(s, {"type": "add_wall", "x": 29, "y": y, "edge": 1}) # sol
		Command.apply(s, {"type": "add_wall", "x": 32, "y": y, "edge": 1}) # sağ
	var wc := place(s, "wc_basic", 30, 5)
	check(wc["ok"], "WC kapalı odaya konur")
	var outside := place(s, "service_table", 10, 3)
	eq(Nav.unreachable_station_items(s), [wc["id"]], "yalnızca kapalı odadaki WC uyarı verir")
	check(outside["ok"], "dıştaki servis masası erişilebilir")


func test_door_gap_restores_access() -> void:
	var s = new_state()
	for x in [30, 31, 32]:
		Command.apply(s, {"type": "add_wall", "x": x, "y": 5, "edge": 0})
		Command.apply(s, {"type": "add_wall", "x": x, "y": 7, "edge": 0})
	for y in [5, 6]:
		Command.apply(s, {"type": "add_wall", "x": 29, "y": y, "edge": 1})
	# sağ duvarda y=6'da kapı boşluğu bırakıldı (yalnız y=5 kapalı)
	Command.apply(s, {"type": "add_wall", "x": 32, "y": 5, "edge": 1})
	var wc := place(s, "wc_basic", 30, 5)
	eq(Nav.unreachable_station_items(s), [], "boşluktan girilir")
	check(wc["ok"], "WC yerleşti")
