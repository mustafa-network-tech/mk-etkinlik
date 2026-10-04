extends "res://sim/actor.gd"
## Garson: IDLE -> TO_PICKUP -> PICKING -> TO_DELIVER -> IDLE (docs/04 §5-6).

enum State { IDLE, TO_PICKUP, PICKING, TO_DELIVER }

var state := State.IDLE
var speed := 1.0
var order_id := 0
var timer := 0.0
