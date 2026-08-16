#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGOCD_VERSION="${ARGOCD_VERSION:-v3.4.2}"
ARGOCD_WAIT_TIMEOUT="${ARGOCD_WAIT_TIMEOUT:-15m}"
REPO_URL="${REPO_URL:?Set REPO_URL to the public GitHub clone URL.}"
GITOPS_PATH="${GITOPS_PATH:-k8s/overlays/dev}"
source "$ROOT_DIR/scripts/lib.sh"

assert_lab_cluster

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side --force-conflicts --namespace argocd \
  --filename "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
kubectl wait --namespace argocd --for=condition=Available deployment --all \
  --timeout="$ARGOCD_WAIT_TIMEOUT"
kubectl rollout status statefulset/argocd-application-controller \
  --namespace argocd --timeout="$ARGOCD_WAIT_TIMEOUT"

sed "s|REPLACE_REPO_URL|$REPO_URL|g" "$ROOT_DIR/argocd/project.yaml" | kubectl apply -f -
sed -e "s|REPLACE_REPO_URL|$REPO_URL|g" \
    -e "s|REPLACE_GITOPS_PATH|$GITOPS_PATH|g" \
    "$ROOT_DIR/argocd/application.yaml" | kubectl apply -f -

for _ in {1..120}; do
  sync_status="$(kubectl --namespace argocd get application incident-lab \
    -o jsonpath='{.status.sync.status}' 2>/dev/null || true)"
  health_status="$(kubectl --namespace argocd get application incident-lab \
    -o jsonpath='{.status.health.status}' 2>/dev/null || true)"
  printf 'Argo CD application: sync=%s health=%s\n' \
    "${sync_status:-Pending}" "${health_status:-Pending}"
  if [[ "$sync_status" == Synced && "$health_status" == Healthy ]]; then
    break
  fi
  sleep 5
done

if [[ "${sync_status:-}" != Synced || "${health_status:-}" != Healthy ]]; then
  echo 'Argo CD Application did not reach Synced/Healthy within 10 minutes.' >&2
  kubectl --namespace argocd describe application incident-lab >&2 || true
  exit 1
fi

cat <<'EOF'
Argo CD installed. Access it locally with:
  kubectl -n argocd port-forward svc/argocd-server 8443:443

Retrieve the initial admin secret only for first login, then rotate/disable it:
  kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' | base64 -d; echo
EOF
