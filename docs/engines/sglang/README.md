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

## Important Constraint: Real EAGLE Requires a Real EAGLE Draft

SGLang supports true `EAGLE` / `EAGLE3`, but this machine does not currently have a trained OpenCoder EAGLE draft checkpoint under `Projects/models`.

The plain `OpenCoder-1.5B-Instruct` checkpoint is useful for:

- size/VRAM bring-up
- tokenizer/runtime compatibility checks
- comparative standalone speculation

It is not automatically the same thing as a trained `EAGLE3` draft artifact. The runtime path can be exercised, but a production-correct OpenCoder EAGLE deployment still requires the training layer to produce or adapt a proper draft checkpoint.

## Container Recipe

All active SGLang validation is happening in the THOTH Docker container, not on the host Python stack:

```bash
docker exec thoth bash -lc '
  cd /workspace/thoth/forks/sglang &&
  source .venv-hephaestion/bin/activate &&
  export HSA_OVERRIDE_GFX_VERSION=10.3.0 &&
  export PYTORCH_ROCM_ARCH=gfx1030 &&
  export PYTHONPATH=/workspace/thoth/forks/sglang/python:/workspace/thoth/forks/sglang/sgl-kernel/python &&
  python -m sglang.launch_server --help
'
```

## Immediate Next Steps

1. Finish the repaired OpenCoder `EAGLE3 + tq4` load and capture the next real blocker or a successful serve
2. Re-run Bonsai 1-bit serve with the GPU freed so the GGUF server path is validated end-to-end, not just at reader/kernel level
3. Move from runtime bring-up to training once the runtime behavior is stable enough to justify a true OpenCoder EAGLE draft artifact

## Notes

- SGLang remains the attack-order position after `llama-turboquant` and `turboquant_plus`
- `llama-turboquant` proved HIP + TurboQuant + Bonsai Q1 on this hardware, but true EAGLE belongs in SGLang, not llama.cpp
