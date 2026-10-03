# 06 · Ekonomi ve değerlendirme formülleri

Tüm sabitler `data/tuning.json`’dadır. Burada gösterilenler **başlangıç değerleri**; prototipte ayarlanacak.

## 1. Eşya katkısı ve azalan getiri
Beş değer her biri için ham toplam:
```
raw_k = Σ_over_item_types  ( stat_k · Σ_{j=0}^{n-1} decay^j ) · condition
```
- `n`: aynı eşya türünden yerleştirilen adet, `decay = stack_decay` (eşya başına; yoksa 0.7). Sandalye gibi sayıyla ölçeklenen eşyalarda 1.0. 10 avize 10 kat prestij vermez.
- `condition` ∈ [0,1]: durabilite/aşınma (hasar sonrası bakım yapılmazsa düşer).

## 2. Beş değerin hesabı (0–100)
Her değer ham toplamın **kapasiteye ve misafir sayısına** göre normalize edilmesiyle bulunur:
```
stat_k = 100 · (1 − exp(−eff_k / scale_k))      # doyma eğrisi, 100’e asimptotik
```
`eff_k` değerler türüne göre:
| Değer | eff formülü (özet) |
|-------|--------------------|
| Prestij | `raw_prestige` (alan bağımsız) · kalite çarpanı (temizlik, düzen) |
| Konfor | `raw_comfort` · `min(1, seats/guests)` · `min(1, wc_slots/(guests/15))` · `ac_factor` · `1 − crowd_penalty` |
| Eğlence | `raw_fun` · `min(1, dance_slots/(guests·0.4))` · `sound_factor` |
| Servis | `raw_service` · `min(1, service_capacity/guest_demand)` |
| Güvenlik | `raw_safety` + `exits_bonus` + `security_staff·6` − `crowd_penalty` |

Başlangıç `scale_k`: prestij 60, konfor 50, eğlence 55, servis 45, güvenlik 40.
`crowd_penalty` = `clamp((1.2 − usable_m² / guests) · 0.5, 0, 0.6)`; `usable_m² = geçilebilir hücre × 0.25` (hücre 0.5 m × 0.5 m). Kişi başı alan 1.2 m²’nin altına inerse ceza.
`service_capacity` = Σ_garson `speed · 8` (masa-servis/saat) vs `guest_demand = guests·0.8` (kişi başı saatlik servis talebi).

Bu değerler **statik tahmin**dir (yapı modunda canlı gösterilir). Etkinlik sırasındaki gerçek sonuç NPC davranışından gelir; ikisi arasındaki fark oyuncuya “plan ile gerçek” öğretici olur.

## 3. Müşteri beklentisi eşleşmesi
Müşteri beklentisi `E_k` (yoksa 0), türün ağırlığı `w_k`:
```
match_k = clamp( 0.5 + (achieved_k − E_k) / 60 , 0, 1 )      # beklentiyi tam karşılayınca 0.5’in üstü
match   = Σ w_k · match_k / Σ w_k
```
Beklenti tanımsızsa `E_k = tür taban beklentisi`. “Özel istek” karşılanırsa +0.05, karşılanmazsa −0.08 (ağırlıkça).

## 4. Yıldız puanı
```
guest_sat   = zaman ağırlıklı ortalama memnuniyet (0–1)
incident_pen = min(0.25, 0.02 · ciddi_olay_sayısı)        # MVP’de kuyruk terkleri sayılır
final       = 0.5·match + 0.5·guest_sat − incident_pen        # ağırlıklar toplamı 1: 5 yıldız ulaşılabilir
stars       = clamp( round(1 + 4·final), 1, 5 )
```
Yorum metni: en düşük 2 değer + en büyük ihtiyaç şikâyeti türünden şablon cümleler (TR/EN tablosu), kişiliğe göre ton.

## 5. İtibar
```
Δrep = (stars − 3) · 12 · size_factor           # size_factor = clamp(guests/60, 0.6, 1.5)
stars ≤ 2 ise Δrep’e ek −8 (kötü ağız)
```
Basamaklar: 0–299 Mahalle salonu · 300–699 Popüler mekân · 700+ Prestijli Event House. İptal edilen etkinlik −15.
Talep üretimi (aylık/haftalık havuz): `budget ~ base · (1 + 0.6·tier)`, beklenti eşikleri tier ile yükselir.

## 6. Teklif ve pazarlık
Müşterinin isteklilik fiyatı:
```
WTP = budget · (1 + 0.15 · (1 − frugality) − 0.10 · pickiness)       # ~0.9–1.15 × bütçe
P(kabul | offer) = 1 / (1 + exp((offer − WTP) / (0.04 · budget)))
```
- `offer ≤ 0.9·WTP` ise neredeyse kesin kabul; `offer ≥ 1.1·WTP` ise neredeyse kesin ret.
- Ret sonrası bir sonraki teklif aynı müşteride **−%15 olasılık** (taciz etme), 2 ret = müşteri çekilir.
- Beklentilerin güçlü şekilde altında kalan mekânda (tahmini match < 0.35) müşteri pazarlıksız reddeder.
- MVP: yalnızca “kabul” ve 3 hazır teklif (bütçe, %95, %110).

## 6b. Gelir
```
gelir = agreed_price  +  bar_revenue  +  extras
bar_revenue = Σ içecek satışı (fiyat − maliyet)    # barda satılan her içecek
extras      = fotoğraf köşesi, VIP paket vb. (MVP sonrası)
```
Sözleşme: ön ödeme %20 (tarihten sonra iade edilmez), kalan %80 etkinlik bitiminde. 1 yıldızda %40, 2 yıldızda %20 kesinti (şikâyet); `data/tuning.json` → `economy.low_star_discount`.

## 7. Gider (etkinlik başına)
| Kalem | Formül | Başlangıç |
|-------|--------|-----------|
| Catering | `guests · head_cost(tür, kalite)` | 190 TL/kişi (nişan) |
| Personel | `Σ wage_per_hour · (event_hours + 1)` | garson 280, aşçı 450, barmen 300 TL/sa |
| Elektrik | `Σ power · hours · 9 TL` | 9 TL/birim-sa |
| Hasar/aşınma | `Σ item_price · wear` (düşen durabilite) | olay+yoğunluk |
| Bakım | sabit + aşınmaya bağlı | haftalık |
| Kira/vergi | sabit, günlük | 600 TL/gün (başlangıç) |
| Reklam | oyuncu bütçesi (MVP sonrası) | |

### Çalıştırılmış örnek (nişan, 65 kişi, 4 saat)
```
Gelir:       46.000 (sözleşme) + 5.200 (bar) + 2.800 (ekstra)   = 54.000 TL
Personel:    3×280×5 + 1×450×5 + 1×300×5                          =  −7.950 TL
Catering:    65 × 190                                             = −12.350 TL
Elektrik:    38 birim × 4 sa × 9                                  =  −1.368 TL
Hasar:                                                            =  −2.000 TL
Net kâr:                                                          = 30.332 TL
```
(Bu, brief’teki örnek ekranla aynı mertebe; sayılar prototipte yeniden ayarlanacak.)

## 8. Borç ve kurtarma
- Kasa < 0: otomatik **kısa vadeli borç** (faiz %2/gün, üst sınır 100.000 TL); borç faizi gider olarak işlenir.
- Borç üst sınırı aşılırsa: **iflas uyarısı**; 7 oyun günü içinde net > 0 olmazsa kapanış.
- Kurtarma kredisi: tek seferlik, sabit faiz, itibar −20; eşya satışı %50.

## 9. İlerleme ve açılımlar
XP = `stars·10 + guests/5 + net/1000`. Seviye eşikleri: 1→2: 100 XP, sonra ×1.35 üstel. Katalog açılımı: L1 temel masa/sandalye+basit DJ · L5 profesyonel ses · L10 LED duvar · L15 VIP dekor · L20 otomatik ışık · L25 premium catering (MVP’de L1–L5).

## 10. Denge test senaryoları (bot)
1. Boş salon + 1 masa → müşteri reddi veya 1–2 yıldız.
2. Dengeli yerleşim (masa, DJ, 1 WC, 1 garson, 1 aşçı) → 3–4 yıldız, net pozitif.
3. Yalnızca dekorasyona yatırım, personelsiz → prestij yüksek, servis ~0, 1–2 yıldız, net negatif. (Başarısızlığın mümkün olduğunu kanıtlar.)
4. Aynı bütçe iki yerleşim: WC pist yanında / pist uzağında; yıldız farkı ≥ 1.

## 11. Uygulama notları (Faz 1, dilim 1d)
- Servis değeri artık garsondan da gelir: `waiter_service_points` (20) × garson hızı, eşya servis puanına eklenir; garson yoksa servis 0 kalır.
- Güvenlik: yalnız çıkış bonusu (8). Güvenlik personeli MVP dışı olduğundan tüm türlerin güvenlik beklentisi düşük tutuldu (10–18).
- Özel istek (fotoğraf köşesi vb.), bar geliri, hasar gideri ve ön ödeme henüz yok.
- Etkinlik süresi ≈ 6 gerçek dakika; ihtiyaç artışı ve yeme/dans süreleri buna göre ayarlandı. Denge ilk oynanış testinden sonra yeniden bakılacak: şu an kötü bir etkinlik de nakit olarak kârlı kalabiliyor (ceza itibarda ve kesintide); “zarar ettirme” için indirim/itibar etkisi artırılabilir.
