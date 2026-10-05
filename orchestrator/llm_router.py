#!/usr/bin/env python3
"""SVAYAM STUDIO - hosted-only LLM router.

Hard rule R1: NO local model is ever used. Every AI call goes to a hosted
free API, tried in a fallback chain, and every provider failure is recorded
so the router can re-order itself next run (stage 10 "LEARN").

Chain (R6):
    GitHub Models  ->  Groq  ->  Gemini  ->  OpenRouter(:free)  ->  retrieval fallback

Credentials are read from the environment only. Never hardcode a key here.
    GITHUB_TOKEN        (auto-provided by GitHub Actions)
    GROQ_API_KEY
    GEMINI_API_KEY
    OPENROUTER_API_KEY

Usage:
    python orchestrator/llm_router.py --prompt "write a GDScript timer node"
    python orchestrator/llm_router.py --system "you are a Godot expert" \
        --prompt "explain Jolt physics in 4.7"
    echo "prompt text" | python orchestrator/llm_router.py --stdin
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from dataclasses import dataclass, field
from pathlib import Path
from typing import Any

MEMORY_DIR = Path(__file__).resolve().parent.parent / "memory"
STATS_FILE = MEMORY_DIR / "llm_stats.json"
TIMEOUT_S = 120


@dataclass
class Provider:
    """One hosted endpoint in the fallback chain."""

    name: str
    env_key: str          # env var holding the API key ("" = no key needed)
    url: str
    model: str
    style: str            # "openai" or "gemini"
    max_tokens: int = 4096
    extra_headers: dict[str, str] = field(default_factory=dict)

    def available(self) -> bool:
        return self.env_key == "" or bool(os.environ.get(self.env_key))


# Order matters: cheapest / highest-limit first. Stage 10 may rewrite the order.
CHAIN: list[Provider] = [
    # The owner's own router (NaraRouter) — free NVIDIA Nemotron models.
    # The URL and model come from the environment, so nothing is hardcoded.
    Provider(
        name="nararouter",
        env_key="NARAROUTER_API_KEY",
        url=os.environ.get("NARAROUTER_BASE_URL", "https://router.bynara.id/v1").rstrip("/")
        + "/chat/completions",
        model=os.environ.get("NARAROUTER_MODEL", "nemotron-3-ultra"),
        style="openai",
        extra_headers={"X-Title": "SVAYAM STUDIO"},
    ),
    Provider(
        name="github-models",
        env_key="GITHUB_TOKEN",
        url="https://models.github.ai/inference/chat/completions",
        model="openai/gpt-4o-mini",
        style="openai",
    ),
    Provider(
        name="groq",
        env_key="GROQ_API_KEY",
        url="https://api.groq.com/openai/v1/chat/completions",
        model="llama-3.3-70b-versatile",
        style="openai",
    ),
    Provider(
        name="gemini",
        env_key="GEMINI_API_KEY",
        url="https://generativelanguage.googleapis.com/v1beta/models/"
        "gemini-2.0-flash:generateContent",
        model="gemini-2.0-flash",
        style="gemini",
    ),
    Provider(
        name="openrouter",
        env_key="OPENROUTER_API_KEY",
        url="https://openrouter.ai/api/v1/chat/completions",
        model="meta-llama/llama-3.3-70b-instruct:free",
        style="openai",
        extra_headers={"X-Title": "SVAYAM STUDIO"},
    ),
]


def _load_stats() -> dict[str, Any]:
    if STATS_FILE.exists():
        try:
            return json.loads(STATS_FILE.read_text())
        except json.JSONDecodeError:
            pass
    return {}


def _save_stats(stats: dict[str, Any]) -> None:
    MEMORY_DIR.mkdir(parents=True, exist_ok=True)
    STATS_FILE.write_text(json.dumps(stats, indent=2, sort_keys=True) + "\n")


def _record(provider: str, ok: bool, latency_s: float) -> None:
    stats = _load_stats()
    entry = stats.setdefault(provider, {"ok": 0, "fail": 0, "avg_latency_s": 0.0})
    if ok:
        entry["ok"] += 1
    else:
        entry["fail"] += 1
    n = entry["ok"] + entry["fail"]
    entry["avg_latency_s"] = round(
        (entry["avg_latency_s"] * (n - 1) + latency_s) / n, 3
    )
    _save_stats(stats)


def _build_body(p: Provider, messages: list[dict[str, str]]) -> bytes:
    if p.style == "gemini":
        system = "\n".join(
            m["content"] for m in messages if m["role"] == "system"
        )
        contents = [
            {"role": "user", "parts": [{"text": m["content"]}]}
            for m in messages
            if m["role"] != "system"
        ]
        body: dict[str, Any] = {
            "contents": contents,
            "generationConfig": {"maxOutputTokens": p.max_tokens},
        }
        if system:
            body["systemInstruction"] = {"parts": [{"text": system}]}
    else:
        body = {"model": p.model, "messages": messages, "max_tokens": p.max_tokens}
    return json.dumps(body).encode("utf-8")


def _parse_reply(p: Provider, raw: dict[str, Any]) -> str:
    if p.style == "gemini":
        return raw["candidates"][0]["content"]["parts"][0]["text"]
    return raw["choices"][0]["message"]["content"]


def _call(p: Provider, messages: list[dict[str, str]]) -> str:
    req = urllib.request.Request(p.url, data=_build_body(p, messages), method="POST")
    req.add_header("Content-Type", "application/json")
    for k, v in p.extra_headers.items():
        req.add_header(k, v)
    key = os.environ.get(p.env_key, "")
    if p.style == "gemini":
        req.add_header("x-goog-api-key", key)
    elif key:
        req.add_header("Authorization", f"Bearer {key}")
    with urllib.request.urlopen(req, timeout=TIMEOUT_S) as resp:
        return _parse_reply(p, json.loads(resp.read().decode("utf-8")))


def chat(
    prompt: str,
    system: str | None = None,
    ordered_chain: list[Provider] | None = None,
) -> dict[str, Any]:
    """Try each available provider in order; return first success.

    Returns {"text": ..., "provider": ..., "attempts": [...]}.
    Raises RuntimeError if every provider fails (caller falls back to
    patterns.jsonl / template retrieval - the no-dependency fallback).
    """
    messages: list[dict[str, str]] = []
    if system:
        messages.append({"role": "system", "content": system})
    messages.append({"role": "user", "content": prompt})

    attempts: list[dict[str, Any]] = []
    for p in ordered_chain or CHAIN:
        if not p.available():
            attempts.append({"provider": p.name, "skipped": "no key"})
            continue
        start = time.time()
        try:
            text = _call(p, messages)
            _record(p.name, True, time.time() - start)
            attempts.append({"provider": p.name, "ok": True})
            return {"text": text, "provider": p.name, "attempts": attempts}
        except (urllib.error.URLError, urllib.error.HTTPError, KeyError, OSError) as exc:
            _record(p.name, False, time.time() - start)
            attempts.append({"provider": p.name, "ok": False, "error": str(exc)})
    raise RuntimeError(f"all hosted providers failed: {json.dumps(attempts)}")


def main(argv: list[str] | None = None) -> int:
    ap = argparse.ArgumentParser(description="SVAYAM STUDIO hosted-only LLM router")
    ap.add_argument("--prompt", default="")
    ap.add_argument("--system", default=None)
    ap.add_argument("--stdin", action="store_true", help="read prompt from stdin")
    args = ap.parse_args(argv)

    prompt = sys.stdin.read() if args.stdin else args.prompt
    if not prompt.strip():
        ap.error("no prompt given (use --prompt or --stdin)")

    try:
        result = chat(prompt, system=args.system)
    except RuntimeError as exc:
        print(f"[router] {exc}", file=sys.stderr)
        return 2
    print(result["text"])
    print(f"[router] served by {result['provider']}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
