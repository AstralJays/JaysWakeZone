# Lab 5 — GCP GKE (WakeBot + Ollama GPU)

Publish `lab5-agentic/` to Docker Hub, set `container_image` + `project_id`, then:

```bash
cd infrastructure/gcp/lab5-kubernetes
cp terraform.tfvars.example terraform.tfvars
# edit project_id + container_image
terraform init && terraform apply
terraform output lab5_url
```

## What you get

| Pool | Size | Workload |
|------|------|----------|
| CPU | `e2-standard-2` (2 vCPU / **8 GiB**) | WakeBot + room for Upwind |
| GPU | `n1-standard-4` + T4 (~15 GiB) | Ollama (`llama3.2`) — RAM capped so sensor fits |

WakeBot env: `OLLAMA_BASE_URL=http://ollama.default.svc.cluster.local:11434/v1`

## Upwind (you install — not in Terraform)

Sized for Upwind’s ≥4 GiB node guidance plus Cluster Manager (~2 GiB). Install the cluster sensor from the portal yourself.

GPU pool is tainted `nvidia.com/gpu=true:NoSchedule` — add a matching **toleration** on the Upwind Sensor so it schedules on the GPU node.

## Notes

- Needs **GPU quota** for T4 in the zone.
- First model pull can take several minutes.
- **Destroy ASAP** — GPU nodes are expensive.

```bash
terraform destroy
```
