#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab scale deployment/incident-api --replicas=5
echo 'Drift injected. Observe Argo CD application state and reconciliation events.'
