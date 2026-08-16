#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab set env deployment/incident-api FAILURE_RATE=0.75
kubectl -n incident-lab rollout status deployment/incident-api --timeout=120s
echo 'Incident injected. Pods are expected to remain Ready; test the business endpoint.'
