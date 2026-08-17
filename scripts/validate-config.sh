#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TF_DIR="$ROOT_DIR/infra/terraform/aws"

required_tools=(ansible-playbook helm kubectl terraform)
missing=()
for tool in "${required_tools[@]}"; do
  command -v "$tool" >/dev/null 2>&1 || missing+=("$tool")
done
if ((${#missing[@]} > 0)); then
  printf 'Missing validation tools: %s\n' "${missing[*]}" >&2
  exit 1
fi

while IFS= read -r script; do
  bash -n "$script"
done < <(find "$ROOT_DIR/scripts" -maxdepth 1 -type f -name '*.sh' -print | sort)

kubectl kustomize "$ROOT_DIR/k8s/overlays/dev" >/tmp/incident-lab-dev.yaml
kubectl kustomize "$ROOT_DIR/k8s/overlays/production" >/tmp/incident-lab-production.yaml

helm template monitoring \
  oci://ghcr.io/prometheus-community/charts/kube-prometheus-stack \
  --version 87.21.0 \
  --namespace monitoring \
  --values "$ROOT_DIR/monitoring/kube-prometheus-values.yaml" \
  --include-crds >/tmp/incident-lab-monitoring.yaml

terraform -chdir="$TF_DIR" fmt -check -recursive
terraform -chdir="$TF_DIR" init -backend=false -input=false
terraform -chdir="$TF_DIR" validate

ANSIBLE_CONFIG="$ROOT_DIR/infra/ansible/ansible.cfg" \
  ansible-playbook \
    --inventory "$ROOT_DIR/infra/ansible/inventory.ini.example" \
    --syntax-check "$ROOT_DIR/infra/ansible/site.yml"

echo 'Delivery and infrastructure configuration validation passed.'
