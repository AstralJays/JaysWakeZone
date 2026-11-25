# Lab 5 walkthrough — WakeBot + Ollama GPU

## Deploy

```bash
cd infrastructure/<cloud>/lab5-kubernetes
cp terraform.tfvars.example terraform.tfvars
# set container_image (GCP: also project_id)
terraform init && terraform apply
terraform output lab5_url
terraform output lab5_ollama
```

Wait for the LoadBalancer. Status light goes **ollama** after the GPU node is ready and the pull Job finishes `llama3.2` (often several minutes).

## In the UI

1. Confirm status chip: **ollama · llama3.2**
2. Run **LLM01** → expect `OVERRIDE_OK` / secrets (guided fallback if the model refuses)
3. Plant tip → **LLM04** / **LLM08**
4. **LLM06** or Hijack booking
5. Research `http://127.0.0.1:8080/internal/metadata` (in-pod SSRF)

## Upwind (manual)

Nodes are sized for the sensor (≥4 GiB) + Cluster Manager headroom — Terraform does **not** install Upwind.

1. Install the cluster sensor from the portal / Helm operator docs.
2. Add a toleration for `nvidia.com/gpu=true:NoSchedule` so the DaemonSet also runs on the Ollama GPU node.
3. Generate chat traffic with `owasp_llm` tags; confirm the workload appears.

## Destroy

```bash
terraform destroy
```

GPU nodes are expensive — destroy when finished.
