#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab get deployment,replicaset,pod -l app.kubernetes.io/name=incident-api
if kubectl -n incident-lab rollout status deployment/incident-api --timeout=10s; then
  echo 'FAIL: rollout unexpectedly completed.' >&2
  exit 1
fi
kubectl -n incident-lab get events --sort-by=.metadata.creationTimestamp | tail -n 20
echo 'PASS: rollout is stalled as expected.'
