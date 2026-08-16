#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab set env deployment/incident-api ALLOCATE_ON_START_MB-
kubectl -n incident-lab rollout status deployment/incident-api --timeout=120s
echo 'Recovered. Compare working-set evidence with requests/limits before proposing tuning.'
