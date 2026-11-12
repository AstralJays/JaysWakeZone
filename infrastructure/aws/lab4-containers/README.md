# AWS Lab 4 — ECS Fargate + Juice Shop

```bash
cd infrastructure/aws/lab4-containers
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab4_url
```

Image: `bkimminich/juice-shop` (Docker Hub). **No ECR.**  
ALB is hourly — destroy when done. Install Upwind tracer yourself.
