# Skill: game-designer

Turns the brief into a full design document.

## Does
- Produces `GDD.md` with all required sections (core loop, controls, systems,
  formulas, variables with ranges, tuning knobs, edge cases, acceptance criteria).
- Every mechanic has a formula, not a vibe.
- All LLM calls go through `orchestrator/llm_router.py` (hosted-only).

## Output
`GDD.md`.
