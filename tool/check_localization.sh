#!/usr/bin/env bash
set -euo pipefail

echo "Generating localizations..."
flutter gen-l10n

echo "Checking for untranslated messages..."
python3 - <<'PYTHON'
import json
from pathlib import Path

report = Path("build/l10n_untranslated.txt")

if not report.exists():
    raise SystemExit("Localization report was not generated.")

data = json.loads(report.read_text())

if data:
    print("Untranslated localization messages found:")
    print(json.dumps(data, ensure_ascii=False, indent=2))
    raise SystemExit(1)
PYTHON

echo "Running Flutter analyzer..."
flutter analyze

echo "Checking generated localization files are committed..."
if ! git diff --quiet -- \
  lib/l10n/app_localizations.dart \
  lib/l10n/app_localizations_en.dart \
  lib/l10n/app_localizations_es.dart; then
  echo "Generated localization files differ from the committed versions."
  echo "Run flutter gen-l10n and commit the generated files."
  git diff -- \
    lib/l10n/app_localizations.dart \
    lib/l10n/app_localizations_en.dart \
    lib/l10n/app_localizations_es.dart
  exit 1
fi

echo "Localization checks passed."
