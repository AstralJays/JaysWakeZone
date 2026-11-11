#!/usr/bin/env bash
# Cloud-init / manual installer for Lab 2 — VM and Hosts (DVWA-lite + Webmin).
set -euxo pipefail

REPO_URL="${REPO_URL:-https://github.com/AstralJays/JaysWakeZone.git}"
REPO_REF="${REPO_REF:-main}"
APP_DIR="${APP_DIR:-/opt/jayswakezone}"
PORT="${PORT:-8080}"

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y git curl ca-certificates docker.io docker-compose-v2 || apt-get install -y git curl ca-certificates docker.io docker-compose
systemctl enable --now docker || true

rm -rf "$APP_DIR"
git clone --depth 1 --branch "$REPO_REF" "$REPO_URL" "$APP_DIR"

cd "$APP_DIR/lab2-wakezone-app"
docker compose up -d --build

cat >/etc/systemd/system/jayswakezone.service <<EOF
[Unit]
Description=Jay's Wake Zone Lab 2
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=${APP_DIR}/lab2-wakezone-app
ExecStart=/usr/bin/docker compose up -d --build
ExecStop=/usr/bin/docker compose down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now jayswakezone.service

# Exposed Linux admin UI — intentional weak creds (admin / password)
chmod +x "$APP_DIR/scripts/install-webmin.sh"
WEBMIN_USER=admin WEBMIN_PASS=password "$APP_DIR/scripts/install-webmin.sh" || true

echo "Wake Zone listening on :${PORT} — open /labs"
echo "Webmin listening on :10000 — login admin / password"
