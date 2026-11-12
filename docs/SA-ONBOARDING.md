# SA Onboarding — facilitator runbook

## Day-1 — Labs 1–3

```bash
cd infrastructure/<aws|azure|gcp>/lab1-3
cp terraform.tfvars.example terraform.tfvars
terraform init && apply && output
terraform destroy
```

## Lab 4 — containers

```bash
cd infrastructure/<cloud>/lab4-containers
terraform init && apply
# lab4_url → install tracer
terraform destroy
```

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
