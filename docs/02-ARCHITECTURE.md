# 02 · Teknik mimari

## 1. Motor kararı
**Öneri: Godot 4 (GDScript).** Gerekçe:
- Ücretsiz, hafif, 2D ve 3D birlikte; Windows’a dışa aktarma kolay, ileride Android/iOS mümkün.
- Sahneler (`.tscn`) ve betikler düz metin → birlikte çalışmaya, sürüm kontrolüne uygun.
- Headless çalıştırma (`godot --headless`) ile simülasyon testleri CI’da koşabilir.

Alternatif Unity (C#): daha geniş varlık mağazası, ama lisans/kurulum yükü ve ikili sahne dosyaları. Flutter bu iş için uygun değil (gerçek zamanlı 3D simülasyon motoru değil).

**Kurulumda doğrulanacak:** sabit Godot 4.x sürümü seçilip `docs/DECISIONS.md`’ye yazılacak; proje o sürüme kilitlenir.

## 2. Altın kural: simülasyon ≠ görüntü
```
┌──────────────────────────────────────────────┐
│ Sunum (Godot sahneleri, kamera, UI, ses)    │  ← durumu OKUR, çizer
├──────────────────────────────────────────────┤
│ Komut katmanı (oyuncu eylemleri → komutlar)  │
├──────────────────────────────────────────────┤
│ Simülasyon çekirdeği (saf GDScript, Node yok)│  ← tek doğruluk kaynağı
├──────────────────────────────────────────────┤
│ Veri (katalog JSON, kayıt dosyaları)         │
└──────────────────────────────────────────────┘
```
- Simülasyon çekirdeği `RefCounted`/`Resource` sınıflarından oluşur; `Node`, `SceneTree`, `Input` bilmez.
- Sunum katmanı yalnızca durumu okur ve komut gönderir. Böylece:
  - 2D prototip → 3D’ye geçişte yalnızca sunum değişir.
  - Simülasyon birim testlerle görsel olmadan doğrulanır (bu, “görsel hata metinle çözülemez” riskinin ana çaresi).

## 3. Klasör yapısı (öneri)
```
project.godot
data/            katalog ve ayar JSON (items, event_types, staff, tuning)
sim/             saf simülasyon (state, grid, nav, needs, economy, events)
commands/        oyuncu komutları (PlaceItem, RemoveWall, StartEvent …)
presentation/    sahneler, kamera, UI, görsel eşleme
save/            serileştirme, şema sürümleri, göç
tests/           gdUnit4 veya GUT testleri (sim/ için)
docs/
```

## 4. Simülasyon döngüsü (sabit adım)
- Sabit adım: **10 Hz** (`dt = 0.1 s` oyun-dışı gerçek zaman). Çizim kare hızından bağımsız.
- Hız çarpanı 1x/2x/4x = saniyede 1/2/4 `step()` yerine adım başına süre ölçeği; **çekirdek her zaman aynı `dt` ile çalışır**, hızlandırma = saniyede daha çok adım. (Determinizm korunur.)
- Oyun saati: 1 oyun dakikası = 1.5 gerçek sn (1x). 4 saatlik etkinlik ≈ 6 dk gerçek.
- Adım sırası (her `step`):
  1. Zaman ve olay zamanlayıcıları
  2. Misafir/personel ihtiyaç azalması
  3. Karar (NPC’lerin yalnızca 1/5’i her adımda; sıra dönüşümlü, bütçeli)
  4. Hareket ve yol izleme
  5. İstasyon kullanımı ve kuyruklar
  6. Servis/mutfak/bar kuyrukları
  7. Memnuniyet ve metrik güncelleme
  8. Sinyaller (olay günlüğü) → sunum

## 5. Determinizm
- Tek `seed` + sistem başına ayrı `RandomNumberGenerator` (misafir üretimi, olaylar, karar gürültüsü).
- Aynı kayıt + aynı komut dizisi = aynı sonuç. Hata yeniden üretimi ve denge testleri için şart.
- Yasak: simülasyonda `randf()` global çağrısı, duvar saati zamanı, sözlük sırasına bağımlı mantık.

## 6. Komut modeli
Oyuncu etkisi her zaman bir komuttur: `{type, args, tick}`. Çekirdek komutu doğrular (para, alan, çakışma) ve uygular ya da `Result.error(reason)` döner. Faydaları: geri al/yinele (yapı modu), test, olası tekrar oynatma.

## 7. Performans bütçesi
- MVP: ≤ 30 NPC, 1000 hücre. Basit A* yeterli.
- Yol bulma: hücre ızgarasında A*, sonuç önbelleği; sık hedefler (çıkış, WC, bar) için ileride akış alanı.
- Karar bütçesi: adım başına en çok N NPC karar verir (N=8).
- İleri hedef (alan genişleme): 200+ NPC; bu noktada akış alanı + çarpışma kaçınma sadeleştirmesi.

## 8. Test stratejisi
| Katman | Yöntem |
|--------|--------|
| Sim çekirdeği | Birim testler, headless, deterministik |
| Denge | Betikli “bot oyuncu” senaryoları: aynı müşteri, iki yerleşim, beklenen yıldız farkı |
| Kayıt | Her şema sürümü için örnek dosya; yükle→kaydet→karşılaştır |
| Sunum | Elle kontrol listesi + ekran görüntüsü karşılaştırma (sonra) |

## 9. Varlık (asset) stratejisi
- Prototip: renkli kutular, dahili şekiller.
- MVP: tek stilde düşük çokgenli paket (lisansı kayıt altına alınır) ya da sanatçıyla tek tek model.
- Karakter animasyonu sade: yürü, otur, dans, ye/içmek (4–5 klip) — 3D’deki en pahalı kalem.
- Her varlığın lisansı `docs/ASSETS.md`’de listelenir (kaynak, lisans, tarih).

## 10. Mobil notu
Dokunmatik yapı modu, UI ölçekleme ve performans ayrı iştir; MVP’de yok. Mimari (sim ≠ sunum) bunu engellemez.
