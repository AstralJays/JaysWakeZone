#!/usr/bin/env bash
# Install Webmin with intentional weak credentials for SA onboarding.
# Demo story: internet-exposed Linux admin UI → admin/password → host compromise.
set -euxo pipefail

WEBMIN_USER="${WEBMIN_USER:-admin}"
WEBMIN_PASS="${WEBMIN_PASS:-password}"

export DEBIAN_FRONTEND=noninteractive

# Official repo setup (idempotent-ish)
curl -fsSL https://raw.githubusercontent.com/webmin/webmin/master/setup-repos.sh -o /tmp/webmin-setup-repos.sh
sh /tmp/webmin-setup-repos.sh --force || true

apt-get update -y
apt-get install -y webmin || apt-get install -y webmin --allow-unauthenticated

# Ensure a local Linux user exists for Webmin PAM auth (Webmin uses system accounts)
if ! id -u "$WEBMIN_USER" >/dev/null 2>&1; then
  useradd -m -s /bin/bash "$WEBMIN_USER"
fi
echo "${WEBMIN_USER}:${WEBMIN_PASS}" | chpasswd
usermod -aG sudo "$WEBMIN_USER" 2>/dev/null || usermod -aG wheel "$WEBMIN_USER" 2>/dev/null || true
# Passwordless sudo so "full server compromise" demos work after login
echo "${WEBMIN_USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/99-jayswakezone-webmin
chmod 440 /etc/sudoers.d/99-jayswakezone-webmin

# Bind on all interfaces, allow from anywhere (intentional lab exposure)
if [[ -f /etc/webmin/miniserv.conf ]]; then
  sed -i 's/^allow=.*/allow=/' /etc/webmin/miniserv.conf || true
  grep -q '^listen=' /etc/webmin/miniserv.conf || echo 'listen=10000' >>/etc/webmin/miniserv.conf
  # Drop IP allowlist if present
  sed -i '/^allow=/d' /etc/webmin/miniserv.conf
  echo 'allow=' >>/etc/webmin/miniserv.conf
fi

systemctl enable webmin || true
systemctl restart webmin || /etc/webmin/start || true

echo "Webmin listening on :10000 — login ${WEBMIN_USER}/${WEBMIN_PASS}"
