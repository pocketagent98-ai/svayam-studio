# ROADMAP

Phase order is fixed by the spec. Each phase ends with an evidence artifact.

| Phase | Goal | Evidence artifact | Status |
|---|---|---|---|
| **P0** | repo + secrets + hello workflow | green Actions run | **done (scaffold)** |
| P1 | inspect + research | `RESEARCH_REPORT.md`, `research.json` | not started |
| P2 | design + review gate | `GAME_BRIEF.md`, `GDD.md`, `TECHNICAL_DESIGN.md` | not started |
| P3 | assets + license gate | `ASSET_MANIFEST.md`, `assets/` | not started |
| P4 | vertical slice + QA + fixer | playable slice, evidence bundle | not started |
| P5 | gate + production + regression | `TEST_RESULTS.md`, perf baseline | not started |
| P6 | release + learn | itch/Pages links, updated memory | not started |
| P7 | weekly radar | auto-issues | not started |

## Before P1

1. Verify the Godot version and commit (KI-001).
2. Add `GROQ_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY` as repo secrets.
3. Run the workflow once via `workflow_dispatch` to confirm the graph is green.
