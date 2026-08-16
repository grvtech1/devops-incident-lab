#!/usr/bin/env bash
set -Eeuo pipefail

NAMESPACE="${NAMESPACE:-incident-lab}"
LOCAL_PORT="${LOCAL_PORT:-18080}"
LOG_FILE="${TMPDIR:-/tmp}/incident-lab-port-forward.log"

kubectl --namespace "$NAMESPACE" port-forward service/incident-api "$LOCAL_PORT:8080" >"$LOG_FILE" 2>&1 &
port_forward_pid=$!
cleanup() {
  kill "$port_forward_pid" >/dev/null 2>&1 || true
  wait "$port_forward_pid" >/dev/null 2>&1 || true
}
trap cleanup EXIT

for _ in {1..20}; do
  if curl --silent --fail "http://127.0.0.1:$LOCAL_PORT/health/ready" >/dev/null; then
    break
  fi
  sleep 0.5
done

curl --silent --fail "http://127.0.0.1:$LOCAL_PORT/health/ready"
echo
curl --silent --fail --request POST "http://127.0.0.1:$LOCAL_PORT/api/orders"
echo
curl --silent --fail "http://127.0.0.1:$LOCAL_PORT/metrics" | grep -E 'incident_lab_(orders|http_requests)_total'
echo 'Smoke test passed.'
