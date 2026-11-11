#!/bin/bash
# Runs on stock python:3.9-bullseye from Docker Hub — no custom image registry.
set -euo pipefail
pip install --no-cache-dir flask==2.0.3 werkzeug==2.0.3
cat >/tmp/jwz_app.py <<'PY'
from flask import Flask
app = Flask(__name__)

@app.route("/")
def index():
    return {"status": "running", "demo": "cve-detection", "lab": "3-serverless"}

@app.route("/health")
def health():
    return {"ok": True}

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
PY
exec python /tmp/jwz_app.py
