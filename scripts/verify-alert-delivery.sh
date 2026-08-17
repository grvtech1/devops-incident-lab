#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

assert_lab_cluster
command -v curl >/dev/null 2>&1 || { echo 'curl is required.' >&2; exit 1; }

ALERTMANAGER_SERVICE="${ALERTMANAGER_SERVICE:-monitoring-kube-prometheus-alertmanager}"
LOCAL_PORT="${ALERTMANAGER_LOCAL_PORT:-19093}"
RUN_ID="delivery-$(date -u +%Y%m%dT%H%M%SZ)"
STARTS_AT="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
ENDS_AT="$(date -u -d '+2 minutes' +%Y-%m-%dT%H:%M:%SZ)"
LOG_FILE="/tmp/incident-lab-alertmanager-port-forward.log"

kubectl --namespace monitoring port-forward \
  "service/$ALERTMANAGER_SERVICE" "$LOCAL_PORT:9093" >"$LOG_FILE" 2>&1 &
port_forward_pid=$!
trap 'kill "$port_forward_pid" 2>/dev/null || true; wait "$port_forward_pid" 2>/dev/null || true' EXIT

for _ in {1..20}; do
  curl --silent --fail "http://127.0.0.1:$LOCAL_PORT/-/ready" >/dev/null 2>&1 && break
  sleep 1
done
curl --silent --fail "http://127.0.0.1:$LOCAL_PORT/-/ready" >/dev/null

curl --silent --show-error --fail \
  --header 'content-type: application/json' \
  --request POST \
  --data "[{
    \"labels\": {
      \"alertname\": \"IncidentLabDeliveryTest\",
      \"instance\": \"$RUN_ID\",
      \"service\": \"incident-api\",
      \"severity\": \"warning\"
    },
    \"annotations\": {
      \"summary\": \"Synthetic alert used to verify Alertmanager webhook delivery\"
    },
    \"startsAt\": \"$STARTS_AT\",
    \"endsAt\": \"$ENDS_AT\"
  }]" \
  "http://127.0.0.1:$LOCAL_PORT/api/v2/alerts"

echo "Submitted IncidentLabDeliveryTest with instance=$RUN_ID"
for _ in {1..30}; do
  if kubectl --namespace "$NAMESPACE" logs \
      --selector app.kubernetes.io/name=incident-api \
      --all-containers --since=2m 2>/dev/null \
      | grep -F '"message":"alertmanager_notification_received"' \
      | grep -F "\"instance\":\"$RUN_ID\""; then
    echo 'PASS: Alertmanager delivered the synthetic alert to the application webhook.'
    exit 0
  fi
  sleep 3
done

echo 'FAIL: no matching webhook delivery was observed within 90 seconds.' >&2
echo "Inspect Alertmanager and port-forward logs: $LOG_FILE" >&2
exit 1
