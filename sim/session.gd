extends RefCounted
## Oyun akışı: talep -> teklif -> sözleşme -> hazırlık -> etkinlik -> sonuç. Sunumdan bağımsız.

const Customers := preload("res://sim/customers.gd")
const EventRun := preload("res://sim/event_run.gd")
const EventResult := preload("res://sim/event_result.gd")

const ROLES := ["waiter", "cook", "bartender"]

var state
var rng := RandomNumberGenerator.new()
var request: Dictionary = {}
var contract: Dictionary = {}
var staff_counts := {"waiter": 0, "cook": 0, "bartender": 0}
var run = null
var last_result: Dictionary = {}
var rejections := 0


func _init(p_state, seed_value: int = 1) -> void:
	state = p_state
	rng.seed = seed_value
	new_request()


func new_request() -> void:
	request = Customers.generate_request(state, rng, state.day)
	rejections = 0


## Müşteri teklifi kabul etti mi. İki ret sonrası müşteri çekilir, yeni talep gelir.
func offer(price: int) -> bool:
	if request.is_empty() or not contract.is_empty():
		return false
	if Customers.decide(state, request, price, rng):
		contract = {"name": request["name"], "event_type": request["event_type"],
				"guests": request["guests"], "agreed_price": price,
				"expectations": request["expectations"], "date_day": request["date_day"]}
		request = {}
		return true
	rejections += 1
	if rejections >= 2:
		new_request()
	return false


func decline() -> void:
	if contract.is_empty():
		new_request()


func set_staff(role: String, count: int) -> void:
	staff_counts[role] = maxi(0, count)


func staff_list() -> Array:
	var out := []
	for role in ROLES:
		for i in staff_counts[role]:
			out.append({"role": role, "speed": 1.0})
	return out


func can_start() -> bool:
	return not contract.is_empty() and run == null and not state.event_active


func start_event() -> bool:
	if not can_start():
		return false
	run = EventRun.new().setup(state, {"guests": contract["guests"], "seed": rng.randi(), "staff": staff_list()})
	return true


## Etkinlik bitti: sonucu hesapla ve uygula. Sonraki güne geç.
func finish_event() -> Dictionary:
	if run == null or not run.finished:
		return {}
	last_result = EventResult.compute(state, run, contract, staff_list())
	last_result["customer"] = contract["name"]
	EventResult.apply(state, last_result)
	run = null
	contract = {}
	state.day += 1
	new_request()
	return last_result
