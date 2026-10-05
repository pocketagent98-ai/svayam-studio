# RAGE SPEED — Godot racing game

A playable 3D arcade racer for Godot **4.7.2** (verified: `4.7.2.stable.official.ed1daf0bf`),
built with **real 3D models** from Kenney's CC0 kits.

## Run it

1. Install Godot 4.7.2 (standard build).
2. Open this folder as a project (`project.godot`), or run `godot --path godot_project`.
3. **START RACE** to drive, **GARAGE** to choose a car and a track.

## Controls

| Action | Keys |
|---|---|
| Accelerate | W / Up |
| Brake / reverse | S / Down |
| Steer | A / D / Left / Right |
| Nitro boost | Shift |
| Handbrake | Space |
| Restart | R |
| Menu | Esc |

## Features

- **Real 3D car models** (6 different cars) with spinning wheels — Kenney CC0 kit.
- **Real 3D scenery** along every track: grandstands, light posts, overhead
  gantries, trees, billboards, tents, pylons, checkered flags.
- **3 tracks**: Coastal Loop, City Circuit, Mountain Pass (generated in code).
- **Garage**: choose your car and track; cars differ in speed, grip and nitro.
- **Nitro boost** with a recharge bar.
- **3-2-1-GO countdown** before the lights go green.
- **6-car race**: you plus 5 AI opponents.
- **Live minimap** showing every car.
- **HUD**: speed, lap, position, time, best lap, nitro.
- **Records**: best lap and best total per track, saved to `user://`.
- **Procedural engine sound** (no external audio files).

## Layout

```
project.godot            engine + display config
main.tscn                single root scene
scripts/Game.gd          state machine: menu / garage / race / results
scripts/Race.gd          world build, countdown, race loop, records, audio
scripts/Track.gd         3 procedural tracks + scenery placement
scripts/Car.gd           arcade car (real model) with stats + nitro
scripts/ModelUtil.gd     load/scale/orient .glb models automatically
scripts/ChaseCamera.gd   third-person camera
scripts/HUD.gd           HUD + live minimap
models/kenney/           real 3D models (Kenney, CC0) — see CREDITS.txt
```

## Licences

The 3D models in `models/kenney/` are Kenney's, released under **CC0 1.0**
(public domain — free for personal and commercial use). See `models/kenney/CREDITS.txt`.

## Verified

Compiled and run headless with Godot 4.7.2: the project imports with no script
errors, all models import, the real car model loads with its four wheels, the
menu loads, and an automated run (flag `--autoplay` after `--`) drives to the
finish and writes a record. Visual rendering could not be captured in the build
sandbox (no display), so check the look on your machine.

## Status

A working 3D game with real models. Still to add: more cars and tracks, damage,
a UI/HUD skin, and the AI co-pilot layer. See `ROADMAP.md`.
