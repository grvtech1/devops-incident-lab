#!/usr/bin/env bash
set -Eeuo pipefail

self_heal="$(kubectl -n argocd get application incident-lab \
  -o jsonpath='{.spec.syncPolicy.automated.selfHeal}' 2>/dev/null || true)"
if [[ "$self_heal" != true ]]; then
  echo 'FAIL: incident-lab is not managed with Argo CD self-heal enabled.' >&2
  exit 1
fi

for _ in {1..30}; do
  replicas="$(kubectl -n incident-lab get deployment incident-api -o jsonpath='{.spec.replicas}')"
  sync_status="$(kubectl -n argocd get application incident-lab \
    -o jsonpath='{.status.sync.status}')"
  health_status="$(kubectl -n argocd get application incident-lab \
    -o jsonpath='{.status.health.status}')"
  printf 'live_replicas=%s sync=%s health=%s\n' \
    "$replicas" "$sync_status" "$health_status"
  if [[ "$replicas" == '2' && "$sync_status" == Synced && "$health_status" == Healthy ]]; then
    echo 'PASS: live replicas match Git and Argo CD reports Synced/Healthy.'
    exit 0
  fi
  sleep 2
done
echo 'FAIL: live and Git state did not converge to Synced/Healthy.' >&2
exit 1
