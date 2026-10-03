extends RefCounted
## Hareket eden varlık tabanı: hücre koordinatında konum ve yol izleme.

var id: int
var pos := Vector2.ZERO
var cell := Vector2i.ZERO
var path: Array[Vector2i] = []


func place_at(c: Vector2i) -> void:
	cell = c
	pos = Vector2(c)
	path.clear()


## speed hücre/sn. Yol bitince true.
func advance(speed: float, dt: float) -> bool:
	var remaining := speed * dt
	while remaining > 0.0 and not path.is_empty():
		var target := Vector2(path[0])
		var d := pos.distance_to(target)
		if d <= remaining:
			pos = target
			cell = path.pop_front()
			remaining -= d
		else:
			pos += (target - pos).normalized() * remaining
			remaining = 0.0
	return path.is_empty()
