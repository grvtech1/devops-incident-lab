#!/usr/bin/env bash
set -Eeuo pipefail
node_container="${LAB_WORKER_NODE:-incident-lab-worker}"
docker unpause "$node_container" >/dev/null 2>&1 || true
kubectl wait --for=condition=Ready "node/$node_container" --timeout=120s
kubectl -n incident-lab get pods -o wide
echo 'Node recovered. Validate application readiness and review pod placement.'
