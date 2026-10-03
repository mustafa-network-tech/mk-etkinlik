# 01 · Oyun tasarım belgesi (GDD)

> **Ürün cümlesi:** Bu oyun bir dekorasyon oyunu değildir. Oyuncunun tasarladığı etkinlik mekânının, gerçek zamanlı çalışan bir işletmeye dönüştüğü yönetim simülasyonudur.

## 1. Kimlik
- Tür: 3D simülasyon / yönetim / tycoon / yapı kurma. Stilize, sıcak görünüm.
- Platform: önce Windows PC; mobil/tablet sonra değerlendirilir.
- Tek oyunculu, offline-first. Hesap, sunucu, çevrimiçi zorunluluk yok.
- Oyuncu: 250 m² mekânın sahibi. Başlangıç: sınırlı sermaye, düşük itibar, temel ekipman.
- Uzun hedef: bölgenin en prestijli etkinlik işletmesi.

## 2. Çekirdek döngü
```
Müşteri talebi → teklif → sözleşme → hazırlık (yapı modu, personel)
   → etkinlik → canlı operasyon → müşteri değerlendirmesi
   → gelir/gider → yatırım → daha büyük müşteri
```
İki mod vardır ve oyunun ritmi bunların arasındaki geçiştir:

| Mod | Zaman | Oyuncu rolü |
|-----|-------|-------------|
| Hazırlık (Yapı) | Durağan, süre baskısı yok (yalnızca etkinlik tarihi) | Tasarımcı |
| Etkinlik günü | Gerçek zamanlı, hız 1x/2x/4x, duraklatılabilir | Yönetici |

## 3. Tasarım sütunları
1. **Tasarım işe yarar.** Her eşyanın istatistiği var; güzel olan değil, doğru yerleştirilen kazanır. Misafirler düzeni gerçekten kullanır (WC çok uzaktaysa kuyruk olur).
2. **Her şeyi maksimuma çıkaramazsın.** Alan ve para sınırlı; beş değer birbirini kısıtlar.
3. **Sonuç okunabilir.** Etkinlik sonunda oyuncu neden başarılı/başarısız olduğunu görür (ısı haritası, kuyruk süreleri, yorumlar).
4. **Özgürlük.** Oda şablonu yok; duvar ve yerleşim serbest. Oyun yalnızca sonucu değerlendirir.
5. **Başarısızlık mümkün** ama kurtarılabilir (bkz. §9).

## 4. Beş değer
Prestij · Konfor · Eğlence · Servis · Güvenlik (0–100). Tek “mekân puanı” yoktur. Hesap: [06-ECONOMY.md](06-ECONOMY.md).

| Değer | Nereden gelir (örnek) |
|-------|-----------------------|
| Prestij | Avize, zarif dekor, duvar kaplaması, halı, personel deneyimi |
| Konfor | Oturma kapasitesi/misafir, klima, WC oranı, yoğunluk, temizlik |
| Eğlence | Ses kalitesi, DJ, pist kapasitesi, ışık, sahne |
| Servis | Garson/mutfak/bar kapasitesi, servis masası konumu |
| Güvenlik | Çıkışlar, güvenlik görevlisi, yangın ekipmanı, aydınlatma, yoğunluk |

## 5. Müşteri ve sözleşme
Müşteri talebi: etkinlik türü, misafir sayısı, bütçe, tema, beklenti eşikleri (değer ≥ N), özel istek, tarih.
- Oyuncu **kabul / reddet / karşı teklif** verir. Karşı teklifte müşteri kabul etmeyebilir (formül: 06 §6).
- Sözleşme: kabul edilen fiyat, ön ödeme (%20), iptal cezası. Beklentiler karşılanmazsa son ödemeden kesinti.
- Talep havuzu itibar basamağına göre üretilir (basamak ↑ → bütçe ve beklenti ↑).

## 6. Etkinlik türleri ve ağırlıklar
Her tür beş değer için ağırlık vektörü ve davranış profili taşır (veri dosyası `event_types.json`).

| Tür | Prestij | Konfor | Eğlence | Servis | Güvenlik | Not |
|-----|:---:|:---:|:---:|:---:|:---:|-----|
| Doğum günü (çocuk) | 0.5 | 1.0 | 1.5 | 1.0 | 1.5 | Çocuk NPC: kısa sabır, dağılma/devirme riski |
| Nişan | 1.5 | 1.0 | 1.0 | 1.0 | 0.5 | Fotoğraf köşesi istekleri |
| Kına | 1.0 | 1.0 | 1.5 | 1.0 | 0.5 | Uzun dans bloğu |
| Mezuniyet | 0.5 | 1.0 | 1.5 | 1.0 | 1.0 | Yüksek tempo |
| Şirket etkinliği | 1.0 | 1.5 | 0.5 | 1.5 | 1.0 | Sahne/projektör, sessiz konuşma alanı |

İlerleyen: düğün, balo, VIP parti, yılbaşı, lansman, gala (prestij+servis ağır), ünlü organizasyonu.

## 7. Etkinlik günü akışı
1. “Etkinliği Başlat” → yapı modu kilitlenir, kapılar açılır.
2. Misafirler giriş dalgalarıyla gelir (dalga eğrisi türe göre).
3. Misafir ihtiyaçları ([04](04-NPC-STATE-MACHINE.md)) zamanla artar; kendi hedeflerini seçerler.
4. Oyuncu müdahaleleri: personel görevlendirme, müzik temposu, ekstra masa, olay kararları (MVP sonrası).
5. Süre dolunca kapı kapanır, misafirler çıkar, sonuç ekranı.

## 8. Sonuç ekranı
Gelir/gider dökümü, beş değerin beklentiyle karşılaştırması, yıldız (1–5), üretilmiş yorumlar, kuyruk/bekleme ısı haritası, “en büyük sorun” özeti. Itibar ve sermaye güncellenir.

## 9. Başarısızlık
- Zarar → borç → itibar kaybı → iptaller → kapanış.
- Kurtarma: tek seferlik kurtarma kredisi (faizli), eşya satışı (%50 değer), “yeniden başla” (ilerleme korunmaz, istatistik arşivlenir).

## 10. İlerleme
İtibar basamakları: **Mahalle salonu (0–299) → Popüler mekân (300–699) → Prestijli Event House (700+)**. Seviye (deneyim) eşya kataloğunu açar (06 §9). Alan genişletme (400/750/1500 m²) ilk sürüm dışı.

## 11. Kapsam

### Prototip (soru: “eğlenceli mi?”)
Tek salon, ızgara yapı modu, 10 eşya, 1 etkinlik türü, 10 misafir, 1 garson, ihtiyaçlar: açlık/eğlence/tuvalet/sabır, sonuç ekranı, renkli kutular.

### MVP
250 m² salon → yapı modu → 20–30 eşya → masa/sandalye → DJ alanı → servis alanı → 3 etkinlik türü → ~20 NPC → temel ihtiyaçlar → 2 personel türü (garson, aşçı veya barmen) → etkinliği başlat → gelir/gider → memnuniyet → kaydet/yükle.

**MVP kabul testi:** Oyuncu boş mekânı düzenleyip etkinlik başlatabiliyor mu? NPC’ler düzeni kullanıyor mu? Sonuç ekranında tasarımın ekonomik etkisi okunuyor mu? Üçü de evetse oyun vardır.

### MVP dışı
Alan genişletme, sosyal medya, teknoloji ağacının tamamı, çoğu rastgele olay, personel yeteneği/moral, tam pazarlık sistemi, mobil.

## 12. Başarı ölçütleri (prototipte)
- Oyuncu 10 dakikada ilk etkinliğini başlatıyor.
- Aynı müşteri için iki farklı yerleşim belirgin biçimde farklı sonuç veriyor (yıldız farkı ≥ 1).
- Oyuncu sonuç ekranından en az bir somut değişiklik çıkarıyor (“WC’yi pistten uzaklaştırayım”).
