extends RefCounted
## Oyun durumunun kökü. Yalnızca komutlarla değişir (commands/command.gd).

const Venue := preload("res://sim/venue.gd")

var data ## GameData
var venue
var cash: int ## eksi = borç (docs/06 §8); eksideyken satın alma yapılamaz
var level: int
var xp := 0 ## bu seviyede biriken deneyim; eşik xp_to_next()
var reputation := 0 ## 0..1000
var day := 1
var insolvent_days := 0 ## borç sınırının üstünde kâr edilmeden geçen gün
var event_active := false


func _init(game_data) -> void:
	data = game_data
	var t: Dictionary = data.tuning
	venue = Venue.new(int(t["grid_width"]), int(t["grid_height"]),
			Vector2i(int(t["entrance"][0]), int(t["entrance"][1])))
	cash = int(t["start_cash"])
	level = int(t["start_level"])


## 0 Mahalle salonu, 1 Popüler mekân, 2 Prestijli Event House.
func tier() -> int:
	var t := 0
	for threshold in data.tuning["economy"]["tier_thresholds"]:
		if reputation >= int(threshold):
			t += 1
	return t


## Sonraki seviye için gereken XP: taban · büyüme^(seviye−1) (docs/06 §9).
func xp_to_next() -> int:
	var eco: Dictionary = data.tuning["economy"]
	return roundi(float(eco["level_xp_base"]) * pow(float(eco["level_xp_growth"]), level - 1))


func debt() -> int:
	return maxi(0, -cash)


func over_debt_limit() -> bool:
	return debt() > int(data.tuning["economy"]["debt_limit"])


## Borç sınırı aşıldıktan sonra süre içinde kâr edilemedi: işletme kapandı.
func is_closed() -> bool:
	return insolvent_days >= int(data.tuning["economy"]["insolvency_days"])
