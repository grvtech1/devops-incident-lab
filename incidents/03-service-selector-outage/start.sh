#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab patch service incident-api --type=merge \
  -p='{"spec":{"selector":{"app.kubernetes.io/name":"wrong-api"}}}'
echo 'Incident injected. Follow the traffic path instead of restarting healthy pods.'
