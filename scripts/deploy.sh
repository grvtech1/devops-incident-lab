#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-incident-lab}"
IMAGE="${IMAGE:-devops-incident-lab:local}"
deployment_exists=false

if kubectl get deployment incident-api --namespace incident-lab >/dev/null 2>&1; then
  deployment_exists=true
fi

docker build --tag "$IMAGE" "$ROOT_DIR"
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"
kubectl apply --server-side --filename "$ROOT_DIR/k8s/base/namespace.yaml"
kubectl apply --kustomize "$ROOT_DIR/k8s/overlays/dev"

# The local tag is intentionally mutable; applying an unchanged pod template
# does not replace pods after kind loads a rebuilt image under the same tag.
if [[ "$deployment_exists" == true ]]; then
  kubectl rollout restart deployment/incident-api --namespace incident-lab
fi

kubectl rollout status deployment/incident-api --namespace incident-lab --timeout=120s
bash "$ROOT_DIR/scripts/smoke-test.sh"
