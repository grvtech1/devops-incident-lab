#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NAMESPACE="${NAMESPACE:-incident-lab}"
EXPECTED_CONTEXT="${EXPECTED_CONTEXT:-kind-incident-lab}"

assert_lab_cluster() {
  local current_context
  current_context="$(kubectl config current-context 2>/dev/null || true)"
  if [[ "$current_context" != "$EXPECTED_CONTEXT" ]]; then
    printf 'Refusing to modify context %q. Expected %q.\n' "$current_context" "$EXPECTED_CONTEXT" >&2
    printf 'Switch to the lab cluster or explicitly set EXPECTED_CONTEXT.\n' >&2
    exit 1
  fi

  if ! kubectl --request-timeout=5s get --raw='/readyz' >/dev/null 2>&1; then
    echo 'Kubernetes API is unreachable or not Ready; refusing to continue.' >&2
    exit 1
  fi

  kubectl --request-timeout=5s get namespace "$NAMESPACE" >/dev/null 2>&1 || {
    printf 'Namespace %q does not exist. Run make bootstrap first.\n' "$NAMESPACE" >&2
    exit 1
  }
}

show_workload_state() {
  echo '--- deployment ---'
  kubectl --namespace "$NAMESPACE" get deployment incident-api -o wide
  echo '--- pods ---'
  kubectl --namespace "$NAMESPACE" get pods -l app.kubernetes.io/name=incident-api -o wide
  echo '--- service endpoints ---'
  printf 'ADDRESS\tREADY\tSERVING\tTERMINATING\tNODE\n'
  kubectl --namespace "$NAMESPACE" get endpointslice \
    -l kubernetes.io/service-name=incident-api \
    -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"\t"}{.conditions.ready}{"\t"}{.conditions.serving}{"\t"}{.conditions.terminating}{"\t"}{.nodeName}{"\n"}{end}'
  echo '--- recent events ---'
  kubectl --namespace "$NAMESPACE" get events --sort-by=.metadata.creationTimestamp | tail -n 15
}

restore_baseline() {
  kubectl apply --kustomize "$ROOT_DIR/k8s/overlays/dev"
  kubectl --namespace "$NAMESPACE" set env deployment/incident-api \
    ALLOCATE_ON_START_MB- FAILURE_RATE- >/dev/null
  kubectl --namespace "$NAMESPACE" patch deployment incident-api --type=json \
    -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/health/ready"}]' \
    >/dev/null
  kubectl --namespace "$NAMESPACE" patch service incident-api --type=merge \
    -p='{"spec":{"selector":{"app.kubernetes.io/name":"incident-api"}}}' >/dev/null
  kubectl --namespace "$NAMESPACE" patch configmap incident-lab-config --type=merge \
    -p='{"data":{"BACKEND_URL":"http://dependency.incident-lab.svc.cluster.local:8080","FAILURE_RATE":"0"}}' >/dev/null
  kubectl --namespace "$NAMESPACE" rollout restart deployment/incident-api >/dev/null
  kubectl --namespace "$NAMESPACE" rollout status deployment/incident-api --timeout=120s
}
