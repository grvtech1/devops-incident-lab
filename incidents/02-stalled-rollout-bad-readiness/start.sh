#!/usr/bin/env bash
set -Eeuo pipefail
kubectl -n incident-lab patch deployment incident-api --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/health/ready-wrong"}]'
echo 'Incident injected. Inspect rollout, pod conditions, events, and probe responses.'
