# 07 · Kaydet / yükle veri modeli

## 1. İlkeler
- **Sürümlü şema:** her dosyada `schema_version` tamsayısı. Yeni sürüm = eski sürümden otomatik **göç (migration)** fonksiyonu zinciri.
- **Yalnızca kalıcı durum** kaydedilir; türetilmiş veri (nav ızgarası, önbellek) yüklemede yeniden üretilir.
- **Katalog kimlikle:** eşya tanımı kayda gömülmez, `def_id` ile anılır. Katalog değişince eski kayıt bozulmaz; bilinmeyen `def_id` “kayıp eşya”: nakit iadesi + uyarı.
- **Atomik yazma:** önce `slot.json.tmp`, sonra yeniden adlandır; önceki kayıt `slot.json.bak` olarak bir sürüm saklanır.
- **Bütünlük:** her dosyada `checksum` (SHA-256 gövde). Doğrulama başarısızsa `.bak`’tan dene, olmazsa kullanıcıya bildir (sessiz silme yok).
- Konum: `user://saves/slot_N.json` (Godot kullanıcı veri klasörü). Çevrimdışı; bulut yok.
- **Etkinlik sırasında kayıt:** MVP’de yalnızca etkinlikler arasında (hazırlık modunda) otomatik/elle kayıt. Canlı etkinlik ortası kayıt MVP sonrası (NPC, sipariş, kuyruk durumu da serileştirilmeli).

## 2. Zarf (envelope)
```json
{
  "schema_version": 1,
  "game_version": "0.1.0",
  "saved_at": "2026-10-03T18:00:00Z",
  "checksum": "sha256:…",
  "state": { … GameState (03) … }
}
```

## 3. Durum gövdesi (özet)
```json
{
  "seed": 12345,
  "rng": {"guests": 111, "events": 222, "decisions": 333},
  "clock": {"day": 14, "minute": 600},
  "finance": {"cash": 84200, "debt": 0, "ledger": []},
  "reputation": {"points": 312, "reviews": []},
  "progression": {"level": 3, "xp": 540, "unlocked": ["table_round_8", "dj_basic"]},
  "venue": {
    "width": 40, "height": 25,
    "walls": [{"x": 10, "y": 5, "edge": "E", "kind": "wood"}],
    "openings": [{"x": 10, "y": 8, "edge": "E", "kind": "door", "width": 2}],
    "items": [{"id": 1, "def": "table_round_8", "x": 12, "y": 9, "rot": 0, "cond": 1.0}]
  },
  "inventory": [],
  "staff": [{"id": 1, "role": "waiter", "wage": 280, "speed": 1.0, "exp": 0}],
  "contracts": [], "lead_pool": [], "history": [],
  "next_id": 42
}
```

## 4. Göç
```
func migrate(state: Dictionary, from: int) -> Dictionary:
    while from < CURRENT_VERSION:
        state = MIGRATIONS[from](state)   # from → from+1
        from += 1
    return state
```
- Her göç saf fonksiyon, kendi birim testi ve örnek eski dosyasıyla (`tests/fixtures/save_v1.json`).
- **Yeni sürümün kaydı eski sürümde açılmaz** (ileri uyumluluk yok): `schema_version > CURRENT` ise “oyunu güncelle” uyarısı.
- Göçten önce dosya `.pre_migrate.bak` olarak kopyalanır.

## 5. Ayarlar ayrı dosya
`user://settings.json`: grafik, ses, dil, kontroller. Kayıttan bağımsız, kendi sürümü.

## 6. Test listesi
- Yükle→kaydet→bayt bayt eş (stabil anahtar sırası).
- Bozuk dosya, eksik alan, bilinmeyen `def_id`, gelecek sürüm, yarım yazma (tmp mevcut) senaryoları.
- Aynı seed + aynı komutlar, kayıt/yükle sonrası aynı sonuca götürür (determinizm).
