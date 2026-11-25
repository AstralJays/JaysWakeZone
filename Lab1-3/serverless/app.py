"""AWS Lambda handler (zip). Terraform packages this file as app.lambda_handler."""
import json
import mmap
import os
import socket


def _attack(event):
    """Direct invoke uses event.attack. Function URL uses ?attack= or JSON body."""
    if not isinstance(event, dict):
        return None
    if event.get("attack"):
        return event["attack"]
    qs = event.get("queryStringParameters") or {}
    if qs.get("attack"):
        return qs["attack"]
    body = event.get("body")
    if not body:
        return None
    if event.get("isBase64Encoded"):
        import base64

        body = base64.b64decode(body).decode()
    try:
        data = json.loads(body)
    except json.JSONDecodeError:
        return None
    if isinstance(data, dict):
        return data.get("attack")
    return None


def lambda_handler(event, context):
    event = event or {}
    attack = _attack(event)
    pid = os.getpid()

    if attack == "discovery":
        with open("/etc/passwd", "r") as f:
            f.read()

    elif attack == "network":
        with socket.create_connection(("example.com", 443), timeout=5):
            pass

    elif attack == "malware":
        with open("/tmp/eicar.com", "w") as f:
            f.write(
                r"X5O!P%@AP[4\PZX54(P^)7CC)7}"
                r"$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*"
            )

    elif attack == "memory":
        with mmap.mmap(
            -1,
            4096,
            prot=mmap.PROT_READ | mmap.PROT_WRITE | mmap.PROT_EXEC,
        ) as mem:
            mem.write(b"Security test")

    result = {
        "attack": attack,
        "pid": pid,
        "executable": os.readlink("/proc/self/exe"),
        "status": "completed",
    }

    if "requestContext" in event:
        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps(result),
        }
    return result
