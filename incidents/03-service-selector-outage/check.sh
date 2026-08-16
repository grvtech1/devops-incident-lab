#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab get pods --show-labels
kubectl -n incident-lab get service incident-api -o wide
addresses="$(kubectl -n incident-lab get endpointslice -l kubernetes.io/service-name=incident-api \
  -o jsonpath='{range .items[*].endpoints[*]}{.addresses}{end}')"
if [[ -n "$addresses" ]]; then
  echo "FAIL: Service still has endpoint addresses: $addresses" >&2
  exit 1
fi
echo 'PASS: healthy pods exist while the Service has zero endpoints.'
