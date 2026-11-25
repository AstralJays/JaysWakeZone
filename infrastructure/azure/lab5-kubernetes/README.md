# Lab 5 — Azure AKS (WakeBot + Ollama GPU)

Publish `lab5-agentic/` to Docker Hub, set `container_image`, then:

```bash
cd infrastructure/azure/lab5-kubernetes
cp terraform.tfvars.example terraform.tfvars
# edit container_image
terraform init && terraform apply
terraform output lab5_url
```

## What you get

| Pool | Size | Workload |
|------|------|----------|
| CPU | `Standard_D2s_v5` (2 vCPU / **8 GiB**) | WakeBot + room for Upwind |
| GPU | `Standard_NC4as_T4_v3` (T4) | Ollama (`llama3.2`) — RAM capped so sensor fits |

WakeBot env: `OLLAMA_BASE_URL=http://ollama.default.svc.cluster.local:11434/v1`

## Upwind (you install — not in Terraform)

Sized for Upwind’s ≥4 GiB node guidance plus Cluster Manager (~2 GiB). Install the cluster sensor from the portal yourself.

GPU pool is tainted `nvidia.com/gpu=true:NoSchedule` — add a matching **toleration** on the Upwind Sensor so it schedules on the GPU node.

## Notes

- Needs **GPU quota** / SKU availability (`eastus` default).
- First model pull can take several minutes.
- **Destroy ASAP** — GPU nodes are expensive.

```bash
terraform destroy
```
