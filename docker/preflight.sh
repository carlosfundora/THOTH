#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THOTH_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DISK_MIN_FREE_GB="${HEPHAESTION_DISK_MIN_FREE_GB:-40}"
DISK_MAX_USED_PCT="${HEPHAESTION_DISK_MAX_USED_PCT:-92}"
TARGET_PATH="${1:-/}"

mkdir -p "$THOTH_ROOT/logs/hephaestion"
LOG_FILE="${HEPHAESTION_PREFLIGHT_LOG:-$THOTH_ROOT/logs/hephaestion/$(date +%Y%m%dT%H%M%S)_docker_preflight.log}"

read -r _ _ _ used_pct _ avail_kb _ < <(df -Pk "$TARGET_PATH" | awk 'NR==2 {print $1, $2, $3, $5, $6, $4, $7}')
used_pct="${used_pct%\%}"
avail_gb=$((avail_kb / 1024 / 1024))

{
    echo "timestamp=$(date --iso-8601=seconds)"
    echo "target_path=$TARGET_PATH"
    echo "disk_used_pct=$used_pct"
    echo "disk_free_gb=$avail_gb"
    echo "disk_min_free_gb=$DISK_MIN_FREE_GB"
    echo "disk_max_used_pct=$DISK_MAX_USED_PCT"
} >>"$LOG_FILE"

if (( avail_gb < DISK_MIN_FREE_GB )); then
    echo "hephaestion preflight failed: free disk ${avail_gb}GB is below floor ${DISK_MIN_FREE_GB}GB" | tee -a "$LOG_FILE" >&2
    exit 1
fi

if (( used_pct > DISK_MAX_USED_PCT )); then
    echo "hephaestion preflight failed: disk usage ${used_pct}% exceeds limit ${DISK_MAX_USED_PCT}%" | tee -a "$LOG_FILE" >&2
    exit 1
fi

echo "hephaestion preflight ok: ${avail_gb}GB free, ${used_pct}% used on ${TARGET_PATH}" | tee -a "$LOG_FILE"
