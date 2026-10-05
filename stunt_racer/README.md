# Stunt Racer — SVAYAM

An endless arcade **stunt racer** built to the "Architecting the Core Loop" PRD/TRD:
high-speed driving through a procedurally generated course, drift and boost to keep
momentum, dodge hazards, and drive as far as you can before you crash.

This is the **vertical slice** the Implementation Plan defines as Phase 1
(Pre-Production): one full cycle of the core loop, end to end.

Godot **4.7.2** (verified: `4.7.2.stable.official.ed1daf0bf`).

## Run it

1. Install Godot 4.7.2.
2. Open this folder as a project, or run `godot --path stunt_racer`.
3. Tap **QUICK RACE**. Portrait, 720x1280.

## Controls

| Action | Keys | Touch |
|---|---|---|
| Accelerate | W / Up | (auto) |
| Brake / reverse | S / Down | — |
| Steer | A / D / Left / Right | hold left / right of screen centre |
| Nitro boost | Shift | — |
| Drift (handbrake) | Space | — |
| Pause | P | — |
| Restart / back | R / Esc | — |

## What the slice implements

| Spec phase | In this slice |
|---|---|
| Core loop | Endless course, distance as the score, crash ends the run |
| Car physics | **RigidBody3D + 4 RayCast3D suspension + Ackermann-style steering + downforce + lateral-grip drift** (the TRD's custom model, not VehicleBody) |
| Track generation | Centreline that grows ahead of the car, extruded into a road mesh with walls; geometry recycled behind |
| Obstacles | Red hazard gates (crash), knock-through orange blocks (physics), coins |
| App flow | FSM: MAIN_MENU → GARAGE → RACE → (PAUSED) → POST_RACE_RESULTS |
| Camera | Chase camera with `KeepAspect = Keep Height` (the TRD calls this out as critical) |
| Renderer | Mobile renderer, portrait |
| Save system | `Global` autoload, **binary** `FileAccess.store_var/get_var`, atomic swap, `.bak` backup |
| HUD | Speed, distance, coins, best, nitro bar |
| Assets | CC0 only (Kenney) — see `models/kenney/CREDITS.txt` |

## Layout

```
project.godot            portrait + mobile renderer + Global autoload
main.tscn                single root scene
scripts/Game.gd          FSM: menu / garage / race / paused / results
scripts/Race.gd          one run: track, car, obstacles, coins, crash
scripts/Car.gd           RigidBody raycast arcade car
scripts/TrackGen.gd      endless procedural track + scenery
scripts/HUD.gd           portrait HUD
scripts/ChaseCamera.gd   chase camera (Keep Height)
scripts/Global.gd        save/load (binary + backup)
scripts/ModelUtil.gd     load/scale/orient .glb models
models/kenney/           CC0 3D models
```

## Verified

Run headless with Godot 4.7.2: imports with no script errors, the menu loads, and
an automated run drives the car up to ~85 km/h along the generated track, streams
new track ahead, and collects coins. No display in the build sandbox, so the look
still needs a check on your machine.

## Not in the slice yet (later phases)

Ramps/loops/tubes, fans and pendulums, AI opponents, 30-car garage with paint and
nitro VFX, boss racers, Unity Ads + IAPs, accessibility options, object pooling,
LOD/MultiMesh optimisation, leaderboards.
