extends RefCounted
## Çeviri tablosu (data/strings.json). Kodda sabit kullanıcı metni yok (docs/DECISIONS.md K3).

static var lang := "tr"
static var _table: Dictionary = {}


static func t(key: String, args: Array = []) -> String:
	if _table.is_empty():
		var f := FileAccess.open("res://data/strings.json", FileAccess.READ)
		_table = JSON.parse_string(f.get_as_text()) if f != null else {}
	var text: String = _table.get(lang, {}).get(key, _table.get("tr", {}).get(key, key))
	return text % args if not args.is_empty() else text
