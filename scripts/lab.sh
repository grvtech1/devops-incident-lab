#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/lib.sh"

usage() {
  cat <<'EOF'
Usage:
  ./scripts/lab.sh list
  ./scripts/lab.sh start <incident-number>
  ./scripts/lab.sh check <incident-number>
  ./scripts/lab.sh recover <incident-number>
  ./scripts/lab.sh solution <incident-number>
  ./scripts/lab.sh status
  ./scripts/lab.sh reset
EOF
}

find_incident() {
  local number="$1"
  local matches
  shopt -s nullglob
  matches=("$ROOT_DIR"/incidents/"$number"-*)
  shopt -u nullglob
  if ((${#matches[@]} != 1)); then
    printf 'Expected one incident matching %q; found %d.\n' "$number-*" "${#matches[@]}" >&2
    exit 1
  fi
  printf '%s\n' "${matches[0]}"
}

command_name="${1:-}"
case "$command_name" in
  list)
    printf '%-4s %-38s %s\n' 'ID' 'INCIDENT' 'PRIMARY SIGNAL'
    printf '%-4s %-38s %s\n' '--' '--------' '--------------'
    for directory in "$ROOT_DIR"/incidents/[0-9][0-9]-*; do
      id="$(basename "$directory" | cut -d- -f1)"
      title="$(sed -n '1s/^# //p' "$directory/README.md")"
      signal="$(sed -n 's/^Primary signal: //p' "$directory/README.md")"
      printf '%-4s %-38s %s\n' "$id" "$title" "$signal"
    done
    ;;
  start|check|recover)
    [[ -n "${2:-}" ]] || { usage; exit 1; }
    assert_lab_cluster
    incident_dir="$(find_incident "$2")"
    bash "$incident_dir/$command_name.sh"
    ;;
  solution)
    [[ -n "${2:-}" ]] || { usage; exit 1; }
    incident_dir="$(find_incident "$2")"
    cat "$incident_dir/SOLUTION.md"
    ;;
  status)
    assert_lab_cluster
    show_workload_state
    ;;
  reset)
    assert_lab_cluster
    restore_baseline
    ;;
  *)
    usage
    exit 1
    ;;
esac
