#!/usr/bin/env python3
"""Stage 1 — deep research (P1 placeholder).

Real implementation will adapt: iTunes RSS (genre 6014), iTunes Search, Steam
storesearch/appdetails/appreviews, itch.io, yt-dlp metadata -> hosted-LLM
summaries, GitHub code search. Rate-limit <=1 req/s; cache under .cache/.
"""

from __future__ import annotations

import json
from pathlib import Path


def main() -> int:
    out = Path("research.json")
    if not out.exists():
        out.write_text(json.dumps({"status": "not-implemented", "stage": 1}, indent=2))
    print("[research] placeholder — implement adapters in P1")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
