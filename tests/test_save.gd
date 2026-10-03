extends "res://tests/test_case.gd"

const SaveGame := preload("res://sim/save_game.gd")

const PATH := "user://test_slot.json"


func _cleanup() -> void:
	for suffix in ["", ".tmp", ".bak"]:
		var p := ProjectSettings.globalize_path(PATH + suffix)
		if FileAccess.file_exists(PATH + suffix):
			DirAccess.remove_absolute(p)


func _sample():
	var s = new_state()
	place(s, "table_round_8", 10, 10)
	place(s, "dj_basic", 5, 5, 90)
	Command.apply(s, {"type": "add_wall", "x": 20, "y": 5, "edge": 1})
	s.level = 3
	return s


func test_roundtrip_preserves_state_exactly() -> void:
	_cleanup()
	var s = _sample()
	check(SaveGame.write(s, PATH), "yazıldı")
	var r := SaveGame.read(s.data, PATH)
	check(r["ok"], "okundu")
	var loaded = r["state"]
	eq(SaveGame.to_dict(loaded), SaveGame.to_dict(s), "yükle sonrası durum aynı")
	eq(loaded.venue.occupant(Vector2i(5, 7)), s.venue.occupant(Vector2i(5, 7)), "doluluk yeniden kuruldu")
	# kayıt -> yükle -> kayıt: bayt bayt aynı gövde
	check(SaveGame.write(loaded, PATH + "2"), "ikinci yazma")
	var a := FileAccess.get_file_as_string(PATH)
	var b := FileAccess.get_file_as_string(PATH + "2")
	eq(a.substr(a.find("\n")), b.substr(b.find("\n")), "gövde bayt bayt eş")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + "2"))
	_cleanup()


func test_loaded_state_keeps_placing_with_fresh_ids() -> void:
	_cleanup()
	var s = _sample()
	SaveGame.write(s, PATH)
	var loaded = SaveGame.read(s.data, PATH)["state"]
	var r := place(loaded, "chair_basic", 30, 10)
	check(r["ok"], "yüklenen durumda yerleştirilir")
	check(not s.venue.items.has(r["id"]), "yeni id çakışmaz")
	_cleanup()


func test_corrupt_file_falls_back_to_backup() -> void:
	_cleanup()
	var s = _sample()
	SaveGame.write(s, PATH)
	s.cash -= 1000
	SaveGame.write(s, PATH) # ilk kayıt .bak olur
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("bozuk\nçöp")
	f.close()
	var r := SaveGame.read(s.data, PATH)
	check(r["ok"], "yedekten okundu")
	check(r.get("from_backup", false), "yedekten olduğu işaretli")
	check(r["state"].cash > s.cash, "yedek eski kaydı taşır")
	_cleanup()


func test_corrupt_without_backup_reports_error() -> void:
	_cleanup()
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string("{}\n{}")
	f.close()
	var r := SaveGame.read(new_state().data, PATH)
	check(not r["ok"], "okunamaz")
	eq(r["error"], "checksum", "sebep bildirilir")
	eq(SaveGame.read(new_state().data, "user://yok.json")["error"], "not_found", "dosya yok")
	_cleanup()


func test_newer_version_is_refused() -> void:
	_cleanup()
	var body := JSON.stringify({}, "", true)
	var env := JSON.stringify({"schema_version": 99, "checksum": body.sha256_text()}, "", true)
	var f := FileAccess.open(PATH, FileAccess.WRITE)
	f.store_string(env + "\n" + body)
	f.close()
	eq(SaveGame.read(new_state().data, PATH)["error"], "newer_version", "gelecek sürüm reddedilir")
	_cleanup()


func test_unknown_item_is_skipped_with_warning() -> void:
	var s = _sample()
	var d := SaveGame.to_dict(s)
	d["venue"]["items"].append({"id": 77, "def": "ghost_item", "x": 1, "y": 1, "rot": 0, "cond": 1.0})
	var r := SaveGame.from_dict(s.data, d)
	check(r["ok"], "yüklenir")
	eq(r["warnings"], ["unknown_item:ghost_item"], "uyarı verir")
	eq(r["state"].venue.items.size(), 2, "bilinen eşyalar korunur")


func test_overlapping_items_in_save_are_rejected() -> void:
	var s = _sample()
	var d := SaveGame.to_dict(s)
	d["venue"]["items"].append({"id": 50, "def": "chair_basic", "x": 11, "y": 11, "rot": 0, "cond": 1.0})
	eq(SaveGame.from_dict(s.data, d)["error"], "corrupt_item", "çakışan kayıt bozuk sayılır")


func test_migration_chain_applies_in_order() -> void:
	var m: Array = [
		func(d): d["a"] = 1; return d,
		func(d): d["b"] = d["a"] + 1; return d,
	]
	var out := SaveGame.migrate({}, 1, m, 3)
	eq(out, {"a": 1, "b": 2}, "v1→v2→v3 sırayla")
