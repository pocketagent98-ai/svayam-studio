#!/usr/bin/env python3
"""Stage 7 — slice gate.

score = 0.30*build + 0.30*tests + 0.20*perf + 0.20*vision/UI

Writes memory/TEST_RESULTS.md and prints `pass=true|false`; also writes to
$GITHUB_OUTPUT when running in Actions. Until the real QA inputs exist the
component scores default to 0, so the gate correctly refuses to pass an
un-built slice (R4).
"""

from __future__ import annotations

import argparse
import os
from datetime import datetime, timezone
from pathlib import Path

THRESHOLD = 60.0


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--build", type=float, default=0.0)
    ap.add_argument("--tests", type=float, default=0.0)
    ap.add_argument("--perf", type=float, default=0.0)
    ap.add_argument("--vision", type=float, default=0.0)
    ap.add_argument("--out", default="memory/TEST_RESULTS.md")
    args = ap.parse_args()

    score = 0.30 * args.build + 0.30 * args.tests + 0.20 * args.perf + 0.20 * args.vision
    passed = score >= THRESHOLD

    report = (
        f"# TEST_RESULTS\n\n"
        f"_generated {datetime.now(timezone.utc).isoformat()}_\n\n"
        f"| component | weight | score |\n|---|---|---|\n"
        f"| build | 0.30 | {args.build} |\n"
        f"| tests | 0.30 | {args.tests} |\n"
        f"| perf | 0.20 | {args.perf} |\n"
        f"| vision/UI | 0.20 | {args.vision} |\n\n"
        f"**score = {score:.1f}** (threshold {THRESHOLD}) -> "
        f"**{'PASS' if passed else 'FAIL'}**\n"
    )
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(report)

    print(f"score={score:.1f} pass={'true' if passed else 'false'}")
    gh_out = os.environ.get("GITHUB_OUTPUT")
    if gh_out:
        with open(gh_out, "a", encoding="utf-8") as fh:
            fh.write(f"pass={'true' if passed else 'false'}\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
