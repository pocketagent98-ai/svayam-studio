# RAGE SPEED — Godot racing game

A playable arcade racer built for Godot **4.7.2** (verified: `4.7.2.stable.official.ed1daf0bf`).

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

- **3 tracks**: Coastal Loop, City Circuit, Mountain Pass (all generated in code).
- **6 cars** with distinct stats (top speed, acceleration, grip, nitro).
- **Garage**: pick your car and track before racing.
- **Nitro boost** with a recharge bar.
- **Race countdown** (3-2-1-GO) before the lights go green.
- **6-car race**: you plus 5 AI opponents that follow the track.
- **Live minimap** showing every car and your position on it.
- **HUD**: speed, lap, live position, race time, best lap, nitro.
- **Records**: best lap and best total time per track, saved to `user://`.
- **Procedural engine sound** (no external audio files).

## Layout

```
project.godot          engine + display config
main.tscn              single root scene (everything else is built in code)
scripts/Game.gd        state machine: menu / garage / race / results
scripts/Race.gd        world build, countdown, race loop, records, audio
scripts/Track.gd       three procedural tracks: road, walls, waypoints
scripts/Car.gd         arcade car with stats + nitro (player and AI)
scripts/ChaseCamera.gd third-person camera
scripts/HUD.gd         HUD + live minimap
```

## Verified

Compiled and run headless with Godot 4.7.2: the project imports with no script
errors, the menu loads, and an automated run (flag `--autoplay` after `--`)
drives the car to the finish line and writes a best-time record. Visual
rendering could not be captured in the build sandbox (no display), so art and
handling tuning are the next thing to check by eye on your machine.

## Status

A working game — menu, garage, a real race with AI, lap timing, records and a
minimap. Still to add: environment art (the PSX pack from your screenshots),
more cars and tracks, damage, and the AI co-pilot layer. See `ROADMAP.md`.
