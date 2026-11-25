"""AWS Lambda (zip) — no container registry. Same demo shape as the Flask app."""
import json


def handler(event, context):
    body = {
        "status": "running",
        "demo": "cve-detection",
        "lab": "3-serverless",
        "runtime": "aws-lambda",
    }
    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json"},
        "body": json.dumps(body),
    }
