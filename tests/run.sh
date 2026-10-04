#!/usr/bin/env bash
# CI girişi: Godot çalışma zamanı hataları testi yarıda kesebilir ama sayıma yansımaz,
# bu yüzden çıktıda SCRIPT ERROR / ERROR: varsa da başarısız sayılır.
set -u
cd "$(dirname "$0")/.."
godot --headless --path . --import >/dev/null 2>&1
out=$(godot --headless --path . --script tests/run_tests.gd 2>&1)
status=$?
echo "$out"
if echo "$out" | grep -qE "SCRIPT ERROR|^ERROR:"; then
	echo "Motor hatası bulundu: testler geçse bile başarısız sayılır." >&2
	exit 1
fi
exit $status
