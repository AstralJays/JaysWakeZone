# SA Onboarding — facilitator runbook

## Day-1 — Labs 1–3

```bash
cd Lab1-3/infrastructure/<aws|azure|gcp>
cp terraform.tfvars.example terraform.tfvars
terraform init && apply && output
```

**Lab 2 host access** (for Upwind sensor): see [HOST-ACCESS.md](HOST-ACCESS.md)

| Cloud | How |
|-------|-----|
| AWS | `terraform output lab2_ssm_command` → SSM session |
| Azure | set `ssh_public_key`, then `lab2_ssh_command` |
| GCP | `lab2_ssh_command` (`gcloud compute ssh`) |

```bash
terraform destroy
```

## Lab 4 — containers (OWASP Juice Shop)

```bash
cd Lab4/infrastructure/<cloud>
terraform init && apply
# lab4_url → Juice Shop UI → install tracer
terraform destroy
```

No image build — pulls `bkimminich/juice-shop` from Docker Hub.

## Lab 5 — Kubernetes (Wakezone AI)

```bash
cd Lab5/infrastructure/<cloud>
terraform init && apply
# lab5_url → Wakezone AI → install cluster sensor
terraform destroy   # do not leave up
```

No image build — pulls public `papaperk/jwz-agent-lab:0.1.0` (plus `ollama/ollama` for the GPU sidecar).

## Outputs

| Folder | Outputs |
|--------|---------|
| `Lab1-3/infrastructure/<cloud>/` | `lab1_*` · `lab2_*` · `lab3_*` |
| `Lab4/infrastructure/<cloud>/` | `lab4_url` |
| `Lab5/infrastructure/<cloud>/` | `lab5_url` · kubeconfig hint |
