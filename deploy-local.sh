#!/usr/bin/env bash
# Deploy tricloud-www to a local CRC (OpenShift Local) cluster.
# Usage: ./deploy-local.sh
# Env overrides: APP_NAME, NAMESPACE, CRC_START_TIMEOUT
set -euo pipefail

APP_NAME="${APP_NAME:-tricloud-www}"
NAMESPACE="${NAMESPACE:-tricloud-local}"
CRC_START_TIMEOUT="${CRC_START_TIMEOUT:-600}"   # seconds

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── helpers ───────────────────────────────────────────────────────────────────
log() { printf '\033[0;36m[%s]\033[0m %s\n' "$(date +%H:%M:%S)" "$*"; }
ok()  { printf '\033[0;32m[%s] ✓ %s\033[0m\n' "$(date +%H:%M:%S)" "$*"; }
die() { printf '\033[0;31mERROR: %s\033[0m\n' "$*" >&2; exit 1; }

command -v crc &>/dev/null || die "'crc' not found — install from https://crc.dev/crc"

# ── 1. ensure CRC is running ──────────────────────────────────────────────────
crc_ready() {
  crc status 2>/dev/null | grep -q "OpenShift.*Running"
}

if crc_ready; then
  ok "CRC already running"
else
  log "CRC is not running — starting (this can take several minutes)..."
  crc start || die "crc start failed"

  log "Waiting for OpenShift to become ready (timeout: ${CRC_START_TIMEOUT}s)..."
  elapsed=0
  until crc_ready; do
    sleep 15
    elapsed=$((elapsed + 15))
    if [[ $elapsed -ge $CRC_START_TIMEOUT ]]; then
      die "Timed out after ${CRC_START_TIMEOUT}s waiting for CRC — check: crc status"
    fi
    log "  ...still waiting (${elapsed}s / ${CRC_START_TIMEOUT}s)"
  done
  ok "CRC is ready"
fi

# ── 2. configure oc ───────────────────────────────────────────────────────────
eval "$(crc oc-env)"
command -v oc &>/dev/null || die "'oc' not found even after crc oc-env"

# ── 3. login ──────────────────────────────────────────────────────────────────
log "Logging in to OpenShift..."
oc login -u developer -p developer \
  https://api.crc.testing:6443 \
  --insecure-skip-tls-verify=true 2>&1 | grep -v "^$" || true

# ── 4. project ────────────────────────────────────────────────────────────────
if oc get project "$NAMESPACE" &>/dev/null; then
  oc project "$NAMESPACE" 2>&1 | grep -v "^$" || true
else
  log "Creating project '$NAMESPACE'..."
  oc new-project "$NAMESPACE"
fi

# ── 5. BuildConfig (first run only) ───────────────────────────────────────────
if ! oc get buildconfig "$APP_NAME" &>/dev/null; then
  log "Creating BuildConfig '$APP_NAME'..."
  oc new-build --binary=true --strategy=docker --name="$APP_NAME"
fi

# ── 6. build ──────────────────────────────────────────────────────────────────
log "Starting binary build from ${SCRIPT_DIR}..."
oc start-build "$APP_NAME" --from-dir="$SCRIPT_DIR" --follow --wait

# ── 7. manifests ──────────────────────────────────────────────────────────────
log "Applying manifests..."
oc apply -f "${SCRIPT_DIR}/deploy/"

# ── 8. patch deployment with the exact built image SHA ────────────────────────
log "Resolving built image reference..."
IMAGE_REF=$(oc get istag "${APP_NAME}:latest" \
  -o jsonpath='{.image.dockerImageReference}' 2>/dev/null || true)

[[ -z "$IMAGE_REF" ]] && die "Could not resolve image reference from ImageStream '${APP_NAME}:latest'"

log "Patching deployment image → ${IMAGE_REF}"
oc set image deployment/"$APP_NAME" "${APP_NAME}=${IMAGE_REF}"

# ── 9. wait for rollout ───────────────────────────────────────────────────────
log "Waiting for rollout to complete..."
oc rollout status deployment/"$APP_NAME" --timeout=120s

# ── 10. print URL ─────────────────────────────────────────────────────────────
ROUTE_HOST=$(oc get route "$APP_NAME" \
  -o jsonpath='{.spec.host}' 2>/dev/null || true)

if [[ -n "$ROUTE_HOST" ]]; then
  ok "Done! → http://${ROUTE_HOST}"
else
  ok "Deployed — no route found yet. Expose with: oc expose svc/${APP_NAME}"
fi
