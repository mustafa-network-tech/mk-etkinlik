extends SceneTree
## Çalıştırma: godot --headless --path . --script tests/run_tests.gd

func _init() -> void:
	var total := 0
	var failed := 0
	var dir := DirAccess.open("res://tests")
	var files: Array[String] = []
	for f in dir.get_files():
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd":
			files.append(f)
	files.sort()
	for f in files:
		var script: GDScript = load("res://tests/" + f)
		if script == null or not script.can_instantiate():
			total += 1
			failed += 1
			print("FAIL  %s (betik derlenemedi)" % f)
			continue
		var methods: Array[String] = []
		for m in script.get_script_method_list():
			if String(m["name"]).begins_with("test_"):
				methods.append(m["name"])
		methods.sort()
		for name in methods:
			var t = script.new()
			t.call(name)
			total += 1
			if t.failures.is_empty():
				print("ok    %s::%s" % [f, name])
			else:
				failed += 1
				print("FAIL  %s::%s" % [f, name])
				for msg in t.failures:
					print("        - ", msg)
	print("\n%d test, %d başarısız" % [total, failed])
	quit(1 if failed > 0 else 0)
