#!/usr/bin/env bash
set -Eeuo pipefail
node_container="${LAB_WORKER_NODE:-incident-lab-worker}"
docker inspect "$node_container" >/dev/null

node_ready="$(kubectl get node "$node_container" \
  -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')"
if [[ "$node_ready" != True ]]; then
  printf 'Refusing to pause %s because it is not Ready.\n' "$node_container" >&2
  exit 1
fi

total_replicas="$(kubectl -n incident-lab get pods \
  -l app.kubernetes.io/name=incident-api --no-headers | wc -l | tr -d ' ')"
target_replicas="$(kubectl -n incident-lab get pods \
  -l app.kubernetes.io/name=incident-api \
  --field-selector "spec.nodeName=$node_container" --no-headers | wc -l | tr -d ' ')"

if [[ "$total_replicas" != 2 || "$target_replicas" != 1 ]]; then
  printf 'Refusing node failure: expected two API pods with exactly one on %s; found total=%s target=%s.\n' \
    "$node_container" "$total_replicas" "$target_replicas" >&2
  kubectl -n incident-lab get pods -o wide >&2
  exit 1
fi

docker pause "$node_container"
echo "Paused $node_container. Node readiness may take about a minute to change."
