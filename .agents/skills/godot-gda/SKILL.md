# Skill: godot-gda

Drives Godot 4.7.2 headless and the `gda` engine-control CLI/MCP.

## Does
- Scaffolds `project.godot` and `export_presets.cfg`.
- Runs `godot --headless --check-only -s <file>` before every commit.
- Attaches scenes/nodes/scripts and captures live evidence.

## Fallback (R6)
gda CLI -> gda MCP -> XOVIET/Rufaty MCP -> direct file writes + headless CLI.
