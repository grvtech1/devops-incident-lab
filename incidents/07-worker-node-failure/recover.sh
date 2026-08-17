#!/usr/bin/env bash
set -Eeuo pipefail
node_container="${LAB_WORKER_NODE:-incident-lab-worker}"
recovery_timeout="${NODE_RECOVERY_TIMEOUT:-5m}"
docker unpause "$node_container" >/dev/null 2>&1 || true
kubectl wait --for=condition=Ready "node/$node_container" --timeout="$recovery_timeout"
kubectl -n incident-lab rollout status deployment/incident-api \
  --timeout="$recovery_timeout"
kubectl -n incident-lab get pods -o wide
echo 'Node recovered. Validate application readiness and review pod placement.'
