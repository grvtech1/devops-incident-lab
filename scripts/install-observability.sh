#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART_VERSION="${KUBE_PROMETHEUS_STACK_VERSION:-87.21.0}"
HELM_TIMEOUT="${OBSERVABILITY_HELM_TIMEOUT:-20m}"
source "$ROOT_DIR/scripts/lib.sh"

assert_lab_cluster

command -v helm >/dev/null 2>&1 || { echo 'helm is required.' >&2; exit 1; }
GRAFANA_ADMIN_PASSWORD="${GRAFANA_ADMIN_PASSWORD:?Set GRAFANA_ADMIN_PASSWORD without committing it.}"

helm upgrade --install monitoring \
  oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
  --version "$CHART_VERSION" \
  --namespace monitoring \
  --create-namespace \
  --values "$ROOT_DIR/monitoring/kube-prometheus-values.yaml" \
  --set-string grafana.adminPassword="$GRAFANA_ADMIN_PASSWORD" \
  --wait \
  --timeout "$HELM_TIMEOUT"

kubectl apply --filename "$ROOT_DIR/monitoring/service-monitor.yaml"
kubectl apply --filename "$ROOT_DIR/monitoring/prometheus-rules.yaml"
kubectl apply --filename "$ROOT_DIR/monitoring/grafana-dashboard.yaml"

cat <<'EOF'
Observability installed.
Grafana:    kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
Prometheus: kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
Alerts:     kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-alertmanager 9093:9093
EOF
