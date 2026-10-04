extends "res://tests/test_case.gd"


func test_catalog_loads_and_grid_is_250_sqm() -> void:
	var s = new_state()
	eq(s.venue.width * s.venue.height, 1000, "1000 hücre = 250 m² (0.5 m hücre)")
	check(s.data.has_def("table_round_8"), "katalogda masa var")


func test_place_item_deducts_cash_and_occupies_cells() -> void:
	var s = new_state()
	var cash0: int = s.cash
	var r := place(s, "table_round_8", 10, 10)
	check(r["ok"], "yerleştirme başarılı")
	eq(s.cash, cash0 - 3500, "fiyat düşer")
	eq(s.venue.occupant(Vector2i(12, 12)), r["id"], "ayak izi köşesi dolu")
	eq(s.venue.occupant(Vector2i(13, 12)), 0, "dışarısı boş")


func test_rotation_normalizes_footprint() -> void:
	var s = new_state()
	var fp: Array[Vector2i] = s.data.footprint("dj_basic", 90)
	eq(fp.size(), 3, "3 hücre")
	for c in fp:
		eq(c.x, 0, "90° dönünce tek sütun")
	check(fp.has(Vector2i(0, 2)), "aşağı doğru uzar")
	var r := place(s, "dj_basic", 5, 5, 90)
	check(r["ok"], "dönmüş yerleştirme")
	eq(s.venue.occupant(Vector2i(5, 7)), r["id"], "dikey uzanır")


func test_out_of_bounds_and_overlap_rejected() -> void:
	var s = new_state()
	eq(place(s, "table_round_8", 39, 24)["error"], "out_of_bounds", "sınır dışı")
	place(s, "table_round_8", 10, 10)
	eq(place(s, "chair_basic", 11, 11)["error"], "occupied", "çakışma")


func test_not_enough_cash_and_locked_item() -> void:
	var s = new_state()
	eq(place(s, "speaker_pro", 5, 5)["error"], "locked", "L5 eşyası L1'de kilitli")
	s.level = 5
	s.cash = 100
	eq(place(s, "speaker_pro", 5, 5)["error"], "not_enough_cash", "para yetmez")


func test_remove_item_refunds_and_frees_cells() -> void:
	var s = new_state()
	var r := place(s, "dj_basic", 5, 5)
	var cash_after_buy: int = s.cash
	var rm := Command.apply(s, {"type": "remove_item", "id": r["id"]})
	check(rm["ok"], "silindi")
	eq(s.cash, cash_after_buy + 5600, "%70 iade")
	eq(s.venue.occupant(Vector2i(5, 5)), 0, "hücre boş")


func test_entrance_cannot_be_blocked() -> void:
	var s = new_state()
	eq(place(s, "wc_basic", 0, 12)["error"], "blocks_entrance", "girişe engel konamaz")
	check(place(s, "chair_basic", 0, 12)["ok"], "geçilebilir eşya olur")


func test_wall_rules() -> void:
	var s = new_state()
	var cash0: int = s.cash
	var add := {"type": "add_wall", "x": 10, "y": 5, "edge": 1}
	check(Command.apply(s, add)["ok"], "iç duvar eklenir")
	eq(s.cash, cash0 - 150, "duvar bedeli")
	eq(Command.apply(s, add)["error"], "wall_exists", "aynı kenara ikinci duvar yok")
	eq(Command.apply(s, {"type": "add_wall", "x": 39, "y": 5, "edge": 1})["error"], "not_buildable", "dış duvar değişmez")
	eq(Command.apply(s, {"type": "add_wall", "x": 5, "y": 0, "edge": 0})["error"], "not_buildable", "kuzey dış duvar")
	check(Command.apply(s, {"type": "remove_wall", "x": 10, "y": 5, "edge": 1})["ok"], "duvar silinir")
	eq(s.cash, cash0 - 150 + 105, "%70 iade")


func test_wall_cannot_cut_an_item_and_item_cannot_straddle_wall() -> void:
	var s = new_state()
	place(s, "table_round_8", 10, 10)
	eq(Command.apply(s, {"type": "add_wall", "x": 10, "y": 10, "edge": 1})["error"], "item_in_way", "eşyanın içinden duvar geçmez")
	var s2 = new_state()
	Command.apply(s2, {"type": "add_wall", "x": 10, "y": 10, "edge": 1})
	eq(place(s2, "table_round_8", 9, 9)["error"], "wall_in_way", "duvarı aşan eşya yerleşmez")
	check(place(s2, "table_round_8", 11, 9)["ok"], "duvara bitişik eşya olur")


func test_build_commands_locked_during_event() -> void:
	var s = new_state()
	s.event_active = true
	eq(place(s, "chair_basic", 5, 5)["error"], "locked_during_event", "etkinlikte yapı kilitli")
