# Lab 5 — AWS EKS (WakeBot + Ollama GPU)

Publish `lab5-agentic/` to Docker Hub, set `container_image`, then:

```bash
cd infrastructure/aws/lab5-kubernetes
cp terraform.tfvars.example terraform.tfvars
# edit container_image
terraform init && terraform apply
terraform output lab5_url
```

## What you get

| Node | Size | Workload |
|------|------|----------|
| CPU | `t3.large` (2 vCPU / **8 GiB**) | WakeBot + room for Upwind |
| GPU | `g4dn.xlarge` (T4, 16 GiB) | Ollama (`llama3.2`) — RAM capped so sensor fits |

WakeBot env: `OLLAMA_BASE_URL=http://ollama.default.svc.cluster.local:11434/v1`

## Upwind (you install — not in Terraform)

Sized for [Upwind’s ≥4 GiB node guidance](https://docs.upwind.io) plus Cluster Manager (~2 GiB default). After apply, install the cluster sensor from the portal yourself.

GPU nodes are tainted `nvidia.com/gpu=true:NoSchedule` — add a matching **toleration** on the Upwind Sensor when you install so the DaemonSet lands on the GPU node too.

## Notes

- Needs **GPU quota** for `g4dn` in the region.
- First model pull can take several minutes.
- **Destroy ASAP** — GPU nodes are expensive.

```bash
terraform destroy
```
