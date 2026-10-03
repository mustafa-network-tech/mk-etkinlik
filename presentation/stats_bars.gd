extends Control
## Beş değer çubuğu ve beklenti işareti. Yeşil: beklenti karşılanıyor.

const I18n := preload("res://presentation/i18n.gd")
const KEYS := ["prestige", "comfort", "fun", "service", "safety"]

var achieved: Dictionary = {}
var expected: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(250, 112)


func set_values(p_achieved: Dictionary, p_expected: Dictionary) -> void:
	achieved = p_achieved
	expected = p_expected
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var bar_x := 80.0
	var bar_w := size.x - bar_x - 8.0
	for i in KEYS.size():
		var k: String = KEYS[i]
		var y := 6.0 + i * 21.0
		var a: float = achieved.get(k, 0.0)
		var e: float = expected.get(k, 0.0)
		draw_string(font, Vector2(2, y + 11), I18n.t("stat." + k), HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
		draw_rect(Rect2(bar_x, y, bar_w, 14), Color(0.85, 0.85, 0.88))
		var col := Color(0.25, 0.7, 0.35) if a >= e else Color(0.85, 0.45, 0.25)
		draw_rect(Rect2(bar_x, y, bar_w * clampf(a / 100.0, 0.0, 1.0), 14), col)
		var ex := bar_x + bar_w * clampf(e / 100.0, 0.0, 1.0)
		draw_line(Vector2(ex, y - 2), Vector2(ex, y + 16), Color(0.1, 0.1, 0.15), 2.0)
		draw_string(font, Vector2(bar_x + 3, y + 11), "%d" % roundi(a), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.05, 0.05, 0.1))
