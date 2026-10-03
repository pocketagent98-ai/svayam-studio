# PROJECT_STATE

_Last updated: P0 scaffold._

## Status

- **Phase:** P0 complete (repo skeleton + workflow graph + hosted-only router).
- **Engine:** Godot 4.7.2-stable (pinned commit `ed1daf0bf`) — **not yet verified**.
- **No game exists yet.** Nothing has passed a gate.

## What works

- `orchestrator/llm_router.py` — hosted-only 4-provider fallback chain.
- `orchestrator/inspect.py` — writes `context/ENGINE_PROFILE.json`.
- `.github/workflows/game-factory.yml` — full 11-stage job graph; stage bodies
  are placeholders for P1+.

## Next actions (P1)

1. Implement `orchestrator/research/run.py` (iTunes/Steam/itch adapters).
2. Verify the Godot version + commit; flip `engine_verified` to true.
3. Add `GROQ_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY` as repo secrets.
