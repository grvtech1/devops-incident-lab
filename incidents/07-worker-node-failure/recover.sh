#!/usr/bin/env bash
set -Eeuo pipefail
node_container="${LAB_WORKER_NODE:-incident-lab-worker}"
recovery_timeout="${NODE_RECOVERY_TIMEOUT:-5m}"
docker unpause "$node_container" >/dev/null 2>&1 || true
kubectl wait --for=condition=Ready "node/$node_container" --timeout="$recovery_timeout"
kubectl -n incident-lab rollout status deployment/incident-api \
  --timeout="$recovery_timeout"

terminating_pods="$(kubectl -n incident-lab get pods \
  -l app.kubernetes.io/name=incident-api \
  -o go-template='{{range .items}}{{if .metadata.deletionTimestamp}}{{.metadata.name}}{{"\n"}}{{end}}{{end}}')"
while IFS= read -r pod; do
  [[ -z "$pod" ]] && continue
  kubectl -n incident-lab wait --for=delete "pod/$pod" --timeout=2m || true
done <<<"$terminating_pods"

pods_on_recovered_node="$(kubectl -n incident-lab get pods \
  -l app.kubernetes.io/name=incident-api \
  --field-selector "spec.nodeName=$node_container,status.phase=Running" \
  --no-headers | wc -l | tr -d ' ')"

if [[ "$pods_on_recovered_node" == 0 ]]; then
  rebalance_pod="$(kubectl -n incident-lab get pods \
    -l app.kubernetes.io/name=incident-api \
    --field-selector status.phase=Running \
    -o jsonpath='{.items[0].metadata.name}')"
  printf 'Evicting %s through the policy API to restore one replica per worker.\n' \
    "$rebalance_pod"
  kubectl create --raw \
    "/api/v1/namespaces/incident-lab/pods/$rebalance_pod/eviction" \
    -f - <<EOF
{"apiVersion":"policy/v1","kind":"Eviction","metadata":{"name":"$rebalance_pod","namespace":"incident-lab"}}
EOF
  kubectl -n incident-lab rollout status deployment/incident-api \
    --timeout="$recovery_timeout"
fi

kubectl -n incident-lab get pods -o wide
echo 'Node recovered. Validate application readiness and review pod placement.'
