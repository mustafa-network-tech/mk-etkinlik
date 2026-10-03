# 08 · Faz planı

İlke: her faz bir **soruya** cevap verir ve bir **çıkış kriteri** ile biter. Kriter sağlanmadan sonraki faza geçilmez. Tamamlanmayan iş “yarım” işaretlenir.

## Faz 0 · Tasarım (şu an)
- [x] GDD, mimari, durum modeli, NPC makinesi, ızgara, ekonomi, kayıt, yol haritası taslakları.
- [x] Açık soruların kapatılması: motor, 3D içerik kaynağı, dil, değerler (bkz. DECISIONS.md).
- [x] `docs/DECISIONS.md` oluşturuldu (motor sürümü: 4.4.1).
- **Çıkış:** Sahibi motor ve MVP kapsamını onayladı. (Karar sahibi “sen karar ver” dedi; Faz 1 başladı.)

## Faz 1 durumu (yarım)
- [x] Dilim 1a: proje iskeleti, katalog, ızgara, duvar, `PlaceItem`/`RemoveItem`/`AddWall`/`RemoveWall`, erişilebilirlik raporu, 14 test yeşil.
- [x] Dilim 1b: kaydet/yükle (07), beş değer statik tahmini (06 §2); toplam 29 test yeşil.
- [ ] Dilim 1c: simülasyon döngüsü, misafir ihtiyaçları, yol bulma (04).
- [ ] Dilim 1d: sonuç ekranı ve 2D sunum.

## Faz 1 · Prototip — “Eğlenceli mi?”
Kapsam: Godot projesi, 2D üstten görünüm, ızgara yapı modu, 10 eşya, 1 etkinlik türü, 10 misafir, 1 garson, 4 ihtiyaç (açlık, eğlence, tuvalet, sabır), basit sonuç ekranı. Renkli kutular.
- **Çıkış kriteri:** (a) boş salon → 10 dk içinde ilk etkinlik, (b) iki yerleşim → farklı sonuç, (c) sonuç ekranından somut ders çıkarılıyor. Hayırsa tasarım gözden geçirilir; 3D’ye geçilmez.
- Çıktı: sim çekirdeği (headless testli), komut katmanı, temel UI.

## Faz 2 · MVP — oynanabilir çekirdek
Kapsam: 250 m² salon, 20–30 eşya, duvar çizme, masa/sandalye, DJ ve servis alanı, 3 etkinlik türü, ~20 NPC, ihtiyaçlar, 2 personel türü, müşteri talebi+teklif (basit), etkinlik başlat, gelir/gider, itibar, kaydet/yükle.
- **Çıkış kriteri:** GDD §11 MVP kabul testi + 06 §10 denge senaryoları + kayıt testleri yeşil + 5 dış oyuncuyla tek oturum (kılavuzsuz).
- Dilimler: (1) sim+nav, (2) yapı modu+komutlar, (3) NPC+sipariş, (4) ekonomi+müşteri, (5) kayıt, (6) cila.

## Faz 3 · 3D geçiş
Sunum katmanı 3D’ye taşınır: stilize modeller, 4–5 karakter animasyonu, kamera, ışık, ses. Sim değişmez.
- **Çıkış:** 30+ dakika kesintisiz oynanış, 60 FPS hedef (orta seviye PC), lisans listesi tam.

## Faz 4 · Genişleme (sırayla, her biri ayrı karar)
1. Rastgele olaylar (hoparlör arızası, düşen pasta, VIP).
2. Personel yeteneği/moral, ek roller.
3. Pazarlık sistemi tamamı, sosyal medya, reklam.
4. Teknoloji ağacının tamamı (L10–L25).
5. Alan genişleme (400/750/1500 m²).
6. Daha fazla etkinlik türü, balo, gala.
7. Mobil/tablet (UI + performans).

## Faz 5 · Yayın
Steam mağaza sayfası (istek listesi için erken), yayın kaydı (Steam Direct, uygulama başına 100 USD), fiyatlandırma, lokalizasyon, test, kayıt göçü politikası.

## Riskler
| Risk | Etki | Önlem |
|------|------|-------|
| 3D içerik üretimi | Çok yüksek | Önce 2D prototip; sim≠sunum; lisanslı paket/sanatçı planı Faz 3 öncesi |
| Görsel hataların metinle çözümü | Yüksek | Saf sim çekirdeği + headless testler + olay günlüğü + ısı haritası |
| Sistemler birbirine bağlı | Yüksek | Dilimler dikey (her dilim oynanabilir); MVP kesin sınır |
| Denge | Orta | Veri dosyaları + bot senaryoları |
| Kapsam kayması | Yüksek | MVP dışı liste GDD’de sabit; yeni fikir → Faz 4 listesi |
| Tek kişilik geliştirme süresi | Yüksek | Küçük, ölçülebilir çıkış kriterleri |

## İlk somut adım (onaydan sonra)
1. `docs/DECISIONS.md`: motor sürümü ve gerekçe.
2. Godot projesi iskeleti (`sim/`, `commands/`, `presentation/`, `tests/`), test çerçevesi.
3. `GameState`, ızgara ve `PlaceItem` komutu + testleri (Faz 1, dilim 1).
