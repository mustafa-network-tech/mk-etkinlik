# Etkinlik Tycoon

Etkinlik mekânı yönetim simülasyonu (Godot 4.4.1). Tasarım belgeleri: [docs/](docs/README.md).

## Testler
```
tests/run.sh   # motor hatası olursa da başarısız sayar
```

## Klasörler
`sim/` saf simülasyon · `commands/` oyuncu komutları · `data/` katalog ve ayarlar · `tests/` testler · `presentation/` sahne ve UI · `tools/` geliştirici araçları.

## Çalıştırma
Godot 4.4.1 ile `project.godot` açılır ya da `godot --path .`. Ekran görüntüsü aracı (sanal ekran):
```
xvfb-run -a -s "-screen 0 1280x720x24" godot --path . --rendering-driver opengl3 --script tools/screenshot.gd -- <klasör>
```
Kontroller: sol listeden eşya seç, haritada sol tık yerleştirir, sağ tık siler, `R` döndürür; "Duvar" aracı en yakın hücre kenarına duvar koyar.
