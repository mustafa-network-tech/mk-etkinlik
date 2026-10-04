# 05 · Yapı modu ve ızgara sistemi

## 1. Boyutlar
- Hücre: **0.5 m × 0.5 m**. 250 m² = 1000 hücre; **40 × 25** (20 m × 12.5 m) dikdörtgen.
- İleride genişleme: ızgara boyutu artar, mevcut koordinatlar korunur (orijin sol-üst).
- İlk sürümde mekân dikdörtgen sabit kabuk; dış duvar ve ana giriş yerleşiktir (oyuncu giriş ağzını taşıyabilir, kaldıramaz).

## 2. Koordinatlar
- Hücre `(x, y)`, 0 ≤ x < 40, 0 ≤ y < 25.
- Duvarlar **hücre kenarlarında** durur: `WallSegment {x, y, edge: N|E}` (her hücrenin kuzey ve doğu kenarı; güneş/batı komşunun N/E’si). Böylece ince duvar, kalın duvar değil, kenar olarak temsil edilir ve hücre alanı kaybolmaz.
- Kapı/kemer: bir kenarda `Opening` (genişlik 2 hücre = 1 m, çift kapı 4 hücre).
- Eşyalar hücrelere yerleşir; ayak izi `footprint` (rot ile döner).

## 3. Yerleştirme kuralları
1. Tüm ayak izi hücreleri ızgara içinde ve boş olmalı (başka eşya yok).
2. Ayak izi duvar kenarıyla kesişmez (duvar kenarı hücreyi bölmez; eşya duvara bitişik olabilir, üstünden geçemez).
3. Eşya rotasyonu 90° adımlarla.
4. Duvara yaslanma gerektiren eşya (`wall_mount`) yalnızca duvar kenarına bitişik yerleştirilir (LED ekran, perde).
5. Yerleştirmeden sonra **erişilebilirlik kontrolü**: eşyanın “kullanım hücresi” (örn. sandalye önü) bir girişten ulaşılabilir olmalı. Değilse **uyarı** (engel değil): özgürlük korunur, bedeli sonuçta ödenir.
6. Para yetmezse yerleştirme reddedilir; kataloğa kilitli eşya görünür ama pasiftir.

## 4. Duvar işlemleri
- **Çiz:** iki hücre köşesi arasında doğru parça (yalnızca yatay/dikey), maliyet = parça × birim fiyat.
- **Sil:** %70 iade (yapı modunda anlık).
- **Değiştir:** tür (alçı, cam, ahşap panel…): prestij ve maliyet farkı, ses yalıtımı (MVP sonrası).
- Dış duvar silinemez. Taşıyıcı kısıt MVP’de yok.
- Kapalı oda tespiti (flood fill) bölümleri etiketleme, WC mahremiyeti vb. için kullanılır (prestij/konfor).

## 5. Yürünebilirlik
- Nav hücresi **yürünebilir** ⇔ hücrede `blocks_movement` bir eşya yok ve hücre dışarıya kapalı değil.
- Hücreler arası geçiş kenar kontrolüyle: komşu hücreler arasında duvar kenarı varsa ve açıklık yoksa geçiş yok. (Çapraz hareket için iki ara kenar da açık olmalı.)
- `nav_dirty` yerleştirme/silme/duvar işleminden sonra true olur; etkinlik başlamadan önce yeniden hesaplanır.
- Doğrulama raporu (etkinlik başlatmadan önce gösterilir):
  - Girişten ulaşılamayan istasyonlar
  - Tek hücre genişliğinde darboğazlar
  - Çıkış sayısı (güvenlik için en az 1; 2+ önerilir)

## 6. Katalog verisi (örnek)
```json
{
  "id": "table_round_8",
  "category": "furniture",
  "footprint": [[0,0],[1,0],[0,1],[1,1],[2,0],[2,1],[0,2],[1,2],[2,2]],
  "price": 3500,
  "stats": {"prestige": 2, "comfort": 0, "fun": 0, "service": 0, "safety": 0},
  "capacity": {"seats": 8},
  "station": {"kind": "seat", "use_time_s": 0, "slots": 8},
  "power": 0, "durability": 90, "blocks_movement": true
}
```
Sandalyeler masa etrafında ayrı eşya olarak yerleşir; “masa+sandalye seti” kolaylık için tek tıkla 8 sandalyeyi yerleştiren **şablon** (komut grubu) olarak sunulur, ama içerik yine bağımsız eşyalardır.

## 7. Yapı modu kullanılabilirliği (MVP)
- Seçim, taşıma, döndürme, silme, kopyalama.
- **Geri al/yinele** (komut yığını).
- Bölge boyama (çoklu duvar/halı).
- Canlı değer göstergesi: beş değerin statik tahmini + seçili müşterinin beklentisiyle karşılaştırma (yeşil/kırmızı).
- Isı/yürüme önizlemesi (MVP sonrası): önceki etkinliğin ısı haritası zemine bindirilir.

## 8. Kamera (sunum)
- Yapı: yukarıdan izometrik, serbest döndürme (90° adım + serbest), yakınlaştırma.
- Etkinlik: aşağı iner, misafirleri takip eden serbest kamera. Kamera tamamen sunum katmanında; sim’i etkilemez.
