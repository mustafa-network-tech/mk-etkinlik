# 04 · NPC durum makinesi

Model: **ihtiyaç tabanlı fayda (utility) seçimi + sonlu durum makinesi**. İhtiyaç → hedef seçimi → yol bulma → eylem → memnuniyet etkisi.

## 1. İhtiyaçlar
0 = tam rahat, 100 = dayanılmaz. (Sabır ise 100’den azalır.)

| İhtiyaç | Artış (puan/oyun dk, taban) | Karşılayan istasyon | Gecikirse |
|---------|----------------------------|---------------------|-----------|
| Açlık | 0.45 | yemek servisi (masa) / büfe | memnuniyet ↓ |
| Susuzluk | 0.55 | bar / servis | memnuniyet ↓ |
| Eğlence | 0.50 (müzik açıkken, ilgiye göre) | pist, sahne, aktivite | sıkılır, gider |
| Konfor | masa yoksa/yoğunsa ↑ | koltuk/masa | huzursuzluk |
| Tuvalet | 0.30 (içtikçe ↑) | WC | kuyrukta sabır ↓ |
| Sosyal | 0.25 | masa, pist, fotoğraf | yalnız hisseder |
| Sabır | beklerken ↓ (taban 1.2/dk), kişilik çarpanı | — | 0 olunca vazgeç/ayrıl |

Taban değerler `data/tuning.json`’da. Kişilik çarpanı 0.6–1.4 aralığında rastgele (misafir başına, tohumdan). Aynı tür iki misafir aynı davranmaz.

## 2. Memnuniyet
```
satisfaction(t) = 100 − Σ_i w_i · max(0, need_i − tolerance_i)^1.2 · k   (0..100’e kırpılır)
```
w_i etkinlik türüne göre; tolerance ≈ 30. Memnuniyet **her adımda** hesaplanmaz, karar adımında güncellenir; son değer = zaman ağırlıklı ortalama (son bölüme daha fazla ağırlık). Beklemeden kaynaklı ceza ayrıca olay günlüğüne “kuyruk şikâyeti” olarak yazılır (sonuç ekranı için).

## 3. Durumlar (misafir)
```
ARRIVING → ENTERING → DECIDING ─┬→ MOVING → QUEUEING → USING → DECIDING
                                ├→ SEATED_IDLE (oturup sosyalleşir)
                                └→ LEAVING → GONE
```
| Durum | Davranış | Çıkış koşulu |
|-------|----------|--------------|
| ARRIVING | Dışarıdan giriş noktasına yürür (dalga eğrisine göre) | Girişe vardı |
| ENTERING | Masa/grup atar (varsa) | Atama bitti |
| DECIDING | Fayda hesaplar, hedef seçer (0.5 s’de bir) | Hedef seçildi |
| MOVING | A* yolunu izler; yol engellenirse yeniden planlar (en çok 2 deneme) | Vardı / yol yok |
| QUEUEING | İstasyon slotu doluysa kuyruğa girer; sabır azalır | Slot açıldı / sabır bitti |
| USING | Slotu `use_time` boyunca kullanır; ihtiyacı azaltır | Süre doldu |
| SEATED_IDLE | Masasında bekler; sipariş verir; konfor/sosyal ↑ azalır | Yeni ihtiyaç eşiği |
| LEAVING | Çıkışa gider | Çıkışa vardı |

## 4. Hedef seçimi (fayda)
Her aday istasyon `s` için:
```
U(s) = urgency(need_s) · pref(persona, s) · 1 / (1 + dist(s)/D0) · crowd(s) + noise
urgency(n) = (n/100)^2           # eşik altı (n<35) hedef üretmez
crowd(s)   = 1 / (1 + queue_len(s)/slots(s))
D0 = 12 hücre, noise ∈ [0, 0.05] (tohumlu)
```
- En yüksek U seçilir; **histerezis:** mevcut hedef, yenisi %20’den fazla iyi değilse korunur (titreşimi önler).
- Sınır: n ≥ 85 ise “acil” → sabır ve kuyruk toleransı ayrı değerlendirilir (WC acilleri kuyruk beklemeyi bırakıp başka WC’ye gider).
- Sabır 0: kuyruktan çıkar, memnuniyet −8, “şikâyet” olayı; ihtiyaç hâlâ yüksekse başka alternatif.

## 5. Sipariş akışı (yemek/içecek)
```
Misafir SEATED + açlık/susuzluk eşiği → Order{state: PLACED}
  → Garson boştaysa en eski siparişi alır (TAKEN)
  → Mutfak/barda hazırlanır (PREPARING; süre = ürün süresi / aşçı hızı)
  → Hazır (READY) → garson servis masasından alır → masaya taşır (DELIVERED)
  → Misafir USING(yer/içer, 20–40 s oyun) → ihtiyaç azalır
```
- Servis kapasitesi = garson sayısı × hız / mekân içi yürüme süresi. Servis masasının konumu doğrudan verimi etkiler.
- Mutfak/bar slot sayısı sınırlı; aşçı yoksa hazırlama çok yavaş.

## 6. Personel durumları
```
IDLE → (görev kuyruğu) → TO_PICKUP → CARRYING → TO_TARGET → DELIVER → IDLE
```
- Görev ataması: en yakın boş personel + role uygun görev; en eski sipariş öncelikli (FIFO + yakınlık, 3 dk’yı aşan siparişe öncelik).
- Moral/yorgunluk MVP’de **yok**; hız sabit (`speed`).
- Temizlik, güvenlik, DJ, teknisyen: MVP sonrası (DJ pasif; DJ eşyası müziği açar).

## 7. Gruplar
Misafirler 2–6 kişilik gruplardır (masa grubu). Grup: aynı masaya atanır, birlikte sipariş verir, birlikte pist/WC’ye gidebilir (%30). Çocuklar (doğum günü) ebeveyne bağlı değil, kısa sabır + yüksek eğlence artışı + “dağınıklık” riski.

## 8. Yol bulma ve çarpışma
- 8 yönlü A*, köşe kesmeyen, maliyet: düz 1, çapraz 1.41, kalabalık hücre +0.5.
- Slot rezervasyonu: hedefe gitmeden istasyon slotu **rezerve** edilir (iki NPC aynı sandalyeye gitmez).
- Kapı ağzında iki yönlü akış: 1 hücre genişlik → sıra (kuyruk); gerçekçi darboğaz, tasarım sonucu.
- Çarpışma kaçınma MVP’de yok: NPC’ler üst üste binebilir, yalnızca yoğunluk maliyeti vardır. Sunumda hafif ofset.

## 9. Olay günlüğü (sonuç ekranı için)
Her anlamlı olay (`QUEUE_ABANDON`, `ORDER_LATE`, `WC_QUEUE_LONG`, `NO_SEAT`, `NO_PATH`) yazılır: `{minute, guest_id, kind, where}`. Sonuç ekranı bunları gruplayıp “sorun haritası” çıkarır.

## 10. Test örnekleri
- Tek WC + 20 misafir: kuyruk uzunluğu ve terk sayısı beklenen aralıkta.
- Servis masası mutfağa 2 hücre / 15 hücre: ortalama teslim süresi farkı ≥ %40.
- Kapı kapalıysa (yol yok): `NO_PATH` olayı ve etkinlik başlatma uyarısı.

## 11. Uygulama notları (Faz 1, dilim 1c)
Koda geçen ve belgeden **sadeleşen** noktalar (sayılar `data/tuning.json` → `sim`):
- İhtiyaçlar: açlık, eğlence, tuvalet, sabır. Konfor/sosyal/susuzluk henüz yok. Eğlence yalnız müzik açıkken hızlı artar (`music: true` bayrağı olan eşya, şimdilik DJ).
- Durumlar: DECIDING, MOVING, QUEUEING, USING, SEATED, EATING, LEAVING, GONE (ARRIVING/ENTERING birleşti: misafir girişte doğar).
- Koltuk gidilirken **rezerve** edilir; pist ve WC'de slot varışta alınır, doluysa kuyruk. Koltuk için kuyruk yok: boş koltuk yoksa `NO_SEAT` günlüğü ve sabır azalır.
- Sabır yalnız kuyrukta, sipariş beklerken ve koltuk bulamazken azalır (taban 3.0/oyun dk × kişilik); servis edilince +30. 0 olunca misafir ayrılır (`QUEUE_ABANDON`, `ORDER_LATE`, `NO_SEAT`).
- Hedef seçimi bölüm 4'teki fayda formülüyle; histerezis ve acil durum istisnası henüz yok.
- Sipariş akışı: yalnız yemek; mutfak/bar hazırlık süresi yok, garson servis masasında 2 sn bekleyip teslim eder. Servis masası olmazsa sipariş alınmaz.
- Misafir gruplaması, çocuk profili, çarpışma ve kalabalık maliyeti yok.
- Memnuniyet: bölüm 2'deki formül + sabır eksikliği, zaman ortalaması; terk edene −0.15.
- Çıktı: `EventRun.result()` → guest_sat, abandon_count, meals/dances/wc_uses, avg_order_wait_s, kuyruk zirveleri, olay günlüğü. Yıldız ve itibar dilim 1d.
