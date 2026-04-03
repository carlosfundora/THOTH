# SGLang — Engine Notes

**Status:** In progress, source port active
**Fork:** `THOTH/forks/sglang` (carlosfundora/sglang)
**Base runtime:** ROCm/gfx1030 compatibility via `HSA_OVERRIDE_GFX_VERSION=10.3.0`
**Upstream TurboQuant donor:** `sgl-project/sglang#21628`

---

## Current State

The local SGLang fork is no longer a placeholder. The ROCm path now includes:

1. The AMD TurboQuant KV cache patch set from PR `#21628`
2. A local `sgl-kernel` ROCm build path for `gfx1030`, with `gfx1031`/`gfx1035` normalized onto the same compatibility target
3. HIP GGUF compatibility fallback paths for ROCm so quantized GGUF models can load without CUDA-only kernels
4. PrismML 1-bit GGUF compatibility shims for Bonsai `Q1_0` / `Q1_0_G128`
5. Optional-backend import fencing so the SGLang server can boot on this ROCm system without pulling unrelated CUDA-oriented stacks

This means SGLang is now a live ROCm target in THOTH, not just a future plan.

## What Has Been Validated

### ROCm / TurboQuant

- `sgl-kernel/setup_rocm.py` was patched so the ROCm extension builds for `gfx1030`
- The extension builds successfully inside the THOTH Docker container
- `python -m sglang.launch_server --help` now works in the container and exposes:
  - `--kv-cache-dtype tq4|tq3|tq2`
  - `--speculative-algorithm EAGLE|EAGLE3|STANDALONE|NGRAM`
  - `--speculative-draft-model-path`

### GGUF / 1-bit compatibility

- PrismML Bonsai GGUF files no longer fail on the old unsupported enum path
- Raw GGUF loading succeeds for Prism `Q1_0`/`Q1_0_G128`
- HIP fallback matmul/dequant paths run through `gguf.quants` instead of CUDA-only kernels

### OpenCoder EAGLE/TurboQuant bring-up

- SGLang now reaches real `EAGLE3` scheduler/model-load paths with:
  - target: `OpenCoder-8B-Instruct`
  - draft: `OpenCoder-1.5B-Instruct`
  - `--kv-cache-dtype tq4`
- The first blocking failure was not the SGLang port. It was a corrupt local shard in the OpenCoder 8B checkout:
  - `model-00002-of-00004.safetensors`
- That corrupt shard was backed up and re-fetched from Git LFS before rerunning the load.
- A second controlled proof now exists with a local draft build:
  - target: `OpenCoder-1.5B-Instruct`
  - draft: `OpenCoder-1.5B-EAGLE3-local`
  - algorithm: true `EAGLE3`
  - result: `/generate` succeeded and returned speculative metrics
- A fresh Docker validation on `2026-04-03` proves the reduced runtime path:
  - target: `OpenCoder-1.5B-Instruct`
  - draft: local `OpenCoder-1.5B-EAGLE3`
  - `--kv-cache-dtype tq4`
  - attention backend: `triton`
  - radix enabled
  - result: `POST /generate` returned `200 OK`

### Docker safety and backend recovery

- THOTH Docker now has a host-side guard and disk preflight under `THOTH/docker`
- The `thoth` runtime container is capped to `12` CPUs and `60G` RAM
- The SGLang ROCm policy was corrected so HIP no longer auto-selects `aiter` unless `aiter` is both installed and explicitly enabled through `SGLANG_USE_AITER`
- On this machine, `aiter` is not installed in the container, so the recovered default backend is now `triton`

## Runtime Matrix

Validated inside the `thoth` container:

- Container image: `thoth:latest`
- Python: `3.12.3`
- PyTorch: `2.11.0+rocm7.2`
- Torch HIP runtime: `7.2.26015`
- Triton: `3.6.0`
- SGLang: `0.5.10rc0`
- `sgl_kernel`: `0.4.0`
- Transformers: `5.4.0`
- FastAPI: `0.135.3`
- Uvicorn: `0.42.0`
- GPU marketed as `AMD Radeon RX 6700 XT`
- ROCm agent target exposed in-container: `gfx1030`
- Physical card reported by `rocm-smi`: `gfx1031`
- `aiter`: not installed in the container runtime

## Validated Docker Paths

Current validated runtime paths:

- `OpenCoder-1.5B-Instruct + local EAGLE3 + tq4 + Triton + radix`
  - proven in Docker on `2026-04-03`
  - request returned `200 OK`
  - fresh canary on the current branch also returned `200 OK`
  - short deterministic canary produced:
    - text: `def hello_world(): print("Hello, world!")`
    - `completion_tokens=16`
    - `e2e_latency=10.14s`
    - `spec_draft_token_num=105`
  - peak sampled resources:
    - latest canary container memory: `9.85 GiB`
    - latest canary GPU junction: `50 C`
    - latest canary VRAM allocation: `92%`
  - report: [`opencoder15-eagle3-tq4-docker-2026-04-03.md`](/home/local/Projects/THOTH/reports/sglang/opencoder15-eagle3-tq4-docker-2026-04-03.md)

- `Bonsai-1.7B GGUF + local EAGLE3 + Triton + radix`
  - proven in Docker on `2026-04-03`
  - request returned `200 OK`
  - report: [`validation-results.md`](./validation-results.md)

- `Bonsai-1.7B GGUF + local EAGLE3 + tq4 + Triton + radix`
  - now proven end-to-end in Docker on `2026-04-03`
  - request returned `200 OK`
  - short deterministic run produced:
    - text: `Alex, and I'm a student at the University of California, Berkeley...`
    - `completion_tokens=24`
    - `e2e_latency=158.24s`
    - `spec_draft_token_num=69`
  - peak sampled resources:
    - container memory: `8.52 GiB`
    - GPU junction: `50 C`
    - VRAM allocation: `97%`
  - report: [`bonsai17-eagle3-tq4-docker-2026-04-03.md`](/home/local/Projects/THOTH/reports/sglang/bonsai17-eagle3-tq4-docker-2026-04-03.md)

## Important Constraint: Real EAGLE Requires a Real EAGLE Draft

SGLang supports true `EAGLE` / `EAGLE3`, and THOTH now has a local OpenCoder 1.5B proof draft under `Projects/models/registry/local`.

The plain `OpenCoder-1.5B-Instruct` checkpoint is useful for:

- size/VRAM bring-up
- tokenizer/runtime compatibility checks
- comparative standalone speculation

It is not automatically the same thing as a trained `EAGLE3` draft artifact. The runtime path can now be exercised locally, but a production-correct OpenCoder EAGLE deployment still requires the training layer to produce or adapt a proper draft checkpoint.

## Container Recipe

All active SGLang validation is happening in the THOTH Docker container, not on the host Python stack:

```bash
docker exec thoth bash -lc '
  cd /workspace/thoth/forks/sglang &&
  source .venv-sglang/bin/activate &&
  export HSA_OVERRIDE_GFX_VERSION=10.3.0 &&
  export PYTORCH_ROCM_ARCH=gfx1030 &&
  export PYTHONPATH=/workspace/thoth/forks/sglang/python:/workspace/thoth/forks/sglang/sgl-kernel/python &&
  python -m sglang.launch_server --help
'
```

## Immediate Next Steps

1. Keep `OpenCoder-1.5B + local EAGLE3 + tq4` as the regression canary for the synced branch
2. Keep `Bonsai-1.7B + local EAGLE3 + tq4` as the 1-bit speculative regression canary
3. Cleanly sync the validated branch state and donor-backed runtime fixes
4. Next runtime target: evaluate simultaneous `EAGLE3` behavior on both the draft model and the generation model without regressing the validated Docker paths

## Notes

- SGLang remains the attack-order position after `llama-turboquant` and `turboquant_plus`
- `llama-turboquant` proved HIP + TurboQuant + Bonsai Q1 on this hardware, but true EAGLE belongs in SGLang, not llama.cpp
- AMD does support radix. The current validated branch proves radix + Triton + `tq4` together on both the OpenCoder path and the Bonsai 1-bit path.
