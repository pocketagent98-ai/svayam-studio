# AGENTS.md — Director rules (provider-neutral)

Any AI agent working in this repository is bound by the rules below. They are
absolute: they may not be weakened, skipped, or "temporarily" disabled.

## Hard rules (R1–R10)

| # | Rule |
|---|------|
| R1 | No model is ever hosted locally. All AI calls go through `orchestrator/llm_router.py` to hosted free APIs, with a fallback chain. |
| R2 | No paid / trial / credit-based dependency in the production path. |
| R3 | No success claim without evidence: logs, frames, screenshots, metrics. |
| R4 | No production work before the vertical slice passes the gate. |
| R5 | Every external asset has a license record; unclear = reject. |
| R6 | Every dependency has a 4-level fallback chain (see README / spec). |
| R7 | Memory files are updated after every run; edit only after detecting conflicts with prior decisions. |
| R8 | Do not clone. Extract principles from references and write an original implementation. |
| R9 | Every Godot technical decision cites the Godot 4.7.2 knowledge base (or `--dump-extension-api`). |
| R10 | A small polished game beats a big broken one. |

## Engine facts (from the KB)

- Engine: Godot 4.7.2-stable. **Verify the pinned commit before locking it.**
- Language: GDScript only (C# is not supported on the web export).
- Renderer: `mobile` by default; web override `gl_compatibility`.
- Physics: Jolt for 3D.
- Stretch: `canvas_items` + `expand`.

## Workflow

1. Read `memory/` before acting; write it back after.
2. Produce the evidence artifact for a stage before starting the next.
3. Ask the human only for: secrets, ship approval, optional phone test.

## Handoff protocol

Phase order: **P0** repo+secrets+hello-workflow -> **P1** inspect+research ->
**P2** design+gate -> **P3** assets+gate -> **P4** slice+QA+fixer ->
**P5** gate+production+regression -> **P6** release+learn -> **P7** weekly radar.
