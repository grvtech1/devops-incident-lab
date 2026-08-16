#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
kubectl apply -k "$ROOT_DIR/k8s/overlays/dev"
kubectl -n incident-lab rollout status deployment/incident-api --timeout=120s
echo 'Baseline restored. Record whether Argo or the manual recovery performed the correction.'
