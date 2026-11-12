# AWS stack 3/3 — Kubernetes (EKS)

**Independent** Terraform root from `../labs-1-3` and `../containers`.  
**Status:** planned — last / most expensive. Keep destroyed when idle.

When ready:

```bash
cd infrastructure/aws/kubernetes
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

SA installs cluster/node sensor themselves. Destroy in **this** directory only.
