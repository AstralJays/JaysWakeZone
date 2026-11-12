# AWS stack 2/3 — Managed containers (ECS Fargate)

**Independent** Terraform root from `../labs-1-3` and `../kubernetes`.  
**Status:** planned — not ready to apply (keeps day-1 spend low).

When ready:

```bash
cd infrastructure/aws/containers
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
```

Target: ECS Fargate + public image (no ECR push). SA installs tracer themselves.  
Destroy with `terraform destroy` in **this** directory only.
