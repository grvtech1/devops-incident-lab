#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-incident-lab}"
IMAGE="${IMAGE:-devops-incident-lab:local}"

docker build --tag "$IMAGE" "$ROOT_DIR"
kind load docker-image "$IMAGE" --name "$CLUSTER_NAME"
kubectl apply --server-side --filename "$ROOT_DIR/k8s/base/namespace.yaml"
kubectl apply --kustomize "$ROOT_DIR/k8s/overlays/dev"
kubectl rollout status deployment/incident-api --namespace incident-lab --timeout=120s
bash "$ROOT_DIR/scripts/smoke-test.sh"
