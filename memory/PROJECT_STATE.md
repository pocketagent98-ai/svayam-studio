# PROJECT_STATE

_Last updated: racing vertical slice built and verified._

## Status

- **Engine:** Godot 4.7.2-stable — **VERIFIED** (`4.7.2.stable.official.ed1daf0bf`,
  downloaded and run headless in the build sandbox). KI-001 resolved.
- **Game:** `godot_project/` holds **RAGE SPEED**, a playable arcade-racing
  vertical slice (menu → garage → race → results, 6 cars, procedural track,
  chase cam, HUD, lap/position/time logic).
- **Verification:** project imports with no script errors; an automated run
  (`--autoplay`) drives a full lap and reaches the finish.

## What works

- `orchestrator/llm_router.py` — hosted-only 4-provider fallback chain.
- `orchestrator/inspect.py` — writes `context/ENGINE_PROFILE.json`.
- `godot_project/` — the racing slice (see its README).

## Open

- Visual/art review by eye (no display in the build sandbox).
- KI-002/003 (free-tier rate limits, Actions job ceiling) still open.
- Stage bodies P1–P7 are still placeholders.

## Next actions

1. Play-test the slice on a real machine; tune speed/handling.
2. Add the garage/stores, more tracks, audio, and the AI-assistant layer.
3. Wire the Godot Asset Store client into the assets stage.
