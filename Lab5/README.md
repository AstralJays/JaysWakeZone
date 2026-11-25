# Lab 5 — Microservice + AI (Wakezone AI)

SurfShop/Maya-style **Wakezone AI** chat for paddle board rentals — OWASP LLM Top 10 + agentic tools — backed by **in-cluster Ollama on a GPU node**.

| | |
|-|-|
| **Image (you publish)** | `YOURUSER/jwz-agent-lab:0.1.0` |
| **Port** | `8080` |
| **K8s** | EKS / AKS / GKE under `infrastructure/` |

## Local

```bash
cd Lab5
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
```

Optional Ollama: `OLLAMA_BASE_URL=http://127.0.0.1:11434/v1`

Docker (Ollama on host):

```bash
docker build -t YOURUSER/jwz-agent-lab:0.1.0 .
docker run --rm -p 8088:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434/v1 \
  -e OLLAMA_MODEL=llama3.2 \
  YOURUSER/jwz-agent-lab:0.1.0
```

## Deploy (Kubernetes + GPU Ollama)

```bash
cd Lab5
docker build -t YOURUSER/jwz-agent-lab:0.1.0 .
docker push YOURUSER/jwz-agent-lab:0.1.0

cd infrastructure/<aws|azure|gcp>
cp terraform.tfvars.example terraform.tfvars
# container_image = "YOURUSER/jwz-agent-lab:0.1.0"
terraform init && terraform apply
terraform output lab5_url
```

| Cloud | App node (Upwind headroom) | Ollama GPU |
|-------|----------------------------|------------|
| AWS | `t3.large` (8 GiB) | `g4dn.xlarge` (T4) |
| Azure | `Standard_D2s_v5` (8 GiB) | `Standard_NC4as_T4_v3` |
| GCP | `e2-standard-2` (8 GiB) | `n1-standard-4` + T4 |

Wakezone AI → `http://ollama.default.svc.cluster.local:11434/v1`.  
**Upwind is not in Terraform** — install the cluster sensor yourself (add GPU toleration). **Destroy ASAP.**

See [WALKTHROUGH.md](WALKTHROUGH.md) and `manifests/`.
