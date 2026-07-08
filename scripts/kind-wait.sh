#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# kind-wait.sh — block until the whole GitOps plane has converged.
#
# Polls Argo CD until at least EXPECTED_APPS Applications exist and every one is
# both Synced and Healthy. On timeout it dumps app/pod state and exits non-zero,
# so it doubles as the CI smoke-test assertion.
#
# Env: TIMEOUT (seconds, default 900), EXPECTED_APPS (default 6:
#      app-of-apps + platform-addons + ingress-nginx + the 3 demo apps).
# ---------------------------------------------------------------------------
set -euo pipefail

NS=argocd
TIMEOUT="${TIMEOUT:-900}"
EXPECTED_APPS="${EXPECTED_APPS:-6}"

apps_table() {
  kubectl -n "$NS" get applications.argoproj.io -o \
    jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.sync.status}{"\t"}{.status.health.status}{"\n"}{end}' \
    2>/dev/null
}

dump_diagnostics() {
  echo "----- applications -----"
  kubectl -n "$NS" get applications.argoproj.io -o wide 2>/dev/null || true
  echo "----- pods (all namespaces) -----"
  kubectl get pods -A 2>/dev/null || true
  echo "----- recent events -----"
  kubectl get events -A --sort-by=.lastTimestamp 2>/dev/null | tail -30 || true
}

deadline=$(( $(date +%s) + TIMEOUT ))
echo "Waiting up to ${TIMEOUT}s for >=${EXPECTED_APPS} apps to be Synced + Healthy..."

while :; do
  table="$(apps_table || true)"
  total="$(printf '%s\n' "$table" | grep -c . || true)"
  ready="$(printf '%s\n' "$table" | awk -F'\t' '$2=="Synced" && $3=="Healthy"' | grep -c . || true)"

  printf '\n[%(%H:%M:%S)T] %s/%s ready (need >=%s apps)\n' -1 "$ready" "$total" "$EXPECTED_APPS"
  printf '%s\n' "$table" | sed 's/^/  /'

  if [[ "$total" -ge "$EXPECTED_APPS" && "$total" -eq "$ready" ]]; then
    echo ""
    echo "All ${total} applications are Synced + Healthy."
    exit 0
  fi

  if [[ "$(date +%s)" -ge "$deadline" ]]; then
    echo ""
    echo "TIMED OUT after ${TIMEOUT}s — not everything converged." >&2
    dump_diagnostics
    exit 1
  fi

  sleep 10
done
