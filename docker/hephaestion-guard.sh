#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THOTH_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LOG_DIR="$THOTH_ROOT/logs/hephaestion"
mkdir -p "$LOG_DIR"

CONTAINER_NAME="${HEPHAESTION_CONTAINER_NAME:-thoth}"
POLL_INTERVAL="${HEPHAESTION_POLL_INTERVAL:-5}"
CPU_WARN_C="${HEPHAESTION_CPU_WARN_C:-80}"
CPU_TRIP_C="${HEPHAESTION_CPU_TRIP_C:-85}"
CPU_TRIP_SUSTAIN_S="${HEPHAESTION_CPU_TRIP_SUSTAIN_S:-15}"
GPU_EDGE_TRIP_C="${HEPHAESTION_GPU_EDGE_TRIP_C:-90}"
GPU_JUNCTION_TRIP_C="${HEPHAESTION_GPU_JUNCTION_TRIP_C:-100}"
NVME_TRIP_C="${HEPHAESTION_NVME_TRIP_C:-80}"
DISK_MIN_FREE_GB="${HEPHAESTION_DISK_MIN_FREE_GB:-40}"
DISK_MAX_USED_PCT="${HEPHAESTION_DISK_MAX_USED_PCT:-92}"
DISK_PATH="${HEPHAESTION_DISK_PATH:-/}"
LOG_FILE="${HEPHAESTION_GUARD_LOG:-$LOG_DIR/$(date +%Y%m%dT%H%M%S)_hephaestion_guard.log}"
PID_FILE="${HEPHAESTION_GUARD_PIDFILE:-${LOG_FILE%.log}.pid}"
COMMAND_PID=""
ONESHOT=0
IGNORE_MISSING_CONTAINER=0

while (($#)); do
    case "$1" in
        --container)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --command-pid)
            COMMAND_PID="$2"
            shift 2
            ;;
        --log-file)
            LOG_FILE="$2"
            shift 2
            ;;
        --once)
            ONESHOT=1
            shift
            ;;
        --ignore-missing-container)
            IGNORE_MISSING_CONTAINER=1
            shift
            ;;
        *)
            echo "unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

echo "$$" >"$PID_FILE"

cleanup() {
    rm -f "$PID_FILE"
}
trap cleanup EXIT

sample_cpu_tctl() {
    if [[ -n "${HEPHAESTION_TEST_CPU_TEMP:-}" ]]; then
        printf '%s\n' "$HEPHAESTION_TEST_CPU_TEMP"
        return
    fi
    sensors 2>/dev/null | awk '
        /^k10temp-pci-/ { in_k10=1; next }
        in_k10 && /^Tctl:/ {
            val=$2
            gsub(/\+|°C/, "", val)
            print val
            exit
        }
    '
}

sample_gpu_temps() {
    if [[ -n "${HEPHAESTION_TEST_GPU_EDGE_TEMP:-}" || -n "${HEPHAESTION_TEST_GPU_JUNCTION_TEMP:-}" ]]; then
        printf '%s %s\n' "${HEPHAESTION_TEST_GPU_EDGE_TEMP:-0}" "${HEPHAESTION_TEST_GPU_JUNCTION_TEMP:-0}"
        return
    fi
    python3 - <<'PY'
import json, subprocess, sys
try:
    proc = subprocess.run(
        ["rocm-smi", "--showtemp", "--json"],
        check=True,
        text=True,
        capture_output=True,
    )
    payload = json.loads(proc.stdout)
except Exception:
    print("0 0")
    sys.exit(0)

edge = 0.0
junction = 0.0
for card in payload.values():
    edge = max(edge, float(card.get("Temperature (Sensor edge) (C)", "0") or 0))
    junction = max(junction, float(card.get("Temperature (Sensor junction) (C)", "0") or 0))
print(f"{edge:.1f} {junction:.1f}")
PY
}

sample_nvme_temp() {
    if [[ -n "${HEPHAESTION_TEST_NVME_TEMP:-}" ]]; then
        printf '%s\n' "$HEPHAESTION_TEST_NVME_TEMP"
        return
    fi
    sensors 2>/dev/null | awk '
        /^nvme-pci-/ { in_nvme=1; next }
        in_nvme && /^Composite:/ {
            val=$2
            gsub(/\+|°C/, "", val)
            if (val > max) max = val
            in_nvme = 0
        }
        END {
            if (max == "") max = 0
            print max
        }
    '
}

sample_disk() {
    if [[ -n "${HEPHAESTION_TEST_DISK_FREE_GB:-}" || -n "${HEPHAESTION_TEST_DISK_USED_PCT:-}" ]]; then
        printf '%s %s\n' "${HEPHAESTION_TEST_DISK_FREE_GB:-999}" "${HEPHAESTION_TEST_DISK_USED_PCT:-0}"
        return
    fi
    read -r used_pct avail_kb < <(df -Pk "$DISK_PATH" | awk 'NR==2 {print $5, $4}')
    used_pct="${used_pct%\%}"
    avail_gb=$((avail_kb / 1024 / 1024))
    printf '%s %s\n' "$avail_gb" "$used_pct"
}

stop_targets() {
    local reason="$1"
    echo "action=trip reason=\"$reason\" stopping_container=$CONTAINER_NAME command_pid=${COMMAND_PID:-none}" | tee -a "$LOG_FILE" >&2
    if docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
        docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
        for _ in $(seq 1 12); do
            if ! docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
                break
            fi
            sleep 1
        done
    fi
    if [[ -n "$COMMAND_PID" ]] && kill -0 "$COMMAND_PID" 2>/dev/null; then
        kill "$COMMAND_PID" >/dev/null 2>&1 || true
    fi
}

cpu_trip_started=0

while true; do
    timestamp="$(date --iso-8601=seconds)"
    cpu_temp="$(sample_cpu_tctl)"
    cpu_temp="${cpu_temp:-0}"
    read -r gpu_edge gpu_junction < <(sample_gpu_temps)
    nvme_temp="$(sample_nvme_temp)"
    nvme_temp="${nvme_temp:-0}"
    read -r disk_free_gb disk_used_pct < <(sample_disk)

    state="ok"
    reason=""

    if awk "BEGIN { exit !($cpu_temp >= $CPU_WARN_C) }"; then
        state="warn"
        reason="cpu_warn"
    fi

    if awk "BEGIN { exit !($cpu_temp >= $CPU_TRIP_C) }"; then
        if (( cpu_trip_started == 0 )); then
            cpu_trip_started="$(date +%s)"
        fi
        if (( $(date +%s) - cpu_trip_started >= CPU_TRIP_SUSTAIN_S )); then
            state="trip"
            reason="cpu_tctl_${cpu_temp}C_for_${CPU_TRIP_SUSTAIN_S}s"
        fi
    else
        cpu_trip_started=0
    fi

    if [[ "$state" != "trip" ]] && awk "BEGIN { exit !($gpu_edge >= $GPU_EDGE_TRIP_C) }"; then
        state="trip"
        reason="gpu_edge_${gpu_edge}C"
    fi
    if [[ "$state" != "trip" ]] && awk "BEGIN { exit !($gpu_junction >= $GPU_JUNCTION_TRIP_C) }"; then
        state="trip"
        reason="gpu_junction_${gpu_junction}C"
    fi
    if [[ "$state" != "trip" ]] && awk "BEGIN { exit !($nvme_temp >= $NVME_TRIP_C) }"; then
        state="trip"
        reason="nvme_${nvme_temp}C"
    fi
    if [[ "$state" != "trip" ]] && (( disk_free_gb < DISK_MIN_FREE_GB )); then
        state="trip"
        reason="disk_free_${disk_free_gb}GB"
    fi
    if [[ "$state" != "trip" ]] && (( disk_used_pct > DISK_MAX_USED_PCT )); then
        state="trip"
        reason="disk_used_${disk_used_pct}pct"
    fi

    if [[ "$IGNORE_MISSING_CONTAINER" -eq 0 ]] && [[ -z "$COMMAND_PID" ]]; then
        if ! docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER_NAME"; then
            echo "timestamp=$timestamp state=stopped reason=container_missing container=$CONTAINER_NAME" | tee -a "$LOG_FILE"
            exit 0
        fi
    fi

    echo "timestamp=$timestamp state=$state cpu_tctl_c=$cpu_temp gpu_edge_c=$gpu_edge gpu_junction_c=$gpu_junction nvme_c=$nvme_temp disk_free_gb=$disk_free_gb disk_used_pct=$disk_used_pct reason=${reason:-none}" | tee -a "$LOG_FILE"

    if [[ "$state" == "trip" ]]; then
        stop_targets "$reason"
        exit 1
    fi

    if [[ "$ONESHOT" -eq 1 ]]; then
        exit 0
    fi

    sleep "$POLL_INTERVAL"
done
