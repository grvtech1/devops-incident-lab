#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
kubectl -n incident-lab set env deployment/incident-api FAILURE_RATE-
kubectl -n incident-lab rollout status deployment/incident-api --timeout=120s
REQUESTS=30 "$ROOT_DIR/scripts/load-test.sh" && {
  echo 'FAIL: recovery validation still observed errors.' >&2
  exit 1
} || true
"$ROOT_DIR/scripts/smoke-test.sh"
echo 'Recovered. The business endpoint is healthy again.'
