# Godot Knowledge Base (placeholder)

Rule **R9**: every Godot technical decision must cite a section of the Godot
4.7.2 knowledge base supplied with the project. The full KB is a separate
document; this file records the decisions already made and the KB anchors they
rely on. If an API is in doubt, resolve it with `godot --dump-extension-api`
rather than guessing.

## Verified decisions

| Topic | Decision | KB anchor |
|---|---|---|
| Language | GDScript only (C# is not supported on the web export) | §18§4 |
| Renderer | `mobile` default; web override `rendering/renderer/rendering_method.web="gl_compatibility"` | §2 / §18§6 |
| Physics | Jolt for 3D | §3 |
| Stretch | `canvas_items` + `expand` | §19 |
| Save | `ConfigFile` / JSON under `user://`; web uses IndexedDB | §18§7 |
| CLI | `--headless --import --export-release --check-only --write-movie --fixed-fps --benchmark-file` | §12 |
| Plugins | LimboAI, Phantom Camera, Dialogue Manager, GUT, Godot Git Plugin, Debug Draw 3D | §20 |

> The `engine_version` / `engine_commit` above are **unverified**. Confirm them
> against the KB (or the Godot release page) before locking the toolchain.
