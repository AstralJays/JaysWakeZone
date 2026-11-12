# Infrastructure

Pick **one** cloud. Each numbered folder is a separate `terraform apply`.

```text
aws|azure|gcp/
  lab1-3/              Labs 1 + 2 + 3 — day-1 onboarding
  lab4-containers/     Lab 4 — ECS / ACA / Cloud Run
  lab5-kubernetes/     Lab 5 — EKS / AKS / GKE
```

```bash
cd infrastructure/aws/lab1-3    # start here
terraform init && terraform apply
```
