# Optional local build only. Terraform uses Docker Hub python:3.9-bullseye + boot command.
FROM python:3.9-bullseye

WORKDIR /app

RUN pip install --no-cache-dir flask==2.0.3 werkzeug==2.0.3

COPY app.py .

EXPOSE 8080

CMD ["python", "app.py"]
