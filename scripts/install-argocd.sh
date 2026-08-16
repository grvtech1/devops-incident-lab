#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARGOCD_VERSION="${ARGOCD_VERSION:-v3.4.2}"
REPO_URL="${REPO_URL:?Set REPO_URL to the public GitHub clone URL.}"
GITOPS_PATH="${GITOPS_PATH:-k8s/overlays/dev}"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply --server-side --force-conflicts --namespace argocd \
  --filename "https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml"
kubectl wait --namespace argocd --for=condition=Available deployment/argocd-server --timeout=300s

sed "s|REPLACE_REPO_URL|$REPO_URL|g" "$ROOT_DIR/argocd/project.yaml" | kubectl apply -f -
sed -e "s|REPLACE_REPO_URL|$REPO_URL|g" \
    -e "s|REPLACE_GITOPS_PATH|$GITOPS_PATH|g" \
    "$ROOT_DIR/argocd/application.yaml" | kubectl apply -f -

cat <<'EOF'
Argo CD installed. Access it locally with:
  kubectl -n argocd port-forward svc/argocd-server 8443:443

Retrieve the initial admin secret only for first login, then rotate/disable it:
  kubectl -n argocd get secret argocd-initial-admin-secret \
    -o jsonpath='{.data.password}' | base64 -d; echo
EOF
