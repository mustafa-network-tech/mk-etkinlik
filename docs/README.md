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

Önceki not: [PROJE_NOTU.md](PROJE_NOTU.md).

## Sayılar nerede?
Bu belgelerdeki tüm sayılar **başlangıç tahminidir**. Denge ayarı prototipte yapılacak; sayılar kodda değil, veri dosyalarında (`data/*.json`) durur.

## Açık sorular (sizin kararınız)
1. **Motor:** Godot 4 öneriyorum (bkz. 02). Unity tercih ederseniz belgeler büyük oranda geçerli kalır, yalnızca 02 değişir.
2. **3D içerik kaynağı:** hazır lisanslı paket mi, 3D sanatçı mı? Prototip bu karardan bağımsız (renkli kutular).
3. **Dil:** MVP yalnızca Türkçe mi, TR+EN mi? (Metinler baştan çeviri tablosunda tutulacak.)
4. **Para birimi/değerler:** TL cinsinden gerçekçi değerler mi, oyun dengesine göre sadeleştirilmiş mi?
