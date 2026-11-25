# Lab 5 walkthrough — Wakezone AI (OWASP LLM)

## Deploy (Kubernetes)

```bash
cd Lab5/infrastructure/<cloud>
cp terraform.tfvars.example terraform.tfvars
terraform init && terraform apply
terraform output lab5_url
```

Uses public image `papaperk/jwz-agent-lab:0.1.0` by default.

Open the URL → Wakezone AI chat + OWASP LLM sidebar.

Status light should go **ollama** once the GPU pod is ready and `llama3.2` is pulled (can take a few minutes). Until then, guided/simulated replies still work.

## Path

1. **LLM01** — click Prompt injection → Send → expect `OVERRIDE_OK` + secrets  
2. **LLM02** — staff PIN / wholesale code in the reply  
3. **LLM04** — Plant tip (FREEBOARD) → ask about FREEBOARD / promo  
4. **LLM06** — ship booking `JWZ-10847` (or Hijack button) → address mutates with no approval  
5. **LLM07** — dump system prompt / INTERNAL workshop notes  
6. **AGENT** — Research `http://127.0.0.1:8080/internal/metadata` → IAM / vault hint  

LLM03 is SCA-only (image deps). LLM05/08/09/10 work from the same sidebar.

Optional: Upwind cluster sensor — tagged chat traffic shows `owasp_llm=LLM0x` on `/api/chat`.

## Destroy

```bash
terraform destroy
```
