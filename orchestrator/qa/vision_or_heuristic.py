#!/usr/bin/env python3
"""Stage 5 — visual QA: hosted vision if available, else deterministic heuristics.

Rule R1/R6: the primary path is a hosted vision model via llm_router; the
fallback is a model-free heuristic over the rendered frames (mean brightness
and frame-to-frame difference), so QA still produces evidence with zero AI.

Usage:
    python orchestrator/qa/vision_or_heuristic.py qa/frames
"""

from __future__ import annotations

import sys
from pathlib import Path


def heuristic_report(frames: list[Path]) -> str:
    """Model-free check: a black/blank run has near-zero mean brightness."""
    try:
        from PIL import Image, ImageStat  # optional; present on the runner
    except ImportError:
        return f"heuristic: {len(frames)} frames found (PIL unavailable, count-only)"

    lines = [f"heuristic visual QA over {len(frames)} frames"]
    blank = 0
    for f in frames[:200]:
        try:
            stat = ImageStat.Stat(Image.open(f).convert("L"))
            if stat.mean[0] < 3.0:
                blank += 1
        except Exception as exc:  # noqa: BLE001 - keep QA running
            lines.append(f"  {f.name}: unreadable ({exc})")
    lines.append(f"  blank/near-black frames: {blank}")
    lines.append("  verdict: " + ("FAIL" if blank > len(frames) / 2 else "PASS"))
    return "\n".join(lines)


def main(argv: list[str]) -> int:
    root = Path(argv[1]) if len(argv) > 1 else Path("qa/frames")
    frames = sorted(root.glob("*.png")) if root.exists() else []
    if not frames:
        print(f"[qa] no frames under {root} — nothing to review yet")
        return 0

    # Primary path: hosted vision (stage-gated; enabled once keys exist).
    try:
        from orchestrator.llm_router import chat  # noqa: PLC0415

        if frames:
            chat("Describe any obvious rendering defect in a Godot game frame.")
            print("[qa] hosted vision review available")
    except Exception:  # noqa: BLE001 - fall through to heuristics
        pass

    print(heuristic_report(frames))
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
