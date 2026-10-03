extends "res://sim/actor.gd"
## Misafir: ihtiyaçlar (0 rahat .. 100 dayanılmaz), sabır (100 .. 0), durum (docs/04).

enum State { DECIDING, MOVING, QUEUEING, USING, SEATED, EATING, LEAVING, GONE }

var state := State.DECIDING
var hunger := 10.0
var fun := 10.0
var bladder := 5.0
var patience := 100.0
var persona := {"hunger": 1.0, "fun": 1.0, "bladder": 1.0, "patience": 1.0}

var station := -1 ## rezerve/kullanılan/sırada beklenen istasyon indeksi
var seat_station := -1 ## oturuyorsa koltuk istasyonu
var order_id := 0 ## bekleyen sipariş (0: yok)
var timer := 0.0 ## USING/EATING kalan süre (sn)
var bad_stations: Array[int] = []
var no_seat := false ## aç ama boş koltuk yok (sabır azalır)
var no_seat_logged := false
var abandoned := false

var sat_acc := 0.0
var sat_steps := 0
