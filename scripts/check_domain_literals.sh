#!/usr/bin/env bash
set -euo pipefail

matches="$(grep -R -n -E --include='*.dart' "porno-social\.com|www\.porno-social\.com|support@porno-social\.com|dmca@porno-social\.com|privacy@porno-social\.com" lib | grep -v "lib/config/app_config.dart" || true)"

if [[ -n "$matches" ]]; then
  echo "Hardcoded domain/email literals found outside lib/config/app_config.dart:"
  echo "$matches"
  exit 1
fi

echo "Domain literal guard passed."