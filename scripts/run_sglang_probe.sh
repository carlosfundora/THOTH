#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 5 ]; then
  echo "usage: $0 <name> <port> <model_path> <draft_path> <prompt> [extra launch args...]" >&2
  exit 2
fi

ROOT="/home/local/Projects/THOTH"
NAME="$1"
PORT="$2"
MODEL_PATH="$3"
DRAFT_PATH="$4"
PROMPT="$5"
shift 5
EXTRA_ARGS=("$@")
MAX_NEW_TOKENS="${PROBE_MAX_NEW_TOKENS:-64}"
REQUEST_TIMEOUT="${PROBE_REQUEST_TIMEOUT:-240}"

TS="$(date +%Y%m%dT%H%M%S)"
LOG_PATH="${ROOT}/logs/${TS}_${NAME}.log"
RESP_PATH="${ROOT}/logs/${TS}_${NAME}_response.json"
RES_PATH="${ROOT}/logs/${TS}_${NAME}_resources.jsonl"

echo "ts=${TS}"
echo "log=${LOG_PATH}"
echo "response=${RESP_PATH}"
echo "resources=${RES_PATH}"

docker exec -u 0 thoth bash -lc \
  "pkill -f 'sglang.launch_server|python3 -u -m sglang.launch_server|curl -sS -X POST http://127.0.0.1:${PORT}' || true" \
  >/dev/null 2>&1 || true

cleanup() {
  if [ -n "${MONPID:-}" ]; then
    kill "${MONPID}" >/dev/null 2>&1 || true
  fi
  if [ -n "${SRVPID:-}" ]; then
    pkill -P "${SRVPID}" >/dev/null 2>&1 || true
    wait "${SRVPID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

(
  while true; do
    python3 - <<'PY'
import json
import subprocess
from datetime import UTC, datetime

sample = {"ts": datetime.now(UTC).isoformat().replace("+00:00", "Z")}
for cmd, key in [
    (["rocm-smi", "--showtemp", "--showuse", "--showmemuse", "--json"], "rocm"),
    (["docker", "stats", "thoth", "--no-stream", "--format", "{{json .}}"], "docker"),
]:
    try:
        out = subprocess.check_output(cmd, text=True, stderr=subprocess.DEVNULL).strip()
        sample[key] = json.loads(out) if out.startswith("{") else out
    except Exception as exc:
        sample[key] = {"error": str(exc)}
print(json.dumps(sample), flush=True)
PY
    sleep 5
  done
) >"${RES_PATH}" &
MONPID=$!

docker exec thoth bash -lc '
  cd /workspace/thoth/forks/sglang
  export PYTHONPATH=/workspace/thoth/forks/sglang/python:/workspace/thoth/forks/sglang/sgl-kernel/python
  export HSA_OVERRIDE_GFX_VERSION=10.3.0
  export PYTORCH_ROCM_ARCH=gfx1030
  export SGLANG_EAGLE_SKIP_TARGET_EMBED_SHARE=1
  if [ -n "${SGLANG_ROCM_DEBUG_KV:-}" ]; then
    export SGLANG_ROCM_DEBUG_KV
  fi
  export PYTHONUNBUFFERED=1
  exec "$@"
' bash \
  /workspace/thoth/forks/sglang/.venv-sglang/bin/python3 \
  -u \
  -m \
  sglang.launch_server \
  --model-path "${MODEL_PATH}" \
  --trust-remote-code \
  --host 127.0.0.1 \
  --port "${PORT}" \
  --attention-backend triton \
  --speculative-algorithm EAGLE3 \
  --speculative-draft-model-path "${DRAFT_PATH}" \
  --speculative-draft-load-format safetensors \
  --speculative-num-steps 3 \
  --speculative-num-draft-tokens 4 \
  --speculative-eagle-topk 1 \
  --disable-cuda-graph \
  --disable-piecewise-cuda-graph \
  --disable-cuda-graph-padding \
  --disable-flashinfer-autotune \
  --disable-overlap-schedule \
  --skip-server-warmup \
  --disable-custom-all-reduce \
  --mem-fraction-static 0.35 \
  --max-running-requests 1 \
  --schedule-policy fcfs \
  "${EXTRA_ARGS[@]}" >"${LOG_PATH}" 2>&1 &
SRVPID=$!

READY=0
for _ in $(seq 1 90); do
  if docker exec thoth bash -lc "curl -fsS http://127.0.0.1:${PORT}/model_info >/dev/null" >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 2
done

if [ "${READY}" -eq 1 ]; then
  docker exec \
    -e PROBE_PROMPT="${PROMPT}" \
    -e PROBE_MAX_NEW_TOKENS="${MAX_NEW_TOKENS}" \
    -e PROBE_REQUEST_TIMEOUT="${REQUEST_TIMEOUT}" \
    thoth \
    bash -lc "
      python3 - <<'PY'
import json
import os
import urllib.request

payload = {
    'text': os.environ['PROBE_PROMPT'],
    'sampling_params': {
        'temperature': 0.0,
        'max_new_tokens': int(os.environ['PROBE_MAX_NEW_TOKENS']),
    },
}
req = urllib.request.Request(
    'http://127.0.0.1:${PORT}/generate',
    data=json.dumps(payload).encode('utf-8'),
    headers={'Content-Type': 'application/json'},
)
timeout = int(os.environ['PROBE_REQUEST_TIMEOUT'])
with urllib.request.urlopen(req, timeout=timeout) as resp:
    print(resp.read().decode('utf-8'))
PY
    " >"${RESP_PATH}"
fi

sleep 10

ls -l "${LOG_PATH}" "${RESP_PATH}" "${RES_PATH}" 2>/dev/null || true
echo "---RESP---"
cat "${RESP_PATH}" 2>/dev/null || true
echo
echo "---LOGTAIL---"
tail -n 120 "${LOG_PATH}" || true
