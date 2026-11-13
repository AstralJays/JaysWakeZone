# Lab 5 — Agentic API Lab (JaysWakeZone)

**One page. Six steps.** Intentionally vulnerable API + WakeBot agent for SA Surf School.

| | |
|-|-|
| **Image (you publish)** | `YOURUSER/jwz-agent-lab:0.1.0` |
| **Port** | `8080` |
| **UI** | single page at `/` |
| **Optional** | Ollama via `OLLAMA_BASE_URL` + `OLLAMA_MODEL` |

Covers a short path through **OWASP API Top 10**-style flaws and **agentic** abuse (prompt injection, SSRF tool, excessive agency) — not a multi-page CTF.

## Local

```bash
cd lab5-agentic
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
# open http://127.0.0.1:8080
```

With Ollama (optional — simulated agent works without it):

```bash
OLLAMA_BASE_URL=http://127.0.0.1:11434/v1 OLLAMA_MODEL=llama3.2 \
  uvicorn app.main:app --port 8080
```

## Build & push (Docker Hub)

```bash
cd lab5-agentic
docker build -t YOURUSER/jwz-agent-lab:0.1.0 .
docker push YOURUSER/jwz-agent-lab:0.1.0
```

Then set Lab 5 Terraform:

```hcl
container_image = "YOURUSER/jwz-agent-lab:0.1.0"
```

## Process (in the UI)

1. Login — broken auth (any password)  
2. BOLA — read another user’s order  
3. Excessive data — dump API keys  
4. Mass assignment — promote to admin  
5. Prompt injection — WakeBot vault secret  
6. SSRF — agent `research` hits `/internal/metadata`

See [WALKTHROUGH.md](WALKTHROUGH.md).
