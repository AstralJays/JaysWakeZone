# Lab 5 walkthrough — Agentic API Lab

## Deploy (Kubernetes)

```bash
cd infrastructure/<cloud>/lab5-kubernetes
cp terraform.tfvars.example terraform.tfvars
# set container_image = "YOURUSER/jwz-agent-lab:0.1.0"
terraform init && terraform apply
terraform output lab5_url
```

Open the URL → one page, steps 1→6 on the left.

## Path

1. **Login** as `alice@surf.lab` / any password → save token  
2. **Order 102** → Bob’s card last4 (BOLA)  
3. **Users** → admin `api_key` in the JSON  
4. **Promote** → admin flags  
5. **Chat** → ignore previous instructions / vault secret  
6. **Research** `http://127.0.0.1:8080/internal/metadata` (in-pod) → IAM/secret hint  

Optional: install Upwind cluster sensor, generate traffic through the six steps.

## Destroy

```bash
terraform destroy
```
