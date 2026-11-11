#!/usr/bin/env bash
# Optional Upwind host sensor install (same pattern as TraditionalJay).
set -euo pipefail

if [[ -z "${UPWIND_CLIENT_ID:-}" || -z "${UPWIND_CLIENT_SECRET:-}" ]]; then
  echo "UPWIND_CLIENT_ID / UPWIND_CLIENT_SECRET unset — skipping sensor install."
  exit 0
fi

# inuse-python=true (default) + don't skip the freshly-started estimator process
# so CVE-2023-36188 PALChain / PythonREPL show as Function in use.
DEFAULT_EXTRA="scanner-v2=true,inuse-python=true,inuse-skip-young-process=false"

curl -s https://get.upwind.io/sensor.sh | \
  UPWIND_CLIENT_ID="$UPWIND_CLIENT_ID" \
  UPWIND_CLIENT_SECRET="$UPWIND_CLIENT_SECRET" \
  UPWIND_AGENT_EXTRA_CONFIG="${UPWIND_AGENT_EXTRA_CONFIG:-$DEFAULT_EXTRA}" \
  bash -s
