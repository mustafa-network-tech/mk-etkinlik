extends Control
## 2D üstten görünüm: ızgara, duvarlar, eşyalar, önizleme; etkinlikte misafirler ve garsonlar.
## Yalnız durumu okur; değişiklikleri komutla yapar.

const Command := preload("res://commands/command.gd")
const Guest := preload("res://sim/guest.gd")
const I18n := preload("res://presentation/i18n.gd")

signal changed
signal message(text: String)

enum Tool { PLACE, WALL, ERASE }

const CELL := 20
const CATEGORY_COLORS := {
	"furniture": Color(0.80, 0.64, 0.42), "decor": Color(0.85, 0.55, 0.65),
	"tech": Color(0.42, 0.55, 0.88), "ops": Color(0.50, 0.74, 0.55),
}

var session
var tool := Tool.PLACE
var selected_def := ""
var rot := 0
var _hover := Vector2i(-1, -1)
var _mouse := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL


func setup(p_session) -> void:
	session = p_session
	custom_minimum_size = Vector2(session.state.venue.width, session.state.venue.height) * CELL


func rotate_selection() -> void:
	rot = (rot + 90) % 360
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if session == null:
		return
	if event is InputEventMouseMotion:
		_mouse = event.position
		_hover = Vector2i(int(event.position.x / CELL), int(event.position.y / CELL))
		queue_redraw()
	elif event is InputEventMouseButton and event.pressed:
		grab_focus()
		if event.button_index == MOUSE_BUTTON_LEFT:
			_primary()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_erase()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_R:
		rotate_selection()


func _primary() -> void:
	var r := {"ok": false, "error": "unknown_command"}
	match tool:
		Tool.PLACE:
			if selected_def == "":
				return
			r = Command.apply(session.state, {"type": "place_item", "def": selected_def,
					"x": _hover.x, "y": _hover.y, "rot": rot})
		Tool.WALL:
			var e := _nearest_edge()
			r = Command.apply(session.state, {"type": "add_wall", "x": e.x, "y": e.y, "edge": e.z})
		Tool.ERASE:
			_erase()
			return
	_report(r)


func _erase() -> void:
	var venue = session.state.venue
	if venue.in_bounds(_hover) and venue.occupant(_hover) > 0:
		_report(Command.apply(session.state, {"type": "remove_item", "id": venue.occupant(_hover)}))
		return
	var e := _nearest_edge()
	_report(Command.apply(session.state, {"type": "remove_wall", "x": e.x, "y": e.y, "edge": e.z}))


func _report(r: Dictionary) -> void:
	if r["ok"]:
		changed.emit()
	else:
		message.emit(I18n.t("err." + String(r["error"])))
	queue_redraw()


## Fare konumuna en yakın hücre kenarı -> Vector3i(x, y, edge) (venue.gd kuralıyla).
func _nearest_edge() -> Vector3i:
	var c := _hover
	var local := _mouse - Vector2(c) * CELL
	var d_n := local.y
	var d_s := CELL - local.y
	var d_w := local.x
	var d_e := CELL - local.x
	var m := minf(minf(d_n, d_s), minf(d_w, d_e))
	if m == d_n:
		return Vector3i(c.x, c.y, 0)
	if m == d_s:
		return Vector3i(c.x, c.y + 1, 0)
	if m == d_w:
		return Vector3i(c.x - 1, c.y, 1)
	return Vector3i(c.x, c.y, 1)


func _process(_delta: float) -> void:
	if session != null and session.run != null:
		queue_redraw()


func _draw() -> void:
	if session == null:
		return
	var venue = session.state.venue
	var w: int = venue.width
	var h: int = venue.height
	for y in h:
		for x in w:
			var shade := 0.93 if (x + y) % 2 == 0 else 0.90
			draw_rect(Rect2(x * CELL, y * CELL, CELL, CELL), Color(shade, shade * 0.97, shade * 0.92))
	draw_rect(Rect2(0, 0, w * CELL, h * CELL), Color(0.2, 0.2, 0.25), false, 3.0)
	var ent: Vector2i = venue.entrance
	draw_rect(Rect2(ent.x * CELL, ent.y * CELL, CELL, CELL), Color(0.3, 0.8, 0.4, 0.6))
	_draw_items(venue)
	_draw_walls(venue)
	if session.run != null:
		_draw_actors()
	elif tool == Tool.PLACE and selected_def != "" and venue.in_bounds(_hover):
		_draw_ghost()


func _draw_items(venue) -> void:
	var font := ThemeDB.fallback_font
	for id in venue.items:
		var item: Dictionary = venue.items[id]
		var def: Dictionary = session.state.data.defs[item["def"]]
		var col: Color = CATEGORY_COLORS.get(def["category"], Color.GRAY)
		if not def["blocks_movement"]:
			col = col.lerp(Color.WHITE, 0.45)
		var min_c := Vector2i(1 << 20, 1 << 20)
		for c in item["cells"]:
			draw_rect(Rect2(c.x * CELL + 1, c.y * CELL + 1, CELL - 2, CELL - 2), col)
			min_c = Vector2i(mini(min_c.x, c.x), mini(min_c.y, c.y))
		if item["cells"].size() >= 2: # tek hücrelik eşyada etiket kalabalık yapar
			var label: String = I18n.t(def["name_key"]).substr(0, 3)
			draw_string(font, Vector2(min_c.x * CELL + 3, min_c.y * CELL + 14), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.1, 0.1, 0.15))


func _draw_walls(venue) -> void:
	for key in venue.walls:
		var k: Vector3i = key
		if k.z == 0: # hücrenin kuzey kenarı
			draw_line(Vector2(k.x * CELL, k.y * CELL), Vector2((k.x + 1) * CELL, k.y * CELL), Color(0.25, 0.2, 0.18), 4.0)
		else: # doğu kenarı
			draw_line(Vector2((k.x + 1) * CELL, k.y * CELL), Vector2((k.x + 1) * CELL, (k.y + 1) * CELL), Color(0.25, 0.2, 0.18), 4.0)


func _draw_ghost() -> void:
	var err: String = Command.check_place(session.state, selected_def, _hover, rot)
	var col := Color(0.2, 0.8, 0.3, 0.5) if err == "" else Color(0.9, 0.2, 0.2, 0.5)
	for off in session.state.data.footprint(selected_def, rot):
		var c: Vector2i = _hover + off
		draw_rect(Rect2(c.x * CELL, c.y * CELL, CELL, CELL), col)


func _draw_actors() -> void:
	var run = session.run
	for g in run.guests:
		if g.state == Guest.State.GONE:
			continue
		var col := Color(0.25, 0.4, 0.85)
		match g.state:
			Guest.State.QUEUEING: col = Color(0.95, 0.6, 0.15)
			Guest.State.USING: col = Color(0.2, 0.7, 0.3)
			Guest.State.SEATED: col = Color(0.45, 0.45, 0.5)
			Guest.State.EATING: col = Color(0.5, 0.85, 0.5)
			Guest.State.LEAVING: col = Color(0.8, 0.25, 0.25)
		var p: Vector2 = (g.pos + Vector2(0.5, 0.5)) * CELL
		draw_circle(p, CELL * 0.32, col)
		var bar := clampf(g.patience / 100.0, 0.0, 1.0) # sabır çubuğu
		draw_rect(Rect2(p.x - 6, p.y - 11, 12.0 * bar, 2), Color(0.9, 0.2, 0.2))
	for w in run.waiters:
		var p: Vector2 = (w.pos + Vector2(0.5, 0.5)) * CELL
		draw_rect(Rect2(p.x - 6, p.y - 6, 12, 12), Color(0.95, 0.8, 0.15))
		draw_rect(Rect2(p.x - 6, p.y - 6, 12, 12), Color(0.2, 0.15, 0.0), false, 1.5)
