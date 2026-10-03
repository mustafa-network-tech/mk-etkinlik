extends "res://tests/test_case.gd"

const AStar := preload("res://sim/astar.gd")


func _wall(s, x: int, y: int, edge: int) -> void:
	Command.apply(s, {"type": "add_wall", "x": x, "y": y, "edge": edge})


func test_straight_and_diagonal_paths_are_shortest() -> void:
	var s = new_state()
	var p := AStar.find_path(s, Vector2i(2, 2), Vector2i(7, 2))
	eq(p.size(), 5, "düz yol 5 adım")
	eq(p[p.size() - 1], Vector2i(7, 2), "hedef dahil")
	var d := AStar.find_path(s, Vector2i(2, 2), Vector2i(6, 6))
	eq(d.size(), 4, "çapraz 4 adım")


func test_same_cell_or_blocked_goal_gives_empty() -> void:
	var s = new_state()
	eq(AStar.find_path(s, Vector2i(2, 2), Vector2i(2, 2)).size(), 0, "aynı hücre")
	place(s, "table_round_8", 10, 10)
	eq(AStar.find_path(s, Vector2i(2, 2), Vector2i(11, 11)).size(), 0, "engelli hedef")


func test_path_detours_around_wall() -> void:
	var s = new_state()
	for y in range(3, 8): # (5,y) ile (6,y) arasında dikey duvar, y=3..7
		_wall(s, 5, y, 1)
	var p := AStar.find_path(s, Vector2i(4, 5), Vector2i(7, 5))
	check(p.size() > 3, "duvar yüzünden dolanır")
	var prev := Vector2i(4, 5)
	for c in p:
		check(not s.venue.has_wall_between(prev, c), "adım duvar geçmiyor")
		prev = c


func test_no_diagonal_corner_cutting() -> void:
	var s = new_state()
	_wall(s, 5, 5, 1) # (5,5) ile (6,5) arası
	_wall(s, 5, 6, 0) # (5,5) ile (5,6) arası: kuzey kenarı (5,6)'nın
	# (5,5)->(6,6) çaprazı iki duvar köşesinden geçerdi
	var p := AStar.find_path(s, Vector2i(5, 5), Vector2i(6, 6))
	check(p.size() > 1, "çapraz köşe kesilemez")


func test_enclosed_target_has_no_path() -> void:
	var s = new_state()
	for x in [30, 31]:
		_wall(s, x, 5, 0)
		_wall(s, x, 6, 0)
	for y in [5]:
		_wall(s, 29, y, 1)
		_wall(s, 31, y, 1)
	eq(AStar.find_path(s, Vector2i(2, 2), Vector2i(30, 5)).size(), 0, "kapalı odaya yol yok")
