#!/usr/bin/env python3
"""Stage 0 — inspect the environment and write ENGINE_PROFILE.json.

Deterministic, no AI, no network required for the base profile. This is the
P0 "hello workflow": it proves the pipeline runs end to end.
"""

from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
from datetime import datetime, timezone
from pathlib import Path

ENGINE_PROFILE = {
    "engine": "godot",
    "engine_version": "4.7.2-stable",
    "engine_commit": "ed1daf0bf",
    "engine_verified": False,   # R9: flip to true only after KB/commit check
    "language": "gdscript",     # C# is not supported on the web export
    "renderer_default": "mobile",
    "renderer_web_override": "gl_compatibility",
    "physics_3d": "jolt",
    "stretch_mode": "canvas_items",
    "stretch_aspect": "expand",
}

HOSTED_PROVIDERS = ["GITHUB_TOKEN", "GROQ_API_KEY", "GEMINI_API_KEY", "OPENROUTER_API_KEY"]


def build_profile() -> dict:
    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "engine": ENGINE_PROFILE,
        "runner": {
            "os": platform.platform(),
            "python": platform.python_version(),
            "arch": platform.machine(),
        },
        "cli": {
            "godot": shutil.which("godot") or None,
            "ffmpeg": shutil.which("ffmpeg") or None,
            "adb": shutil.which("adb") or None,
            "node": shutil.which("node") or None,
        },
        "providers_available": [k for k in HOSTED_PROVIDERS if os.environ.get(k)],
        "local_models_allowed": False,  # R1
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", default="context/ENGINE_PROFILE.json")
    args = ap.parse_args()

    profile = build_profile()
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(profile, indent=2) + "\n")
    print(f"[inspect] wrote {out}")
    print(f"[inspect] hosted providers available: {profile['providers_available']}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
