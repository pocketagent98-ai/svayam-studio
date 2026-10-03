# Skill: vertical-slice

Builds the smallest thing that is a real, playable game (rule R4).

## Slice contents
boot -> menu -> one full loop -> one polished level -> UI -> audio ->
save/load -> fail/retry -> settings -> perf measurement.

## Rule
No production/content scale-up until the slice passes the gate in
`orchestrator/qa/gate.py`.
