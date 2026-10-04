extends RefCounted
## 8 yönlü A*; köşe kesmez, duvar ve engelleyen eşyaya saygı gösterir (docs/04 §8).

const Nav := preload("res://sim/nav.gd")

const SQRT2 := 1.41421356
const DIRS8: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1),
	Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1),
]


## Başlangıç hariç, hedef dahil hücre listesi. Yol yoksa ya da from == to ise boş.
static func find_path(state, from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if from == to or not Nav.is_passable(state, to):
		return empty
	var venue = state.venue
	var open: Array[Vector2i] = [from]
	var g := {from: 0.0}
	var f := {from: _h(from, to)}
	var parent := {}
	var closed := {}
	while not open.is_empty():
		var best_i := 0
		for i in range(1, open.size()):
			if f[open[i]] < f[open[best_i]]:
				best_i = i
		var cur: Vector2i = open[best_i]
		open.remove_at(best_i)
		if cur == to:
			return _rebuild(parent, cur, from)
		closed[cur] = true
		for d in DIRS8:
			var nxt: Vector2i = cur + d
			if closed.has(nxt) or not Nav.is_passable(state, nxt):
				continue
			var step := 1.0
			if d.x != 0 and d.y != 0:
				step = SQRT2
				var ox := cur + Vector2i(d.x, 0)
				var oy := cur + Vector2i(0, d.y)
				if not Nav.is_passable(state, ox) or not Nav.is_passable(state, oy):
					continue
				if venue.has_wall_between(cur, ox) or venue.has_wall_between(ox, nxt) \
						or venue.has_wall_between(cur, oy) or venue.has_wall_between(oy, nxt):
					continue
			elif venue.has_wall_between(cur, nxt):
				continue
			var ng: float = g[cur] + step
			if not g.has(nxt) or ng < g[nxt]:
				g[nxt] = ng
				f[nxt] = ng + _h(nxt, to)
				parent[nxt] = cur
				if not open.has(nxt):
					open.append(nxt)
	return empty


static func _h(a: Vector2i, b: Vector2i) -> float:
	var dx := absi(a.x - b.x)
	var dy := absi(a.y - b.y)
	return float(maxi(dx, dy)) + (SQRT2 - 1.0) * float(mini(dx, dy))


static func _rebuild(parent: Dictionary, cur: Vector2i, from: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	while cur != from:
		out.push_front(cur)
		cur = parent[cur]
	return out
