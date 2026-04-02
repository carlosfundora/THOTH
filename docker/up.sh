#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THOTH_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$THOTH_ROOT/logs/hephaestion"
mkdir -p "$LOG_DIR"

"$SCRIPT_DIR/preflight.sh" /

cd "$SCRIPT_DIR"
docker compose up -d --force-recreate "$@"

guard_log="$LOG_DIR/$(date +%Y%m%dT%H%M%S)_hephaestion_guard.log"
nohup "$SCRIPT_DIR/hephaestion-guard.sh" --container thoth --log-file "$guard_log" >/dev/null 2>&1 &

echo "hephaestion guard started: $guard_log"
