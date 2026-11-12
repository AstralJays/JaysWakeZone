"""CVE demo Flask app — Lab 5 Kubernetes workload."""
import os
from flask import Flask

app = Flask(__name__)
LAB = os.environ.get("JWZ_LAB", "5-kubernetes")


@app.route("/")
def index():
    return {"status": "running", "demo": "cve-detection", "lab": LAB}


@app.route("/health")
def health():
    return {"ok": True}


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT", "8080")))
