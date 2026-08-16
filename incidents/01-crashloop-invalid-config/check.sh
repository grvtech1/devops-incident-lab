#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab get deployment,replicaset,pod -l app.kubernetes.io/name=incident-api
kubectl -n incident-lab logs -l app.kubernetes.io/name=incident-api --all-containers --prefix --tail=80 2>&1 \
  | tee /dev/stderr | grep -q 'startup_validation_failed'
echo 'PASS: startup validation failure is observable in application logs.'
