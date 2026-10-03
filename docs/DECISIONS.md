# Kararlar

Tarih: 3 Ekim 2026. Karar veren: proje sahibi “sen karar ver” dedi; öneriler Claude’a ait ve geri alınabilir.

## K1 · Motor: Godot 4 (GDScript)
- **Karar:** Godot 4, simülasyon çekirdeği GDScript (saf, Node’suz).
- **Gerekçe:** ücretsiz, 2D+3D, metin tabanlı sahne/betik (birlikte çalışmaya uygun), headless test, Windows ve ileride mobil dışa aktarma.
- **Sürüm:** Proje kurulurken güncel kararlı Godot 4.x seçilip burada kilitlenecek (şimdi tahmin etmiyoruz).
- **Geri dönüş koşulu:** Prototipte 30 NPC ile 60 FPS tutmuyorsa C# (Godot .NET) değerlendirilir. Unity’ye geçiş yalnızca sunum katmanını etkiler.

## K2 · Varlık stratejisi
- **Prototip:** renkli kutular, hiçbir dış varlık yok.
- **MVP:** önce CC0 veya açık lisanslı düşük çokgenli paketler (lisans her paket için `docs/ASSETS.md`’de: kaynak, lisans, tarih). Ticari kullanımı açıkça izin vermeyen paket alınmaz.
- **Sonra:** satış öncesi ana eşyalar ve karakterler için 3D sanatçı (bütçe kalırsa). Karar noktası: Faz 3 başlangıcı.
- Gerekçe: 3D içerik en büyük risk; satın alma kararını oyunın eğlenceli olduğu kanıtlanana kadar ertelemek parayı korur.

## K3 · Dil
- **Karar:** Türkçe + İngilizce, ilk günden. Tüm kullanıcı metni çeviri tablosunda (anahtar → metin); kodda sabit metin yok. İçerik önce Türkçe yazılır, İngilizce MVP bitimine kadar tamamlanır.
- Gerekçe: sonradan metin ayıklamak pahalı; İngilizce Steam erişimi için gerekli.

## K4 · Para ve değerler
- **Karar:** Gerçekçi TL değerleri (brief’teki örnekler: 18.000 TL hoparlör, 48.000 TL bütçe). Tüm sayılar `data/*.json`’da; para birimi gösterimi bir ayar olmalı (gelecekte sembol/format değişimi).
- Gerekçe: Türkiye teması oyunun kimliği; enflasyon etkisi oyun içinde modellenmez, sabit tutulur (denge bozulmasın).

## K5 · Depo
- Tasarım belgeleri `docs/`; kod, Faz 0 çıkışından sonra aynı depoda (`sim/`, `commands/`, `presentation/`, `tests/`).

## Faz 0 durumu
Açık sorular (motor, 3D kaynağı, dil, değerler) yukarıda kapatıldı. Faz 0 çıkışı için kalan: sahibinin bu kararları ve MVP kapsamını gözden geçirmesi.

## K6 · Godot sürümü ve test aracı (4 Ekim 2026)
- **Sürüm:** Godot **4.4.1-stable** (linux x86_64 ile headless doğrulandı). Yükseltme ayrı karar.
- **Test:** Harici eklenti yok; `tests/run_tests.gd` küçük bir koşucu (`test_*.gd` dosyalarında `test_*` metotları). Gerekçe: bağımlılık yok, CI'da tek komut. Yetersiz kalırsa gdUnit4'e geçilir.
- **Komut:** `tests/run.sh`. Godot çalışma zamanı hataları testi yarıda kesip sayıma yansımadığı için betik, çıktıda `SCRIPT ERROR`/`ERROR:` görürse de çıkış kodu 1 verir.
