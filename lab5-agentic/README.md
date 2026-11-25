# Lab 5 — WakeBot (OWASP LLM + agentic)

Simplified **JaysSurfShop / Maya** lab: one chat page, OWASP LLM Top 10 prompts in the sidebar, plus a couple agentic tools. Intentionally vulnerable — sandbox only.

| | |
|-|-|
| **Image (you publish)** | `YOURUSER/jwz-agent-lab:0.1.0` |
| **Port** | `8080` |
| **UI** | `/` — WakeBot chat + OWASP LLM sidebar |
| **Ollama** | Local optional; **Lab 5 K8s** runs Ollama on a GPU node and sets `OLLAMA_BASE_URL` automatically |

Covers **OWASP LLM Top 10 (2025)** and light **agentic** abuse (tool SSRF, excessive agency) — not OWASP API Top 10, not a multi-page SurfShop.

## Local

```bash
cd lab5-agentic
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
# open http://127.0.0.1:8080
```

With Ollama (optional):

```bash
OLLAMA_BASE_URL=http://127.0.0.1:11434/v1 OLLAMA_MODEL=llama3.2 \
  uvicorn app.main:app --port 8080
```

Docker on a Mac/Windows host (Ollama on the host — **not** `127.0.0.1` inside the container):

```bash
docker run --rm -p 8088:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434/v1 \
  -e OLLAMA_MODEL=llama3.2 \
  YOURUSER/jwz-agent-lab:0.1.0
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

## UI flow (like SurfShop `/chat`)

1. Click an **OWASP LLM** prompt in the sidebar → fills the composer and tags the call with `owasp_llm`
2. Send — watch the reply (simulated or Ollama) + meta (`mode`, `owasp_llm`, tools)
3. **LLM04**: plant a tip → ask about FREEBOARD
4. **AGENT**: Research URL → `http://127.0.0.1:8080/internal/metadata` (SSRF)
5. **LLM06**: chat “ship JWZ-10847…” or use **Hijack booking**

See [WALKTHROUGH.md](WALKTHROUGH.md).
