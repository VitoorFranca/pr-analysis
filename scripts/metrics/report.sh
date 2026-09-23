#!/usr/bin/env bash
set -euo pipefail

INPUT="${1:-all-metrics.json}"
OUT="${2:-metrics-report.html}"
TEMPLATE="$(dirname "$0")/report-template.html"
PLACEHOLDER="__METRICS_DATA__"

[ -f "$INPUT" ] || { echo "arquivo não encontrado: $INPUT" >&2; exit 1; }
[ -f "$TEMPLATE" ] || { echo "template não encontrado: $TEMPLATE" >&2; exit 1; }

jq -e 'type == "array"' "$INPUT" > /dev/null \
  || { echo "$INPUT precisa conter um array JSON" >&2; exit 1; }

grep -q "$PLACEHOLDER" "$TEMPLATE" \
  || { echo "template sem o marcador $PLACEHOLDER" >&2; exit 1; }

# Os findings são texto produzido por um LLM sobre um diff de terceiros. Escapar
# "<" como < mantém o JSON válido e impede que a string feche o <script>.
{
  sed "/$PLACEHOLDER/,\$d" "$TEMPLATE"
  jq -c . "$INPUT" | sed 's|<|\\u003c|g'
  sed "1,/$PLACEHOLDER/d" "$TEMPLATE"
} > "$OUT"

echo "$OUT: $(jq length "$INPUT") execuções"
