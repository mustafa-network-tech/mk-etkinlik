extends RefCounted
## Mekân: hücre ızgarası, kenar duvarları, yerleştirilmiş eşyalar. Bkz. docs/05-BUILD-GRID.md.

const N := 0 ## hücrenin kuzey kenarı
const E := 1 ## hücrenin doğu kenarı

var width: int
var height: int
var entrance: Vector2i
var items: Dictionary = {} ## id -> {id, def, x, y, rot, cond, cells}
var walls: Dictionary = {} ## Vector3i(x, y, edge) -> kind
var next_id := 1
var _occ := PackedInt32Array()


func _init(w: int, h: int, entrance_cell: Vector2i) -> void:
	width = w
	height = h
	entrance = entrance_cell
	_occ.resize(w * h)


func in_bounds(c: Vector2i) -> bool:
	return c.x >= 0 and c.y >= 0 and c.x < width and c.y < height


func occupant(c: Vector2i) -> int:
	return _occ[c.y * width + c.x] if in_bounds(c) else -1


func set_occupant(c: Vector2i, id: int) -> void:
	_occ[c.y * width + c.x] = id


## Dış duvar örtük ve değişmez; yalnız iç kenarlara duvar konabilir.
func is_inner_edge(x: int, y: int, edge: int) -> bool:
	if x < 0 or y < 0 or x >= width or y >= height:
		return false
	if edge == N:
		return y > 0
	return x < width - 1


## İki komşu (4 yön) hücre arasında duvar var mı.
func has_wall_between(a: Vector2i, b: Vector2i) -> bool:
	var d := b - a
	if d == Vector2i(1, 0):
		return walls.has(Vector3i(a.x, a.y, E))
	if d == Vector2i(-1, 0):
		return walls.has(Vector3i(b.x, b.y, E))
	if d == Vector2i(0, 1):
		return walls.has(Vector3i(b.x, b.y, N))
	if d == Vector2i(0, -1):
		return walls.has(Vector3i(a.x, a.y, N))
	return false
