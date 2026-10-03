extends SceneTree
## Geliştirici aracı: ana sahneyi senaryo ile sürüp PNG kaydeder.
## xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --script tools/screenshot.gd -- <klasör>

const Command := preload("res://commands/command.gd")

var out_dir := "user://shots"


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		out_dir = args[0]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var main = load("res://presentation/main.tscn").instantiate()
	root.add_child(main)
	await _frames(3)
	_shot("1_empty")

	var st = main.session.state
	st.cash = 200000
	st.level = 5
	for i in 40:
		Command.apply(st, {"type": "place_item", "def": "chair_basic", "x": 2 + i % 20, "y": 2 + i / 20 * 2})
	for i in 3:
		Command.apply(st, {"type": "place_item", "def": "table_round_8", "x": 3 + i * 5, "y": 18})
	Command.apply(st, {"type": "place_item", "def": "service_table", "x": 3, "y": 9})
	Command.apply(st, {"type": "place_item", "def": "wc_basic", "x": 32, "y": 3})
	Command.apply(st, {"type": "place_item", "def": "dance_floor", "x": 22, "y": 11})
	Command.apply(st, {"type": "place_item", "def": "dj_basic", "x": 28, "y": 11})
	for x in range(31, 35):
		Command.apply(st, {"type": "add_wall", "x": x, "y": 5, "edge": 0})
	main.view.selected_def = "chair_basic"
	main.view._hover = Vector2i(10, 8)
	main.session.offer(int(main.session.request["budget"] * 0.9))
	main.session.set_staff("waiter", 3)
	main._staff_spins["waiter"].value = 3
	main._refresh()
	await _frames(2)
	_shot("2_built")

	main._on_start()
	for i in 700:
		main.session.run.step()
	await _frames(2)
	_shot("3_event")

	main.session.run.run_to_end()
	main._show_result(main.session.finish_event())
	main._refresh()
	await _frames(2)
	_shot("4_result")
	quit()


func _frames(n: int) -> void:
	for i in n:
		await process_frame


func _shot(name: String) -> void:
	var img := root.get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("saved ", name, " ", img.get_size())
