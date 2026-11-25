# Lab 5 — Microservice + AI (Wakezone AI)

SurfShop/Maya-style **Wakezone AI** chat (paddle rentals) — OWASP LLM Top 10 + agentic tools — with **in-cluster Ollama on a GPU node**.

| | |
|-|-|
| **App image (public)** | `papaperk/jwz-agent-lab:0.1.0` |
| **Ollama** | `ollama/ollama` on GPU |
| **Port** | `8080` |
| **K8s** | EKS / AKS / GKE under `infrastructure/` |

No local image build for deploy — same pattern as Lab 4.

## Configure

```bash
cd Lab5/infrastructure/<aws|azure|gcp>
cp terraform.tfvars.example terraform.tfvars
```

| Cloud | Edit in `terraform.tfvars` |
|-------|----------------------------|
| **AWS** | `aws_region` (default `us-east-1`). Optional: `aws_profile`, `gpu_instance_type`. |
| **Azure** | `location` (default `eastus`). Optional: `gpu_vm_size`. |
| **GCP** | **Required:** `project_id`. Optional: `region` / `zone`, `gpu_type`. |

Confirm **GPU (T4) quota** in that region/account before apply.  
`container_image` / `ollama_model` are optional (defaults: Hub image + `llama3.2`).

| Cloud | App node (Upwind headroom) | Ollama GPU |
|-------|----------------------------|------------|
| AWS | `t3.large` (8 GiB) | `g4dn.xlarge` (T4) |
| Azure | `Standard_D2s_v5` (8 GiB) | `Standard_NC4as_T4_v3` |
| GCP | `e2-standard-2` (8 GiB) | `n1-standard-4` + T4 |

## Deploy

```bash
terraform init
terraform apply
terraform output lab5_url
```

Open the URL → Wakezone AI. Status may stay **simulated** until the GPU pod pulls `llama3.2` (a few minutes).

## Destroy

```bash
terraform destroy   # do this ASAP — GPU cost
```

## After apply (Upwind)

Install the **cluster sensor** yourself (not in Terraform). Add a GPU node toleration if the sensor must schedule onto the Ollama pool. Chat calls tag `owasp_llm=…` for the workshop path — see [WALKTHROUGH.md](WALKTHROUGH.md).

## Local (optional)

```bash
cd Lab5
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8080
# optional: OLLAMA_BASE_URL=http://127.0.0.1:11434/v1
```

```bash
docker run --rm -p 8088:8080 \
  -e OLLAMA_BASE_URL=http://host.docker.internal:11434/v1 \
  -e OLLAMA_MODEL=llama3.2 \
  papaperk/jwz-agent-lab:0.1.0
```

### Maintainers — refresh Hub image

```bash
cd Lab5
docker build -t papaperk/jwz-agent-lab:0.1.0 -t papaperk/jwz-agent-lab:latest .
docker push papaperk/jwz-agent-lab:0.1.0 && docker push papaperk/jwz-agent-lab:latest
```
