#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CLUSTER_NAME="${CLUSTER_NAME:-incident-lab}"

bash "$ROOT_DIR/scripts/preflight.sh"

if ! kind get clusters | grep -Fxq "$CLUSTER_NAME"; then
  kind create cluster --name "$CLUSTER_NAME" --config "$ROOT_DIR/cluster/kind-config.yaml"
else
  echo "Cluster $CLUSTER_NAME already exists."
fi

bash "$ROOT_DIR/scripts/deploy.sh"
