extends RefCounted
## Yürünebilirlik ve erişilebilirlik. Türetilmiş veri; kayda girmez.

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]


static func is_passable(state, c: Vector2i) -> bool:
	var venue = state.venue
	if not venue.in_bounds(c):
		return false
	var id: int = venue.occupant(c)
	if id == 0:
		return true
	return not state.data.blocks_movement(venue.items[id]["def"])


## Girişten ulaşılabilen hücreler (Vector2i -> true).
static func reachable_from_entrance(state) -> Dictionary:
	var venue = state.venue
	var seen := {}
	if not is_passable(state, venue.entrance):
		return seen
	var queue: Array[Vector2i] = [venue.entrance]
	seen[venue.entrance] = true
	var head := 0
	while head < queue.size():
		var cur := queue[head]
		head += 1
		for d in DIRS:
			var nxt := cur + d
			if seen.has(nxt) or not is_passable(state, nxt):
				continue
			if venue.has_wall_between(cur, nxt):
				continue
			seen[nxt] = true
			queue.append(nxt)
	return seen


## İstasyonu olan ama girişten kullanılamayan eşyaların id'leri (uyarı raporu).
static func unreachable_station_items(state) -> Array[int]:
	var venue = state.venue
	var reach := reachable_from_entrance(state)
	var out: Array[int] = []
	for id in venue.items:
		var item: Dictionary = venue.items[id]
		if state.data.defs[item["def"]]["station"] == null:
			continue
		if not _touches(venue, item, reach):
			out.append(id)
	out.sort()
	return out


static func _touches(venue, item: Dictionary, reach: Dictionary) -> bool:
	for cell in item["cells"]:
		if reach.has(cell):
			return true
		for d in DIRS:
			var nb: Vector2i = cell + d
			if reach.has(nb) and not venue.has_wall_between(cell, nb):
				return true
	return false
