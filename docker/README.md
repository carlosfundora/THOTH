# THOTH Docker Environment

ROCm 7.2 dev container for TurboQuant KV cache + speculative decoding research on RX 6700 XT (gfx1031).

## Quick Start

```bash
# Build the image (compiles llama-turboquant with HIP)
./build.sh

# Start the container with the Hephaestion guard
./up.sh

# Attach to interactive shell
docker compose exec thoth bash
```

## Inside the Container

```bash
# Verify GPU is detected
rocm-smi

# Test TurboQuant build
llama-cli --model /workspace/models/<your-model>.gguf \
  --n-gpu-layers 99 \
  --kv-cache-dtype turbo4 \
  -p "test"

# Start llama-server
llama-server --model /workspace/models/<your-model>.gguf \
  --n-gpu-layers 99 \
  --kv-cache-dtype turbo4 \
  --host 0.0.0.0 --port 8080
```

## Volume Mounts

| Container Path | Host Path | Purpose |
|---|---|---|
| `/workspace/forks` | `Projects/forks` | External fork repos (accelerate, deepspeed, etc.) |
| `/workspace/models` | `Projects/models` | Model weights (GGUF, safetensors) |
| `/workspace/build` | `Projects/build` | Build artifacts, SDK tools |
| `/workspace/thoth` | `Projects/THOTH` | THOTH project (live-mounted) |

## Environment Variables

See `.env` for defaults. Key variables:
- `HSA_OVERRIDE_GFX_VERSION=10.3.0` — Required for gfx1031
- `GPU_TARGETS=gfx1030` — CMake target arch
- `HIP_VISIBLE_DEVICES=0` — GPU selection
- `THOTH_CPUS=18` — Host-enforced CPU cap for the runtime container during THOTH development and parity training checks
- `THOTH_BUILD_JOBS=8` — Max parallel build jobs during image rebuilds
- `HEPHAESTION_*` — Circuit-breaker thresholds for CPU, GPU, NVMe, and disk

## Ports

| Port | Service |
|---|---|
| 8080 | llama-server |
| 8000 | vLLM (optional) |

## Safety

The Docker workflow now has two safety layers:

```bash
# Disk preflight only
./preflight.sh /

# One-shot guard sample
./hephaestion-guard.sh --once
```

`./up.sh` starts `docker compose up -d` and launches the background guard. If the host crosses the configured thermal or disk limits, the guard logs the reason to `THOTH/logs/hephaestion`, stops the `thoth` container, and exits nonzero.
