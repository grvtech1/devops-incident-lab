#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab set env deployment/incident-api ALLOCATE_ON_START_MB=192
echo 'Incident injected. Wait for a restart, then inspect lastState and resource limits.'
