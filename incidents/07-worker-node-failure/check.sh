#!/usr/bin/env bash
set -Eeuo pipefail
node_name="${LAB_WORKER_NODE:-incident-lab-worker}"
for _ in {1..45}; do
  status="$(kubectl get node "$node_name" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null || true)"
  printf 'node=%s ready=%s\n' "$node_name" "${status:-unknown}"
  if [[ "$status" != 'True' ]]; then
    kubectl -n incident-lab get pods -o wide
    echo 'PASS: worker node is no longer Ready. Test service continuity and observe rescheduling.'
    exit 0
  fi
  sleep 2
done
echo 'FAIL: node did not become NotReady within the observation window.' >&2
exit 1
