# SA Onboarding — facilitator runbook

## Day-1 — Labs 1–3

```bash
cd infrastructure/<aws|azure|gcp>/lab1-3
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
cd infrastructure/<cloud>/lab4-containers
terraform init && apply
# lab4_url → Juice Shop UI → install tracer
terraform destroy
```

No image build — pulls `bkimminich/juice-shop` from Docker Hub.

## Lab 5 — Kubernetes

```bash
cd infrastructure/<cloud>/lab5-kubernetes
terraform init && apply
# lab5_url → install cluster sensor
terraform destroy   # do not leave up
```

## Outputs

| Folder | Outputs |
|--------|---------|
| `lab1-3/` | `lab1_*` · `lab2_*` · `lab3_*` |
| `lab4-containers/` | `lab4_url` |
| `lab5-kubernetes/` | `lab5_url` · kubeconfig hint |
