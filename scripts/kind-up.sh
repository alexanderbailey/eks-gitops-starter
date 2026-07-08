#!/usr/bin/env bash
# ---------------------------------------------------------------------------
# kind-up.sh — reproduce the GitOps plane locally on kind, no AWS, no bill.
#
# It plays the role Terraform plays on AWS (create a cluster, install Argo CD)
# and then hands off to GitOps exactly as the real thing does: an app-of-apps
# pointed at THIS checkout reconciles ingress-nginx and the demo apps.
#
# So it can reflect your uncommitted working tree (and needs no GitHub access),
# the checkout is served from a throwaway in-cluster git server; the app-of-apps
# and every child Application pull from there. AWS-only seams are swapped by the
# `local` overlays (ingress-nginx for ALB, in-cluster Postgres for RDS, no ESO).
#
# Usage: scripts/kind-up.sh [--ci]
# ---------------------------------------------------------------------------
set -euo pipefail

CI=false
[[ "${1:-}" == "--ci" ]] && CI=true

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER="${KIND_CLUSTER:-eks-gitops-starter}"

# Pinned; bump deliberately.
ARGOCD_VERSION="v2.13.2"
GIT_SERVER_IMAGE="alpine:3.20"
GIT_PORT=9418

log() { printf '\n\033[1;34m==>\033[0m %s\n' "$*"; }

require() { command -v "$1" >/dev/null 2>&1 || { echo "missing required tool: $1" >&2; exit 1; }; }
require kind
require kubectl
require docker
require git

# --------------------------------------------------------------- 1. cluster
if kind get clusters 2>/dev/null | grep -qx "$CLUSTER"; then
  log "kind cluster '$CLUSTER' already exists — reusing it"
else
  log "creating kind cluster '$CLUSTER'"
  # Map the ingress-nginx NodePort (30080) to localhost:8080 so the frontend is
  # reachable at http://localhost:8080 once it's reconciled.
  kind create cluster --name "$CLUSTER" --wait 120s --config - <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 8080
        protocol: TCP
EOF
fi
kubectl config use-context "kind-${CLUSTER}" >/dev/null

# --------------------------------------------------------------- 2. Argo CD
log "installing Argo CD ${ARGOCD_VERSION}"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd \
  -f "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
log "waiting for Argo CD to be ready"
kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=300s
kubectl -n argocd rollout status deploy/argocd-server --timeout=300s
kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s

# ---------------------------------------------- 3. in-cluster git server + push
log "starting in-cluster git server and pushing this checkout"
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: git-server
  namespace: default
  labels: { app: git-server }
spec:
  replicas: 1
  selector: { matchLabels: { app: git-server } }
  template:
    metadata: { labels: { app: git-server } }
    spec:
      containers:
        - name: git-daemon
          image: ${GIT_SERVER_IMAGE}
          command: ["/bin/sh", "-c"]
          args:
            - |
              set -e
              # 'git daemon' lives in the git-daemon subpackage, not plain git.
              apk add --no-cache git-daemon
              git init --bare /srv/git/repo.git
              exec git daemon --reuseaddr --base-path=/srv/git --export-all \
                --enable=receive-pack --listen=0.0.0.0 --port=${GIT_PORT} --verbose
          ports:
            - containerPort: ${GIT_PORT}
          readinessProbe:
            tcpSocket:
              port: ${GIT_PORT}
            initialDelaySeconds: 3
            periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: git-server
  namespace: default
spec:
  selector: { app: git-server }
  ports:
    - port: ${GIT_PORT}
      targetPort: ${GIT_PORT}
EOF
if ! kubectl -n default rollout status deploy/git-server --timeout=180s; then
  echo "git-server did not become ready; diagnostics:" >&2
  kubectl -n default logs deploy/git-server --tail=50 >&2 || true
  kubectl -n default describe pod -l app=git-server >&2 || true
  exit 1
fi

# Port-forward so we can push from the host; clean it up on exit.
kubectl -n default port-forward svc/git-server "${GIT_PORT}:${GIT_PORT}" >/dev/null 2>&1 &
PF_PID=$!
trap 'kill "${PF_PID}" 2>/dev/null || true' EXIT
# Wait for the forward to accept connections.
for _ in $(seq 1 30); do
  (exec 3<>"/dev/tcp/127.0.0.1/${GIT_PORT}") 2>/dev/null && { exec 3>&- 3<&-; break; }
  sleep 1
done

# Snapshot the working tree (tracked + untracked, minus .gitignore) into a
# detached commit via a temporary index — the real index/HEAD is untouched.
# The index path must not exist yet (git rejects an empty file as a bad index),
# so put it inside a fresh temp dir rather than using `mktemp` directly.
SNAP_DIR="$(mktemp -d)"
TMP_INDEX="${SNAP_DIR}/index"
GIT_INDEX_FILE="$TMP_INDEX" git -C "$ROOT" add -A
SNAP_TREE="$(GIT_INDEX_FILE="$TMP_INDEX" git -C "$ROOT" write-tree)"
# Identity is set explicitly so this works on a fresh CI runner with no git config.
SNAP_COMMIT="$(
  GIT_AUTHOR_NAME=kind-up GIT_AUTHOR_EMAIL=kind-up@localhost \
  GIT_COMMITTER_NAME=kind-up GIT_COMMITTER_EMAIL=kind-up@localhost \
  git -C "$ROOT" commit-tree "$SNAP_TREE" -m 'kind-up snapshot'
)"
rm -rf "$SNAP_DIR"
git -C "$ROOT" push -f "git://127.0.0.1:${GIT_PORT}/repo.git" "${SNAP_COMMIT}:refs/heads/main"

# --------------------------------------------------------------- 4. app-of-apps
log "applying the app-of-apps (bootstrap/overlays/local)"
kubectl apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: app-of-apps
  namespace: argocd
spec:
  project: default
  source:
    repoURL: git://git-server.default.svc.cluster.local:${GIT_PORT}/repo.git
    targetRevision: main
    path: bootstrap/overlays/local
  destination:
    server: https://kubernetes.default.svc
    namespace: argocd
  syncPolicy:
    automated: { prune: true, selfHeal: true }
    syncOptions: [ "CreateNamespace=true" ]
EOF

log "cluster is up and Argo CD is reconciling."
if [[ "$CI" == "false" ]]; then
  cat <<EOF

Next:
  scripts/kind-wait.sh          # block until every app is Synced + Healthy
  http://localhost:8080         # the frontend, once healthy
  kubectl -n argocd get applications
  task kind-down                # tear it all down
EOF
fi
