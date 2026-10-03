# Etkinlik Tycoon: proje notu

**Durum:** Fikir aşaması. Kod yazılmadı. (Not tarihi: 3 Ekim 2026)
**Öncelik:** Çini Ustası yayınlandıktan sonra ya da ona paralel olarak, yalnızca tasarım belgesi çalışmasıyla başlanacak.

> **Ürün cümlesi:** Bu oyun bir dekorasyon oyunu değildir. Oyuncunun tasarladığı etkinlik mekânının, gerçek zamanlı çalışan bir işletmeye dönüştüğü yönetim simülasyonudur.

---

## 1. Özet

- **Tür:** Simülasyon / yönetim / tycoon / yapı kurma.
- **Platform:** Önce Windows PC. İleride Android, iOS ve tablet değerlendirilebilir.
- **Yapı:** Tek oyunculu, önce çevrimdışı (offline-first).
- **Oyuncunun rolü:** Küçük bir organizasyon mekânının sahibi. 250 m² alan, sınırlı sermaye, düşük itibar ve temel ekipmanla başlar. Hedefi bölgenin en prestijli etkinlik işletmesini kurmak.
- **Temel döngü (oyunun omurgası):**
  Müşteri talebi → teklif → sözleşme → hazırlık → etkinlik → canlı operasyon → müşteri değerlendirmesi → gelir/gider → yatırım → daha büyük müşteri

---

## 2. Tasarım fikirleri

### 2.1 250 m² alan
- Alan tamamen oyuncunun kontrolünde. Yapı modunda duvar ekleyebilir, silebilir, değiştirebilir.
- Örnek bölümler: ana salon, dans pisti, sahne, DJ bölümü, bar, mutfak, WC, depo, personel alanı, giriş/resepsiyon, fotoğraf alanı, VIP alanı.
- Oyun "bu oda mutlaka burada olacak" dememeli; oyuncuya mümkün olduğunca özgürlük verilmeli.

### 2.2 Yapı modu (Build Mode)
Oyunun en güçlü taraflarından biri olmalı. Oyuncu katalogdan nesne seçip yerleştirir:
- **Mobilya:** masa, sandalye, koltuk, bar taburesi, VIP koltukları.
- **Dekorasyon:** çiçek, perde, balon, kemer, masa süsü, duvar kaplaması, halı, bitki.
- **Teknik ekipman:** hoparlör, subwoofer, DJ seti, mikrofon, projektör, LED ekran, sahne ışığı, spot, lazer.
- **Operasyon:** buzdolabı, fırın, servis masası, raf, çöp kutusu, bulaşık alanı.

Her nesnenin görüntüsünün yanında istatistikleri de olmalı. Böylece pahalı eşya yalnızca kozmetik olmaz. Örnek:
```
Profesyonel Hoparlör
Fiyat: 18.000 TL
Ses kalitesi: +22
Prestij: +8
Elektrik tüketimi: 4
Dayanıklılık: 82/100
```

### 2.3 Çoklu değerlendirme (tek "mekân puanı" yok)
Beş ana değer: **Prestij, Konfor, Eğlence, Servis, Güvenlik.**
- Kristal avize prestij verir ama servis vermez. Geniş mutfak servis verir ama prestij beklentisini karşılamaz.
- Alan ve para sınırlı olduğu için oyuncu her şeyi en yükseğe çıkaramaz. Strateji buradan doğar.

### 2.4 Müşteri sistemi
Sürekli farklı müşteriler gelir. Örnek:
```
Ayşe & Emre
Etkinlik: Nişan
Misafir: 65
Bütçe: 48.000 TL
Tema: Romantik
Beklenti: Prestij ≥ 60, Eğlence ≥ 45
Özel istek: Fotoğraf köşesi
Tarih: Cumartesi
```
- Oyuncu işi kabul eder, reddeder ya da teklif verir (42.000 / 46.000 TL / özel fiyat).
- Müşteri teklifi kabul etmeyebilir. Böylece küçük bir pazarlık sistemi oluşur.

### 2.5 Etkinlik türleri
- **Başlangıç:** Doğum günü, nişan, kına, mezuniyet, şirket etkinliği.
- **İleride:** Düğün, balo, VIP parti, yılbaşı, lansman, gala gecesi, ünlü organizasyonu.
- Her tür farklı değerlere ağırlık verir. Çocuk doğum gününde eğlence ve güvenlik, gala gecesinde prestij ve servis öne çıkar.

### 2.6 Etkinlik günü (oyunun kalbi)
- "Etkinliği Başlat" denince yapı modu kapanır, kapılar açılır.
- Misafirler gelir, masalarına oturur. Garsonlar servis yapar, DJ müzik çalar, insanlar dans eder, bar ve mutfak çalışır.
- Oyuncu artık tasarımcı değil, işletme yöneticisidir.

### 2.7 NPC davranışı
- **İhtiyaçlar:** açlık, susuzluk, eğlence, konfor, tuvalet, sosyal ihtiyaç, sabır.
- Acıkan misafir servis bekler; yemek gelmezse memnuniyeti düşer. Dans etmek isteyen misafir pist doluysa bekler ya da başka bir şey yapar. WC kuyruğu uzarsa memnuniyet düşer.
- NPC'ler birbirinin aynısı gibi davranmamalı (kişilik ve tercih farkları).

### 2.8 Canlı problemler (rastgele olaylar)
Örnek: **Hoparlör bozuldu.**
- Teknisyen çağır (2.000 TL)
- Yedek sistemi kullan (ses kalitesi −20)
- Böyle devam et

Diğer olaylar: elektrik sorunu, garsonun gelmemesi, yemeğin gecikmesi, misafir kavgası, pastanın düşmesi, DJ'in geç kalması, WC arızası, ekstra masa talebi, VIP misafir gelmesi, klima arızası, dekorasyonun devrilmesi, yağmur yüzünden dış alanın kullanılamaması.

### 2.9 Personel
- Türler: garson, aşçı, barmen, temizlik görevlisi, güvenlik, DJ, teknisyen, organizasyon sorumlusu.
- Değerler: maaş, hız, deneyim, moral, yetenek. Ucuz garson yavaştır; deneyimli garson pahalıdır ama aynı sürede daha çok masaya bakar.

### 2.10 Ekonomi
- **Gelir:** organizasyon ücreti, ekstra hizmetler, bar, VIP paketler.
- **Gider:** personel, yiyecek-içecek, elektrik, bakım, dekorasyon, ekipman, reklam, kira, vergi.
- Etkinlik sonu ekranı örneği:
```
Organizasyon geliri:  54.000 TL
Personel:             −8.500 TL
Catering:            −12.400 TL
Elektrik:             −1.300 TL
Hasar:                −2.000 TL
Net kâr:              29.800 TL
```

### 2.11 İtibar
- Müşteri etkinlik sonunda puan ve yorum bırakır. Örnek: ★★★★☆ "Salon çok güzeldi fakat yemek servisi biraz gecikti."
- İtibar yükseldikçe daha zengin müşteriler gelir.
- Basamaklar: Mahalle organizasyon salonu → Popüler etkinlik mekânı → Prestijli Event House.

### 2.12 Sosyal medya
- Her başarılı etkinlikten sonra sanal bir sosyal medya gönderisi oluşur. Örnek: "📸 Dün geceki nişan organizasyonumuz ❤️ · ❤️ 1.248 · 💬 73 · Yeni takipçi: +286"
- Takipçi arttıkça müşteri sayısı ve kalitesi artar. Oyuncu reklam bütçesi de ayırabilir.

### 2.13 Teknoloji ağacı
Örnek açılma sırası: Seviye 1 temel masa/sandalye ve basit DJ · Seviye 5 profesyonel ses sistemi · Seviye 10 LED duvar · Seviye 15 VIP dekorasyon · Seviye 20 otomatik ışık sistemi · Seviye 25 premium catering.

### 2.14 Alan genişletme (ilk sürümde yok)
250 → 400 → 750 → 1.500 m². İlk sürüm tamamen 250 m² üzerinde çalışabilir.

### 2.15 Başarısızlık mümkün olmalı
- Yanlış yatırım zarar ettirir. Bütün parayı dekorasyona yatırıp personeli ihmal eden oyuncunun etkinliği çöker.
- Borçlanma, itibar kaybı, rezervasyon iptali, uzun süre zarar edilirse işletmenin kapanması.
- Kurtarma kredisi ya da yeniden başlama seçenekleri sunulabilir.

### 2.16 Görsel tarz
- Ultra gerçekçi değil; stilize 3D ya da yarı gerçekçi. Temiz, sıcak, kaliteli görünüm.
- Kamera: izometrik üstten görünüm, serbest döndürme ve yakınlaştırma. Yapı modunda yukarıdan; etkinlik sırasında aşağı inip misafirlerin arasında izlenebilir.

---

## 3. Değerlendirme (Claude, 3 Ekim 2026)

**Güçlü yanlar:**
- Özgün ve Türkiye'ye çok yakışan bir konu (kına, nişan, düğün salonu kültürü).
- Bu türde oyuncuyu bağlayan şey, kurduğu düzenin işe yarayıp yaramadığını görmek. Fikrin merkezinde de bu var.
- Çoklu değerlendirme ve "her şeyi en yükseğe çıkaramazsın" kısıtı, sağlam bir strateji temeli.

**Riskler:**
1. **3D içerik en büyük engel.** Kod yazılabilir, ama 3D model, doku ve karakter animasyonu (yemek yiyen, dans eden, kuyrukta bekleyen misafirler) yapay zekâyla kodla üretilemez. Hazır paket (lisansına dikkat ederek) ya da bir 3D sanatçı gerekir.
2. **Test zorluğu.** Godot veya Unity'de görsel davranış hatalarını metin üzerinden çözmek yavaş; editörün çalıştırılıp gözlemlenmesi gerekir.
3. **Sistemler birbirine bağlı.** Yapı modu, yol bulma, NPC ihtiyaçları, personel ve ekonomi birlikte çalışmadan oyun oynanabilir olmuyor; MVP'nin en küçük hâli bile büyük.
4. **Dağıtım.** PC'de Steam ücretli satış (Steam Direct kaydı uygulama başına 100 dolar) ve önceden "istek listesi" toplamak için tanıtım gerekiyor.

**Öneri:**
- **Motor:** Godot (ücretsiz, hafif, 2D ve 3D destekli; GDScript metin tabanlı olduğu için birlikte çalışmaya uygun). Unity de olur ama lisans ve kurulum yükü daha fazla.
- **Önce 2D prototip, sonra 3D.** Üstten bakışlı ya da 2D izometrik bir prototiple çekirdek döngünün eğlenceli olup olmadığı test edilmeli. Prison Architect ve RimWorld gibi başarılı yönetim oyunları da 2D. Döngü 2D'de keyifliyse görseller sonra 3D'ye taşınır ya da 2D'de kalınabilir.

---

## 4. Kapsam

### 4.1 Prototip (yalnızca "eğlenceli mi?" sorusunu cevaplar)
- Tek salon, ızgara tabanlı yapı modu.
- 10 eşya (masa, sandalye, DJ, servis masası, bar, WC, dekorasyon birkaç tane).
- 1 etkinlik türü, 10 misafir, 1 garson.
- Misafir ihtiyaçları: açlık, eğlence, tuvalet, sabır.
- Etkinlik sonu gelir/gider ve memnuniyet ekranı.
- Basit 2D görseller (renkli kareler bile olabilir).

### 4.2 MVP (orijinal hedef)
250 m² tek salon → yapı modu → 20–30 eşya → masa/sandalye yerleştirme → bir DJ alanı → bir servis alanı → 3 etkinlik türü → yaklaşık 20 NPC → temel NPC ihtiyaçları → 2 personel türü → etkinliği başlat → gelir/gider → müşteri memnuniyeti → kaydet/yükle.

**MVP'nin asıl testi:** Oyuncu boş mekânı düzenleyebiliyor mu, bir etkinlik başlatabiliyor mu, NPC'ler kurduğu düzeni gerçekten kullanıyor mu, etkinlik sonunda tasarımının ekonomik sonuçlarını görebiliyor mu? Cevap evetse elimizde oyun var. Arızalar, düşen pasta ve VIP müşteri sonra eklenir.

### 4.3 MVP'de olmayacaklar
Alan genişletme, sosyal medya, teknoloji ağacının tamamı, rastgele olayların çoğu, personel yetenekleri ve moral, pazarlık sistemi, mobil sürüm.

---

## 5. Kod yazmadan önce hazırlanacak belgeler
Orijinal talimat: önce kod değil, tasarım. Sırayla:
1. [ ] Oyun tasarım belgesi (GDD): döngü, etkinlik türleri, değer sistemi, müşteri üretimi, ilerleme.
2. [ ] Teknik mimari: motor seçimi, katmanlar, simülasyon döngüsü (sabit adımlı tick), sahne yapısı.
3. [ ] Oyun durumu modeli: mekân, eşyalar, personel, müşteri, etkinlik, ekonomi.
4. [ ] NPC durum makinesi: ihtiyaç → hedef seçimi → yol bulma → eylem → memnuniyet etkisi.
5. [ ] Yapı modu ızgara sistemi: hücre boyutu, duvarlar, kapılar, nesne kaplama alanı, yürünebilirlik.
6. [ ] Ekonomi formülleri: eşya etkileri, beş değerin hesaplanması, müşteri beklentisi karşılaştırması, gelir/gider, itibar değişimi.
7. [ ] Kaydet/yükle veri modeli (sürümlü şema).
8. [ ] Faz planı: prototip → MVP → genişleme.
