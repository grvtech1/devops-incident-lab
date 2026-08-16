#!/usr/bin/env bash
set -Eeuo pipefail
for _ in {1..30}; do
  replicas="$(kubectl -n incident-lab get deployment incident-api -o jsonpath='{.spec.replicas}')"
  printf 'declared_live_replicas=%s\n' "$replicas"
  if [[ "$replicas" == '2' ]]; then
    echo 'PASS: Argo CD self-healed the imperative drift back to Git state.'
    exit 0
  fi
  sleep 2
done
echo 'FAIL: drift was not reconciled. Confirm Argo CD manages k8s/overlays/dev with selfHeal enabled.' >&2
exit 1
