#!/usr/bin/env bash
set -Eeuo pipefail
for _ in {1..30}; do
  reasons="$(kubectl -n incident-lab get pods -l app.kubernetes.io/name=incident-api \
    -o jsonpath='{range .items[*]}{.metadata.name}{" "}{.status.containerStatuses[0].lastState.terminated.reason}{"\n"}{end}')"
  printf '%s\n' "$reasons"
  if grep -q 'OOMKilled' <<<"$reasons"; then
    echo 'PASS: Kubernetes recorded an OOMKilled termination.'
    exit 0
  fi
  sleep 2
done
echo 'FAIL: no OOMKilled termination observed within 60 seconds.' >&2
kubectl -n incident-lab describe pods -l app.kubernetes.io/name=incident-api
exit 1
