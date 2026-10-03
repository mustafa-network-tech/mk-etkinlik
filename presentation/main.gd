extends Control
## Ana ekran: yapı modu + talep/teklif + personel + etkinlik izleme + sonuç paneli.
## Mantık sim/session.gd'de; burada yalnız arayüz ve zaman akışı var.

const GameData := preload("res://sim/game_data.gd")
const GameState := preload("res://sim/game_state.gd")
const Session := preload("res://sim/session.gd")
const Nav := preload("res://sim/nav.gd")
const Stats := preload("res://sim/venue_stats.gd")
const SaveGame := preload("res://sim/save_game.gd")
const VenueView := preload("res://presentation/venue_view.gd")
const StatsBars := preload("res://presentation/stats_bars.gd")
const I18n := preload("res://presentation/i18n.gd")

const SAVE_PATH := "user://slot_1.json"

var session
var view
var bars
var speed := 1.0
var paused := false
var _acc := 0.0

var _top_label: Label
var _status: Label
var _request_label: Label
var _offer_box: HBoxContainer
var _start_btn: Button
var _staff_spins := {}
var _item_buttons := {}
var _tool_buttons := {}
var _result_panel: ColorRect
var _result_label: RichTextLabel
var _speed_label: Label


func _ready() -> void:
	var data := GameData.new()
	assert(data.load_from("res://data/items.json", "res://data/tuning.json"))
	session = Session.new(GameState.new(data), int(Time.get_unix_time_from_system()))
	_build_ui()
	_refresh()


func _build_ui() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var root := VBoxContainer.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	var top := HBoxContainer.new()
	root.add_child(top)
	_top_label = Label.new()
	_top_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_top_label)
	for pair in [["ui.save", _on_save], ["ui.load", _on_load]]:
		top.add_child(_button(I18n.t(pair[0]), pair[1]))
	_speed_label = Label.new()
	top.add_child(_speed_label)
	for sp in [1.0, 2.0, 4.0]:
		top.add_child(_button("%dx" % int(sp), func(): speed = sp; paused = false; _refresh()))
	top.add_child(_button(I18n.t("ui.pause"), func(): paused = not paused; _refresh()))

	var body := HBoxContainer.new()
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(body)
	body.add_child(_build_left())

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	view = VenueView.new()
	view.setup(session)
	view.changed.connect(_refresh)
	view.message.connect(func(t): _status.text = t)
	scroll.add_child(view)

	body.add_child(_build_right())

	_status = Label.new()
	root.add_child(_status)

	_result_panel = ColorRect.new() # soluk arka plan + ortalanmış sonuç paneli
	_result_panel.color = Color(0, 0, 0, 0.55)
	_result_panel.visible = false
	_result_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	_result_panel.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 560)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.13, 0.13, 0.17)
	style.set_content_margin_all(16)
	style.set_corner_radius_all(8)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var rv := VBoxContainer.new()
	panel.add_child(rv)
	_result_label = RichTextLabel.new()
	_result_label.bbcode_enabled = true
	_result_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	rv.add_child(_result_label)
	rv.add_child(_button(I18n.t("ui.continue"), _close_result))
	add_child(_result_panel)


func _build_left() -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(190, 0)
	var tools := HBoxContainer.new()
	box.add_child(tools)
	for t in [["tool.place", VenueView.Tool.PLACE], ["tool.wall", VenueView.Tool.WALL], ["tool.erase", VenueView.Tool.ERASE]]:
		var b := Button.new()
		b.text = I18n.t(t[0])
		b.toggle_mode = true
		b.pressed.connect(func(): view.tool = t[1]; _refresh())
		tools.add_child(b)
		_tool_buttons[t[1]] = b
	box.add_child(_button(I18n.t("ui.rotate"), func(): view.rotate_selection()))
	var title := Label.new()
	title.text = I18n.t("ui.items")
	box.add_child(title)
	var ids: Array = session.state.data.defs.keys()
	ids.sort_custom(func(a, b): return session.state.data.defs[a]["price"] < session.state.data.defs[b]["price"])
	for id in ids:
		var b := Button.new()
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(func(): view.selected_def = id; view.tool = VenueView.Tool.PLACE; view.queue_redraw(); _refresh())
		box.add_child(b)
		_item_buttons[id] = b
	return box


func _build_right() -> Control:
	var box := VBoxContainer.new()
	box.custom_minimum_size = Vector2(270, 0)
	_request_label = Label.new()
	_request_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_request_label.custom_minimum_size = Vector2(260, 130)
	box.add_child(_request_label)
	_offer_box = HBoxContainer.new()
	box.add_child(_offer_box)
	_offer_box.add_child(_button(I18n.t("ui.offer_95"), func(): _offer(0.95)))
	_offer_box.add_child(_button(I18n.t("ui.offer_budget"), func(): _offer(1.0)))
	_offer_box.add_child(_button(I18n.t("ui.offer_110"), func(): _offer(1.10)))
	_offer_box.add_child(_button(I18n.t("ui.decline"), func(): session.decline(); _refresh()))
	var staff_title := Label.new()
	staff_title.text = I18n.t("ui.staff")
	box.add_child(staff_title)
	for role in Session.ROLES:
		var row := HBoxContainer.new()
		var l := Label.new()
		l.text = I18n.t("staff." + role)
		l.custom_minimum_size = Vector2(90, 0)
		row.add_child(l)
		var sp := SpinBox.new()
		sp.min_value = 0
		sp.max_value = 8
		sp.value_changed.connect(func(v): session.set_staff(role, int(v)); _refresh())
		row.add_child(sp)
		box.add_child(row)
		_staff_spins[role] = sp
	var st := Label.new()
	st.text = I18n.t("ui.stats")
	box.add_child(st)
	bars = StatsBars.new()
	box.add_child(bars)
	_start_btn = _button(I18n.t("ui.start"), _on_start)
	box.add_child(_start_btn)
	return box


func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	return b


# --- akış ------------------------------------------------------------------

func _offer(factor: float) -> void:
	var req: Dictionary = session.request
	if req.is_empty():
		return
	var accepted: bool = session.offer(int(req["budget"] * factor / 100.0) * 100)
	_status.text = I18n.t("ui.offer_accepted" if accepted else "ui.offer_refused")
	_refresh()


func _on_start() -> void:
	if session.start_event():
		_acc = 0.0
		_result_panel.visible = false
		_refresh()


func _process(delta: float) -> void:
	var run = session.run
	if run == null or run.finished or paused:
		return
	_acc += delta * speed
	var step_s: float = session.state.data.tuning["sim"]["step_s"]
	var n := 0
	while _acc >= step_s and not run.finished and n < 200:
		run.step()
		_acc -= step_s
		n += 1
	if run.finished:
		_show_result(session.finish_event())
	_refresh()


func _show_result(res: Dictionary) -> void:
	var t := ""
	t += "[b]%s[/b] · %s\n" % [I18n.t("ui.result"), res["customer"]]
	t += I18n.t("ui.stars", ["★".repeat(res["stars"]) + "☆".repeat(5 - res["stars"])]) + "\n"
	t += I18n.t("ui.match", [roundi(res["match"] * 100), roundi(res["guest_sat"] * 100)]) + "\n\n"
	t += "[b]%s[/b]\n" % I18n.t("ui.income")
	for e in res["income"]:
		t += "  %s: %s TL\n" % [I18n.t("income." + e["kind"]), _money(e["amount"])]
	t += "[b]%s[/b]\n" % I18n.t("ui.expenses")
	for e in res["expenses"]:
		t += "  %s: -%s TL\n" % [I18n.t("expense." + e["kind"]), _money(e["amount"])]
	t += "\n[b]%s[/b]\n" % I18n.t("ui.net", [_money(res["net"])])
	t += I18n.t("ui.rep_change", [res["reputation_delta"]]) + "\n\n"
	t += "[b]%s[/b]\n" % I18n.t("ui.issues")
	var shown := 0
	for issue in res["issues"]:
		if shown >= 3:
			break
		if issue["kind"] == "stat":
			t += "  • " + I18n.t("issue.stat", [I18n.t("stat." + issue["key"])]) + "\n"
		else:
			t += "  • %s (%d)\n" % [I18n.t("issue.log." + issue["key"]), issue["count"]]
		shown += 1
	if shown == 0:
		t += "  " + I18n.t("ui.no_issues") + "\n"
	_result_label.text = t
	_status.text = ""
	_result_panel.visible = true


func _close_result() -> void:
	_result_panel.visible = false
	_refresh()


func _on_save() -> void:
	if session.state.event_active:
		return
	_status.text = I18n.t("ui.saved") if SaveGame.write(session.state, SAVE_PATH) else "!"


func _on_load() -> void:
	if session.state.event_active:
		return
	var r: Dictionary = SaveGame.read(session.state.data, SAVE_PATH)
	if not r["ok"]:
		_status.text = I18n.t("ui.load_failed", [r["error"]])
		return
	session.state = r["state"]
	session.contract = {}
	session.new_request()
	view.session = session
	_status.text = I18n.t("ui.loaded")
	_refresh()


# --- görünüm yenileme --------------------------------------------------------

func _refresh() -> void:
	var state = session.state
	var running: bool = session.run != null
	view.queue_redraw()
	_top_label.text = "%s   %s   %s   %s" % [I18n.t("ui.day", [state.day]), I18n.t("ui.cash", [_money(state.cash)]),
			I18n.t("ui.level", [state.level]), I18n.t("ui.reputation", [state.reputation, I18n.t("tier.%d" % state.tier())])]
	_speed_label.text = "%s %dx%s" % [I18n.t("ui.speed"), int(speed), " ⏸" if paused else ""]
	for t in _tool_buttons:
		_tool_buttons[t].button_pressed = (view.tool == t)
	for id in _item_buttons:
		var def: Dictionary = state.data.defs[id]
		var b: Button = _item_buttons[id]
		b.text = "%s  %s" % [I18n.t(def["name_key"]), _money(def["price"])]
		b.disabled = int(def["tier_unlock"]) > state.level or running
		b.modulate = Color(1, 1, 0.6) if view.selected_def == id else Color.WHITE
	_request_label.text = _describe_deal()
	_offer_box.visible = session.contract.is_empty() and not running
	_start_btn.disabled = not session.can_start()
	for role in _staff_spins:
		_staff_spins[role].editable = not running
	var guests := 40
	var expect: Dictionary = {}
	var deal: Dictionary = session.contract if not session.contract.is_empty() else session.request
	if not deal.is_empty():
		guests = int(deal["guests"])
		expect = state.data.event_types[deal["event_type"]]["base_expect"].duplicate()
		for k in deal["expectations"]:
			expect[k] = deal["expectations"][k]
	bars.set_values(Stats.estimate(state, guests, session.staff_list()), expect)
	if running:
		_status.text = I18n.t("ui.running", [int(session.run.minute()) / 60, int(session.run.minute()) % 60])
	elif not Nav.unreachable_station_items(state).is_empty():
		_status.text = I18n.t("ui.warning_unreachable", [Nav.unreachable_station_items(state).size()])


func _describe_deal() -> String:
	var deal: Dictionary = session.contract if not session.contract.is_empty() else session.request
	if deal.is_empty():
		return I18n.t("ui.no_contract")
	var data = session.state.data
	var lines: Array[String] = []
	lines.append(I18n.t("ui.contract" if not session.contract.is_empty() else "ui.request"))
	lines.append(I18n.t("ui.customer", [deal["name"]]))
	lines.append(I18n.t("ui.event", [I18n.t(data.event_types[deal["event_type"]]["name_key"])]))
	lines.append(I18n.t("ui.guests", [deal["guests"]]))
	if session.contract.is_empty():
		lines.append(I18n.t("ui.budget", [_money(deal["budget"])]))
	else:
		lines.append(I18n.t("ui.budget", [_money(deal["agreed_price"])]))
	lines.append(I18n.t("ui.date", [deal["date_day"]]))
	var ex: Array[String] = []
	for k in deal["expectations"]:
		ex.append("%s ≥ %d" % [I18n.t("stat." + k), roundi(deal["expectations"][k])])
	lines.append(I18n.t("ui.expect", [", ".join(ex)]))
	return "\n".join(lines)


func _money(v: int) -> String:
	var s := str(absi(v))
	var out := ""
	for i in s.length():
		if i > 0 and (s.length() - i) % 3 == 0:
			out += "."
		out += s[i]
	return ("-" if v < 0 else "") + out
