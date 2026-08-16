#!/usr/bin/env bash
set -Eeuo pipefail
node_container="${LAB_WORKER_NODE:-incident-lab-worker}"
docker inspect "$node_container" >/dev/null
docker pause "$node_container"
echo "Paused $node_container. Node readiness may take about a minute to change."
