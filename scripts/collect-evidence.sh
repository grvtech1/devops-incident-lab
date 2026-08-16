#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"
assert_lab_cluster

incident="${1:-manual}"
timestamp="$(date -u +'%Y%m%dT%H%M%SZ')"
output_dir="$ROOT_DIR/evidence/runs/${timestamp}-${incident}"
mkdir -p "$output_dir"

kubectl config current-context >"$output_dir/context.txt"
kubectl --namespace "$NAMESPACE" get all -o wide >"$output_dir/workloads.txt"
kubectl --namespace "$NAMESPACE" get deployment incident-api -o yaml >"$output_dir/deployment.yaml"
kubectl --namespace "$NAMESPACE" get service incident-api -o yaml >"$output_dir/service.yaml"
kubectl --namespace "$NAMESPACE" get endpointslice -l kubernetes.io/service-name=incident-api -o yaml >"$output_dir/endpointslices.yaml"
kubectl --namespace "$NAMESPACE" get events --sort-by=.metadata.creationTimestamp \
  >"$output_dir/events.txt" 2>&1
kubectl --namespace "$NAMESPACE" logs -l app.kubernetes.io/name=incident-api \
  --all-containers --prefix --tail=200 >"$output_dir/application.log" 2>&1 || true

if kubectl --namespace monitoring get service monitoring-kube-prometheus-prometheus \
  >/dev/null 2>&1; then
  kubectl --namespace monitoring get pods -o wide \
    >"$output_dir/monitoring-workloads.txt" 2>&1
  kubectl --namespace "$NAMESPACE" get servicemonitor,prometheusrule -o yaml \
    >"$output_dir/monitoring-config.yaml" 2>&1
fi

if kubectl --namespace argocd get application incident-lab >/dev/null 2>&1; then
  kubectl --namespace argocd get pods -o wide \
    >"$output_dir/argocd-workloads.txt" 2>&1
  kubectl --namespace argocd get application incident-lab -o yaml \
    >"$output_dir/argocd-application.yaml" 2>&1
  kubectl --namespace argocd logs statefulset/argocd-application-controller \
    --since=10m >"$output_dir/argocd-controller.log" 2>&1 || true
fi

cp "$ROOT_DIR/evidence/TEMPLATE.md" "$output_dir/incident-report.md"

printf 'Evidence captured in %s\n' "$output_dir"
