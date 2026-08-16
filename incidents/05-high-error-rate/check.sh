#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REQUESTS=80 "$ROOT_DIR/scripts/load-test.sh"
echo 'PASS: business failures are present despite healthy Kubernetes readiness.'
