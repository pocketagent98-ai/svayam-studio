# SETUP — connect your AI and run the studio

This repo is ready. The only thing left is to give it your API key **the safe
way** — as a GitHub secret, never inside the code.

> Never paste a key into a file, a commit, or a chat. Anything typed into a
> chat should be treated as exposed, so if you have already shared a key,
> revoke it and create a new one.

---

## 1. Add your key as a repository secret

1. Open the repo: `https://github.com/pocketagent98-ai/svayam-studio`
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. **Name:** `NARAROUTER_API_KEY`  **Secret:** *(paste your NaraRouter key)*
5. Click **Add secret**

That is the only required secret. `GITHUB_TOKEN` is provided automatically by
GitHub Actions, so nothing else is needed to start.

Optional extras (same screen) — the router will use them automatically if present:

| Name | What it is |
|---|---|
| `GROQ_API_KEY` | Groq free tier |
| `GEMINI_API_KEY` | Google Gemini free tier |
| `OPENROUTER_API_KEY` | OpenRouter free models |

## 2. (Optional) Point the router at a specific model

**Settings → Secrets and variables → Actions → Variables tab → New repository variable**

| Name | Example value |
|---|---|
| `NARAROUTER_BASE_URL` | `https://router.bynara.id/v1` |
| `NARAROUTER_MODEL` | `nemotron-3-ultra` |

If you leave these blank, the router uses those same defaults.

## 3. Test that it works

1. Open the **Actions** tab.
2. Choose **svayam-studio** on the left.
3. Click **Run workflow** → **Run workflow**.
4. Open the run and look at the **smoke** job. It prints which keys are
   configured, then asks the AI one trivial question. If it prints `ROUTER OK`,
   your key works and the studio is live.

## 4. Then start building

- Open an **issue**, type what you want, and add the label **`new-game`**.
  That is the trigger for the full pipeline.

---

## How the key is used

Nothing is hardcoded. The workflow passes the secret to the code as an
environment variable, and `orchestrator/llm_router.py` reads it from there:

```
GitHub secret  ->  Actions env  ->  llm_router.py  ->  the model
```

The router tries providers in order and falls back automatically:

```
nararouter  ->  github-models  ->  groq  ->  gemini  ->  openrouter
```

So if one provider is down or out of quota, the next one is used.

## Running locally (optional)

```bash
export NARAROUTER_API_KEY=...        # your key, in your own shell only
python orchestrator/llm_router.py --prompt "say hello"
```

A `.env.example` is included as a template. If you create a real `.env`, it is
already listed in `.gitignore` and will not be committed.
