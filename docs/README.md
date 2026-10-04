# Etkinlik Tycoon: tasarım belgeleri

Kod yok; önce tasarım. Okuma sırası:

| # | Belge | Cevapladığı soru |
|---|-------|------------------|
| 1 | [01-GDD.md](01-GDD.md) | Oyun ne, döngü nasıl, MVP sınırı nerede? |
| 2 | [02-ARCHITECTURE.md](02-ARCHITECTURE.md) | Motor, katmanlar, simülasyon döngüsü |
| 3 | [03-STATE-MODEL.md](03-STATE-MODEL.md) | Oyun durumu hangi veri yapılarından oluşur? |
| 4 | [04-NPC-STATE-MACHINE.md](04-NPC-STATE-MACHINE.md) | Misafir ve personel nasıl karar verir? |
| 5 | [05-BUILD-GRID.md](05-BUILD-GRID.md) | Yapı modu ızgarası, duvar, kapı, yürünebilirlik |
| 6 | [06-ECONOMY.md](06-ECONOMY.md) | Beş değer, müşteri beklentisi, gelir/gider, itibar formülleri |
| 7 | [07-SAVE-LOAD.md](07-SAVE-LOAD.md) | Sürümlü kayıt şeması |
| 8 | [08-ROADMAP.md](08-ROADMAP.md) | Faz planı, çıkış kriterleri, riskler |
| — | [DECISIONS.md](DECISIONS.md) | Alınan kararlar (motor, varlık, dil, para) |

Önceki not: [PROJE_NOTU.md](PROJE_NOTU.md).

## Sayılar nerede?
Bu belgelerdeki tüm sayılar **başlangıç tahminidir**. Denge ayarı prototipte yapılacak; sayılar kodda değil, veri dosyalarında (`data/*.json`) durur.

## Kararlar (özet, ayrıntı DECISIONS.md)
1. **Motor:** Godot 4 (GDScript); sürüm kurulumda kilitlenir.
2. **3D içerik:** prototipte kutular, MVP’de lisanslı CC0/açık paketler, sanatçı kararı Faz 3’te.
3. **Dil:** Türkçe + İngilizce, çeviri tablosuyla baştan.
4. **Değerler:** gerçekçi TL, hepsi veri dosyalarında.
