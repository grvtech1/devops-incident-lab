#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab patch configmap incident-lab-config --type=merge \
  -p='{"data":{"BACKEND_URL":"http://dependency.incident-lab.svc.cluster.local:8080"}}'
kubectl -n incident-lab rollout restart deployment/incident-api
kubectl -n incident-lab rollout status deployment/incident-api --timeout=120s
echo 'Recovered. Run the smoke test and capture evidence.'
