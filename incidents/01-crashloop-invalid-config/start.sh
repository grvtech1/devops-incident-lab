#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab patch configmap incident-lab-config --type=merge \
  -p='{"data":{"BACKEND_URL":"not-a-valid-url"}}'
kubectl -n incident-lab rollout restart deployment/incident-api
echo 'Incident injected. Investigate before opening SOLUTION.md.'
