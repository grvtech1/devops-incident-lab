#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab patch service incident-api --type=merge \
  -p='{"spec":{"selector":{"app.kubernetes.io/name":"incident-api"}}}'
sleep 2
kubectl -n incident-lab get endpointslice -l kubernetes.io/service-name=incident-api
echo 'Recovered. Run the smoke test; no pod restart should be required.'
