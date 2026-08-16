#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab get deployment,replicaset,pod -l app.kubernetes.io/name=incident-api

matching_logs="$(
  kubectl -n incident-lab logs -l app.kubernetes.io/name=incident-api \
    --all-containers --prefix --tail=80 2>&1 \
    | grep 'startup_validation_failed' \
    | tail -n 5 || true
)"

if [[ -z "$matching_logs" ]]; then
  echo 'FAIL: startup validation failure was not found in application logs.' >&2
  exit 1
fi

printf '%s\n' "$matching_logs"
echo 'PASS: startup validation failure is observable in application logs.'
