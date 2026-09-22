#!/usr/bin/env bash
set -euo pipefail

REPO="${1:?uso: $0 owner/repo}"
OUT="metrics"
mkdir -p "$OUT"

gh api "repos/$REPO/actions/artifacts" --paginate \
  --jq '.artifacts[]
        | select(.name | startswith("pr-metrics-"))
        | select(.expired | not)
        | "\(.id) \(.name)"' |
while read -r id name; do
  gh api "repos/$REPO/actions/artifacts/$id/zip" > "$OUT/$name.zip"
  unzip -o -q "$OUT/$name.zip" -d "$OUT/$name"
  rm "$OUT/$name.zip"
done

jq -s '.' "$OUT"/*/metrics.json > all-metrics.json

jq '{
  execucoes: length,
  custo_total_usd: (map(.claude_cost_usd) | add),
  custo_medio_usd: (map(.claude_cost_usd) | add / length)
}' all-metrics.json