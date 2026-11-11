# Intentionally older Debian + pinned Flask for agentless / image CVE demos.
# Published to ghcr.io/astraljays/jayswakezone-flask (public) — no ECR/ACR/GAR needed.
FROM python:3.9-bullseye

WORKDIR /app

RUN pip install --no-cache-dir flask==2.0.3 werkzeug==2.0.3

COPY app.py .

EXPOSE 8080

CMD ["python", "app.py"]
