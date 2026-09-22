#!/usr/bin/env bash
set -euo pipefail

INPUT="${1:-shadow.json}"
JEV_PRICE_PER_TOKEN=0.000000042

for T in 0.5 1.0 1.5 2.0 2.5; do
  jq --argjson t "$T" --argjson p "$JEV_PRICE_PER_TOKEN" '
    map(
      .triage //= [] | .findings //= []
      | ((.triage | length) > 0 and all(.triage[]; .risk != null and .risk < $t)) as $pular
      | {
          pr,
          pular: $pular,
          economia_usd: (if $pular then .claude_cost_usd else 0 end),
          custo_jev_usd: ((.triage | map(.input_tokens // 0) | add // 0) * $p),
          perdidos: (if $pular
                     then [.findings[] | select(.severity == "high" or .severity == "critical")]
                     else [] end)
        }
    )
    | {
        limiar: $t,
        prs_pulados: (map(select(.pular)) | length),
        economia_liquida_usd: ((map(.economia_usd) | add) - (map(.custo_jev_usd) | add)),
        achados_graves_perdidos: (map(.perdidos[]) )
      }
  ' "$INPUT"
done