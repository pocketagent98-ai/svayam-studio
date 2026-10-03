# DECISIONS

Append-only log of locked decisions. Never silently edit a prior entry; if a
new decision conflicts with an old one, add a dated entry that supersedes it and
say why (rule R7).

## 2026-10-03 — Architecture v5 accepted

- **Skills-based virtual studio** on GitHub Actions (CPU only).
- **Hosted free AI only**; no local model (R1). Chain: GitHub Models -> Groq ->
  Gemini -> OpenRouter(:free).
- **Retrieval/memory:** SQLite FTS5 + JSON, no embeddings, no weights.
- **Method:** vertical-slice-first, evidence-driven, stage-gated.
- **Assets:** CC0 / QAL verified only, with procedural fallback.
- **Cost target:** Rs 0.
