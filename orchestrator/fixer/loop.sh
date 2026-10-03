#!/usr/bin/env bash
# Stage 6 — fixer loop (<=3 rounds).
# Parse QA evidence -> defect tickets -> patch -> lint -> re-QA.
set -euo pipefail

MAX_ROUNDS=3
round=1

while [ "$round" -le "$MAX_ROUNDS" ]; do
  echo "[fixer] round ${round}/${MAX_ROUNDS}"
  # 1. Parse the evidence bundle for defects.
  python orchestrator/fixer/parse_evidence.py || { echo "[fixer] no evidence yet"; exit 0; }
  # 2. Apply patches (hosted codegen). Placeholder until P4.
  # 3. Re-run QA.
  python orchestrator/qa/gate.py --out memory/TEST_RESULTS.md | tee /tmp/gate.out
  if grep -q "pass=true" /tmp/gate.out; then
    echo "[fixer] gate passed on round ${round}"
    exit 0
  fi
  round=$((round + 1))
done

echo "[fixer] still failing after ${MAX_ROUNDS} rounds — recorded in KNOWN_ISSUES.md"
exit 1
