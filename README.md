# SVAYAM STUDIO

A **skills-based virtual game studio** that runs on GitHub Actions (CPU only).
You file an issue, and the pipeline researches, designs, builds a Godot vertical
slice, tests it with evidence, and ships it — using only hosted free AI APIs.

This repository is the **P0 foundation**: the repo skeleton, the Actions
workflow graph, the hosted-only LLM router, the memory files, and the skill
stubs. The stage logic (research, design, codegen, QA, ship) is filled in over
phases P1–P7 — see `ROADMAP.md`.

## Non-negotiable rules

The full rule set lives in `AGENTS.md` (R1–R10). The short version:

1. **No local model** — all AI calls go to hosted free APIs in a fallback chain.
2. **No paid dependency** anywhere in the production path.
3. **No success claim without evidence** (logs, frames, screenshots, metrics).
4. **Vertical slice first** — no production work before the slice passes.
5. **Every external asset has a license record**; unclear means reject.
6. **Every dependency has a 4-level fallback chain.**

## Layout

```
AGENTS.md                     provider-neutral director rules
.agents/skills/               the studio's skills (director, designer, QA, ...)
orchestrator/                 the machinery (llm_router, qa, fixer, ship, learn)
memory/                       durable state, updated every run (no weight training)
context/                      engine profile + Godot knowledge base
godot_project/                the game under construction
.github/workflows/            the game-factory pipeline
```

## The pipeline (11 stages)

Trigger -> Research -> Design -> Assets -> Vertical slice -> QA -> Fixer ->
Gate -> Production -> Regression -> Release -> Learn -> (weekly Radar).

## Setup (do this first)

See **[SETUP.md](SETUP.md)**. In short: add your key as a repository **secret**
named `NARAROUTER_API_KEY` (Settings -> Secrets and variables -> Actions), then
run the **smoke** job from the Actions tab to confirm it works. Keys are never
written into the code.

## Cost

Target is **Rs 0**. Public repo = free Actions minutes; Pages/itch free; no model
hosting. Secrets: `GITHUB_TOKEN` (auto) and `NARAROUTER_API_KEY` (yours).
Optional fallbacks: `GROQ_API_KEY`, `GEMINI_API_KEY`, `OPENROUTER_API_KEY`.

## Try the router locally

```bash
export NARAROUTER_API_KEY=...   # your key, in your own shell only
python orchestrator/llm_router.py --prompt "one-line Godot 4.7 tip"
```
