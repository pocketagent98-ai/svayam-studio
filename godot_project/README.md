# RAGE SPEED — Godot racing vertical slice

A playable arcade racer built for Godot **4.7.2** (verified: `4.7.2.stable.official.ed1daf0bf`).

## Run it

1. Install Godot 4.7.2 (standard build).
2. Open this folder as a project (`project.godot`), or run:

   ```
   godot --path godot_project
   ```

3. In the menu: **START RACE** to drive, **GARAGE** to pick a car colour.

## Controls

| Action | Keys |
|---|---|
| Accelerate | W / Up |
| Brake / reverse | S / Down |
| Steer | A / D / Left / Right |
| Handbrake | Space |
| Restart | R |
| Menu | Esc |

## What's in the slice

- **Main menu → garage → race → results** flow.
- **6 cars**: you plus 5 AI opponents that follow the track waypoints.
- **Procedural track**: a closed Catmull-Rom loop, road mesh, and continuous
  barrier walls generated in code (no imported assets).
- **Chase camera** that smoothly follows the player.
- **HUD**: speed (km/h), lap counter, live position, and race time.
- **Race logic**: lap counting, live standings, and a finish summary.

## Layout

```
project.godot          engine + display config
main.tscn              single root scene (everything else is built in code)
scripts/Game.gd        state machine: menu / garage / race / results
scripts/Race.gd        builds the world, spawns cars, runs the race loop
scripts/Track.gd       procedural road, walls, waypoints, start line
scripts/Car.gd         arcade car (player + AI)
scripts/ChaseCamera.gd third-person camera
scripts/HUD.gd         on-screen speed / lap / position / time
```

## Verified

Compiled and run headless with Godot 4.7.2: the project imports with no script
errors, the menu loads, and an automated run (flag `--autoplay` after `--`)
drives a full lap and reaches the finish. Visual rendering could not be captured
in the build sandbox (no display), so art/tuning is the next thing to check by
eye on your machine.

## Status

This is a **vertical slice** — a real, working foundation, not the finished
game. See the repository `ROADMAP.md` for what comes next (garage/stores,
more tracks, audio, minimap, damage, and the AI-assistant layer).
