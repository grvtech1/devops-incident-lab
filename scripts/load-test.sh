#!/usr/bin/env bash
set -Eeuo pipefail

NAMESPACE="${NAMESPACE:-incident-lab}"
LOCAL_PORT="${LOCAL_PORT:-18080}"
REQUESTS="${REQUESTS:-100}"
LOG_FILE="${TMPDIR:-/tmp}/incident-lab-load-port-forward.log"

kubectl --namespace "$NAMESPACE" port-forward service/incident-api "$LOCAL_PORT:8080" >"$LOG_FILE" 2>&1 &
port_forward_pid=$!
cleanup() {
  kill "$port_forward_pid" >/dev/null 2>&1 || true
  wait "$port_forward_pid" >/dev/null 2>&1 || true
}
trap cleanup EXIT

for _ in {1..20}; do
  curl --silent --fail "http://127.0.0.1:$LOCAL_PORT/health/ready" >/dev/null && break
  sleep 0.5
done

success=0
failure=0
for ((request=1; request<=REQUESTS; request++)); do
  status="$(curl --silent --output /dev/null --write-out '%{http_code}' \
    --request POST "http://127.0.0.1:$LOCAL_PORT/api/orders" || true)"
  if [[ "$status" == '202' ]]; then
    ((success+=1))
  else
    ((failure+=1))
  fi
done

printf 'requests=%d success=%d failure=%d error_rate=%s\n' \
  "$REQUESTS" "$success" "$failure" "$(awk -v f="$failure" -v r="$REQUESTS" 'BEGIN { printf "%.2f", f/r }')"
((failure > 0))
