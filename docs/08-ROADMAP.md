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
- [x] Dilim 1c: sabit adımlı etkinlik simülasyonu (`sim/event_run.gd`), A*, ihtiyaçlar, istasyon kuyrukları, garson sipariş akışı, olay günlüğü; toplam 42 test yeşil.
- [x] Dilim 1d-mantık: etkinlik sonucu (beklenti eşleşmesi, yıldız, gelir/gider, itibar), müşteri talebi ve teklif kabulü, 50 test yeşil.
- [x] Dilim 1d-sunum: 2D ana ekran (`presentation/`): yapı modu (yerleştir/duvar/sil/döndür), talep ve teklif, personel, beş değer çubukları, etkinlik izleme (1x/2x/4x/duraklat), sonuç paneli, kaydet/yükle, TR/EN çeviri tablosu (`data/strings.json`). Ekran görüntüleri: `docs/img/`.
- [x] Dilim 1e: aşçı simülasyona bağlandı (mutfak sırası), barmen listeden çıktı; katalog 10 eşya ve denge (başlangıç kasasıyla ≥3 yıldız testi); XP/seviye; kira, borç faizi, iflas ve yeniden başlama; kayıt şeması 2. Testler Windows’ta da koşuldu; toplam 64 test yeşil.
- [ ] Faz 1 çıkış kriteri (yarım): bir insan oyuncuyla 10 dakikalık deneme henüz yapılmadı. Aşağıdaki "Bilinen eksikler"e bakın.

### Bilinen eksikler (Faz 1)
- Arayüz yalnız sanal ekranda (xvfb) doğrulandı; fare etkileşimi (tıklayıp yerleştirme, duvar kenarı seçimi, sağ tık silme) elle denenmedi.
- Yazı tipi motorun varsayılanı; ayrı yazı tipi ve görsel cila yok.
- Kayıt yalnız mekân/kasa/seviye/XP/itibar/gün/iflas sayacı; sözleşme, talep ve personel sayıları yüklemede yeniden üretilir (kabul edilmiş sözleşme yüklemede kaybolur).
- Denge: bkz. docs/06 §11-12.

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
