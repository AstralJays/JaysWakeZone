# Lab 5 — Kubernetes (WakeBot + Ollama GPU)

Workload: **WakeBot** (OWASP LLM Top 10 + agentic) backed by **in-cluster Ollama on a GPU node**.

App source: [`lab5-agentic/`](../lab5-agentic/)  
**You build & push** the image to Docker Hub, then point Terraform at it.  
**Upwind is not installed by Terraform** — nodes are sized so you can add the cluster sensor without OOMs.

| Cloud | Path | App node (Upwind headroom) | Ollama GPU |
|-------|------|----------------------------|------------|
| AWS | `infrastructure/aws/lab5-kubernetes/` | EKS `t3.large` (8 GiB) | `g4dn.xlarge` (T4) |
| Azure | `infrastructure/azure/lab5-kubernetes/` | AKS `Standard_D2s_v5` (8 GiB) | `Standard_NC4as_T4_v3` |
| GCP | `infrastructure/gcp/lab5-kubernetes/` | GKE `e2-standard-2` (8 GiB) | `n1-standard-4` + T4 |

CPU nodes follow Upwind’s **≥4 GiB** sensor guidance and leave room for Cluster Manager (~2 GiB). Ollama memory is capped (~6 GiB limit) so the Sensor DaemonSet fits on GPU nodes too.

```bash
# 1) publish image
cd lab5-agentic
docker build -t YOURUSER/jwz-agent-lab:0.1.0 .
docker push YOURUSER/jwz-agent-lab:0.1.0

# 2) deploy
cd ../infrastructure/aws/lab5-kubernetes   # or azure|gcp
cp terraform.tfvars.example terraform.tfvars
# container_image = "YOURUSER/jwz-agent-lab:0.1.0"
terraform init && terraform apply
terraform output lab5_url
```

WakeBot → `http://ollama.default.svc.cluster.local:11434/v1`. A Job pulls `llama3.2`.

**Needs GPU quota.** When installing Upwind, add a GPU **toleration** for `nvidia.com/gpu=true:NoSchedule`. **Destroy promptly.**
