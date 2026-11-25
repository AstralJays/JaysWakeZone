# Lab 3 — Serverless

Part of the default grab-and-go apply. You do **not** build or push images.

| Cloud | Terraform gives you | What runs |
|-------|---------------------|-----------|
| AWS | Lambda + Function URL | `app.py` (`lambda_handler`) — zip, no image |
| Azure | App Service URL | public `python:3.9-bullseye` + inline Flask boot |
| GCP | Cloud Run URL | public `python:3.9-bullseye` + inline Flask boot |

## AWS Lambda signals

After apply, `terraform output lab3_function_url`, then:

```bash
curl "$URL?attack=discovery"   # read /etc/passwd
curl "$URL?attack=network"     # TCP to example.com:443
curl "$URL?attack=malware"     # write EICAR test string to /tmp
curl "$URL?attack=memory"      # RWX mmap
```

Console test events can use `{"attack":"discovery"}` directly.

Install the Upwind **Lambda tracer** yourself (portal — typically a layer + env, not a custom image).

## Deploy / destroy

Use the parent stack: [`../README.md`](../README.md) (`Lab1-3/infrastructure/<cloud>/`).
