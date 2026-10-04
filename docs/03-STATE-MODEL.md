# 03 · Oyun durumu modeli

Tek kök: `GameState`. Tüm değişiklik komutlarla yapılır; sunum yalnızca okur. Kimlikler (`id`) kalıcı tamsayıdır (`next_id` sayacından).

## 1. Kök
```
GameState
  schema_version : int
  seed, rng_states
  clock          : GameClock { day, minute, tick }
  venue          : Venue
  finance        : Finance
  reputation     : Reputation
  progression    : Progression { level, xp, unlocked_item_ids[] }
  staff[]        : Staff
  inventory[]    : OwnedItemRef            # sahip olunan ama yerleştirilmemiş
  contracts[]    : Contract                # kabul edilmiş, bekleyen
  lead_pool[]    : CustomerRequest         # gelen talepler
  active_event   : EventRun | null
  history[]      : EventResult             # son N etkinlik
```

## 2. Mekân
```
Venue
  width_cells, height_cells        # 40×25 = 1000 hücre (hücre 0.5 m → 250 m²)
  walls[]      : WallSegment {x, y, edge: N|E, kind, hp}   # hücre kenarında
  openings[]   : Opening {x, y, edge, kind: door|arch, width_cells}
  items[]      : PlacedItem {id, def_id, x, y, rot: 0|90|180|270,
                             condition: 0..1, power_on: bool}
  zones[]      : opsiyonel etiket {rect, label}  # yalnızca oyuncu notu, oyunu bağlamaz
  nav_dirty    : bool                           # yürünebilirlik yeniden hesaplanmalı
```
`ItemDef` (katalog, kayıtta yok; `data/items.json`):
```
ItemDef
  id, name_key, category: furniture|decor|tech|ops
  footprint: [[dx,dy],…]        # kapladığı hücreler (rot=0)
  price, sell_ratio, tier_unlock (seviye)
  stats: {prestige, comfort, fun, service, safety}   # ham katkılar
  power: int                    # elektrik birimi
  durability: int (0–100)
  capacity: {seats, dance_slots, serve_slots, queue_slots, ...}
  station: null | {kind: seat|dance|bar|serve|wc|photo|kitchen, use_time_s, slots}
  stack_decay: float            # aynı türün n. kopyası değeri (0.7^n)
  blocks_movement: bool
```

## 3. Finans ve itibar
```
Finance { cash, debt, loan_rate, ledger[] }          # ledger: {day, kind, amount, ref}
Reputation { points: 0..1000, tier, reviews[], followers }   # followers MVP dışı
```

## 4. Müşteri / sözleşme / etkinlik
```
CustomerRequest
  id, name, event_type, guests, budget, theme
  expectations: {prestige?, comfort?, fun?, service?, safety?}   # eşikler
  special_requests[]  # {kind: photo_corner|stage|vip_area, weight}
  date_day, personality: {frugality, pickiness, haggle}

Contract { request_id, agreed_price, deposit_paid, date_day, status }

EventRun
  contract_id, start_minute, end_minute, phase: arriving|running|closing
  guests[] : Guest, staff_on_duty[] : staff_id
  stations[] : StationRuntime {item_id, occupants[], queue[]}
  orders[]   : Order {guest_id, kind: food|drink, state, ready_at}
  metrics    : {avg_satisfaction, per_need[], wait_times[], incidents[], revenue_bar}
  event_queue: zamanlanmış olaylar (MVP: boş)

EventResult { contract_id, income[], expenses[], stats_final, stars, reviews[], net, heatmap }
```

## 5. NPC
```
Guest
  id, pos(float x,y), cell, persona: {patience, appetite, sociality, dance_affinity,
                                      thirst, bladder, age_group}
  needs: {hunger, thirst, fun, comfort, bladder, social, patience}  # 0..100
  state, goal, path[], carrying, satisfaction (0..100)
  seat_item_id | null, group_id (aynı masa/aile)

Staff
  id, role: waiter|cook|bartender|cleaner|security|dj|tech|coordinator
  wage_per_hour, speed, experience, morale, skills
  state, task, path[]
```

## 6. Türetilmiş (kayıtta olmayan) veri
Yürünebilirlik ızgarası, yol önbelleği, beş değerin statik tahmini, istasyon dizinleri. `nav_dirty` ile yeniden üretilir; yüklemede hesaplanır.

## 7. Değişmezlik (invariants) — test edilecek
- Hiçbir `PlacedItem` ayak izi duvarla veya başka eşyayla çakışmaz.
- `cash` negatifse `debt` mantığı devreye girer; ledger toplamı = kasa değişimi.
- Etkinlik sırasında `venue` yapı komutlarını reddeder.
- Her `Guest.seat_item_id` mevcut bir `seat` istasyonunu gösterir.
- Her girişten her istasyona en az bir yol vardır; yoksa yerleşim “uyarı” verir (etkinlik başlatılabilir ama bildirilir).
