#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab patch deployment incident-api --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/health/ready"}]'
kubectl -n incident-lab rollout status deployment/incident-api --timeout=120s
echo 'Recovered. Validate endpoint continuity and record why liveness was insufficient.'
