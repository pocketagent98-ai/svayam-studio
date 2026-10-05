# CHANGELOG

## [P0.2] — racing vertical slice
- Verified the engine: Godot 4.7.2-stable (`ed1daf0bf`) downloaded and run headless.
- Built **RAGE SPEED**, a playable Godot racing vertical slice:
  - `scripts/Game.gd` — menu / garage / race / results state machine.
  - `scripts/Race.gd` — world build, car spawning, race loop, standings.
  - `scripts/Track.gd` — procedural Catmull-Rom track, road mesh, barrier walls.
  - `scripts/Car.gd` — arcade car used by the player and the AI.
  - `scripts/ChaseCamera.gd`, `scripts/HUD.gd`.
- Verified headless: clean import, menu loads, automated run completes a lap
  and reaches the finish.

## [P0] — 2026-10-03
- Initialised the SVAYAM STUDIO repository skeleton.
- Added `orchestrator/llm_router.py` (hosted-only, 4-provider fallback chain).
- Added `orchestrator/inspect.py` (Stage 0 engine profile).
- Added the 11-stage `game-factory.yml` workflow graph (stage bodies placeholders).
- Added memory files, context templates, and skill stubs.
