#!/usr/bin/env bash
set -Eeuo pipefail

required=(docker kind kubectl curl)
missing=()

for command_name in "${required[@]}"; do
  if ! command -v "$command_name" >/dev/null 2>&1; then
    missing+=("$command_name")
  fi
done

if ((${#missing[@]} > 0)); then
  printf 'Missing required tools: %s\n' "${missing[*]}" >&2
  printf 'Run this lab from WSL2 after installing Docker, kind, kubectl, and curl.\n' >&2
  exit 1
fi

docker info >/dev/null 2>&1 || {
  echo 'Docker is installed but its daemon is not reachable.' >&2
  exit 1
}

echo 'Preflight passed.'
docker --version
kind --version
kubectl version --client
