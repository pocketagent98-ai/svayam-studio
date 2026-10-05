# CHANGELOG

## [P0.7] — stunt racer vertical slice (new game)
- New project `stunt_racer/` built to the user's PRD/TRD: endless arcade stunt racer.
- Custom car physics: RigidBody3D + 4 RayCast3D suspension + Ackermann-style
  steering + downforce + lateral-grip drift (TRD model, not VehicleBody).
- Endless procedural track (centreline grows ahead, mesh extruded, recycled behind).
- Obstacles (crash gates, knock-through blocks), coins, chase camera with
  KeepAspect = Keep Height, portrait mobile renderer.
- FSM app flow (menu/garage/race/paused/results) and a binary save system
  (`Global` autoload, store_var/get_var, atomic swap, .bak backup).
- Touch steering for one-finger mobile play.
- Verified headless: imports clean, menu loads, automated run drives ~85 km/h
  along the generated track and collects coins.

## [P0.6] — studio setup wired to your AI
- Added NaraRouter as the first provider in `orchestrator/llm_router.py`
  (URL/model read from env; no key in the code).
- Workflow now passes secrets to every job (`env:` block) and has a **smoke**
  job to prove the AI connection on demand.
- Added `SETUP.md` (step-by-step) and `.env.example`.
- Fixed a real bug: `orchestrator/inspect.py` shadowed Python's built-in
  `inspect` module; renamed to `orchestrator/engine_profile.py`.
- Verified: workflow YAML parses, router runs and lists its 5-provider chain,
  engine_profile runs.

## [P0.5] — championship, autopilot, pit lane
- Added **Championship mode**: 3 rounds with points, a between-rounds screen and a final standings screen.
- Added **autopilot** (press C): the AI co-pilot drives the player's car; press again to take over.
- Added a **pit lane** of garages, a start gantry, covered grandstand and banner towers (Kenney racing kit).
- Race result now carries place/time/track so the top level can score the cup.
- Verified headless: menu clean, race finishes, championship round + final screens reached.

## [P0.4] — real 3D models
- Added real 3D models (Kenney CC0 Car Kit + Racing Kit) under `models/kenney/`.
- `scripts/ModelUtil.gd`: loads .glb, auto-scales by bounding box, auto-aligns
  the car's long axis and front direction from the model's own wheel nodes.
- Cars now use real 3D models with spinning wheels (6 cars, 4 of them unique models).
- Tracks now place real 3D scenery: grandstands, light posts, overhead gantries,
  trees, billboards, tents, pylons and checkered flags.
- Verified headless: all models import, the car loads with 4 wheels, race finishes.

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
