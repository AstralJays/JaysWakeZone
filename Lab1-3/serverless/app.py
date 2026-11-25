"""Minimal Flask app on an older base image — agentless / image CVE demo."""
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
