# Lab 5 — Kubernetes (Damn Vulnerable AI Agent)

**No image build/push.** Terraform pulls the public Docker Hub image onto EKS / AKS / GKE.

| | |
|-|-|
| **Image** | [`opena2a/dvaa:0.9.2`](https://hub.docker.com/r/opena2a/dvaa) |
| **Source** | [opena2a-org/damn-vulnerable-ai-agent](https://github.com/opena2a-org/damn-vulnerable-ai-agent) |
| **Dashboard** | container `:9000` → Service `:80` |
| **You install** | Upwind cluster / node sensor (after apply) |

| Cloud | Stack path | Platform | Node |
|-------|------------|----------|------|
| AWS | `infrastructure/aws/lab5-kubernetes/` | EKS | 1× `t3.medium` |
| Azure | `infrastructure/azure/lab5-kubernetes/` | AKS | 1× `Standard_B2s` |
| GCP | `infrastructure/gcp/lab5-kubernetes/` | GKE | 1× `e2-medium` |

Intentionally vulnerable — **lab / sandbox only**. LB exposes the **dashboard** only; agent ports stay in-cluster (`kubectl port-forward` for HackMyAgent).

Reference manifests: `manifests/deployment.yaml`.  
**Destroy promptly** — control plane + node hours add up.

See [WALKTHROUGH.md](WALKTHROUGH.md).
