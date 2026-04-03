# Draft-Model Speculative Decoding — Test Results (Run 002)

**Date:** 2026-04-01
**Hardware:** RX 6700 XT (`gfx1031` treated as `gfx1030`)
**Container:** `thoth`
**Binary:** `llama-turboquant` rebuilt from live THOTH source (`b8522-408510d13`)

---

## Summary
This run rebuilt `forks/llama-turboquant` inside Docker and validated three runtime goals on the fresh HIP binary:

1. Bonsai 1-bit GGUF loads and generates on GPU
2. OpenCoder-8B + OpenCoder-1.5B draft-model speculative decoding works on GPU
3. The same OpenCoder pair also works with quantized `tq3_0` V-cache in speculative mode when Flash Attention is explicitly enabled

This is still **draft-model speculation**, not a first-class `EAGLE3` runtime mode.

Important correction:

- this file retains its historical filename for link stability
- the actual tested path was ordinary llama draft-model speculation via
  `--model-draft`
- no true llama-side EAGLE implementation was proven here

---

## Build Command

```bash
cd /workspace/thoth/forks/llama-turboquant

HSA_OVERRIDE_GFX_VERSION=10.3.0 \
HIPCXX="$(hipconfig -l)/clang" \
HIP_PATH="$(hipconfig -R)" \
HIP_DEVICE_LIB_PATH="$(find "$HIP_PATH" -type f -name oclc_abi_version_400.bc -printf "%h\n" | head -n 1)" \
cmake -S . -B build-hephaestion-docker \
  -DGGML_HIP=ON \
  -DGPU_TARGETS=gfx1030 \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build-hephaestion-docker --config Release -- -j"$(nproc)"
```

Build log:
- `/home/local/Projects/THOTH/logs/hephaestion/20260401T212234_llama-turboquant_build.log`

---

## Test 1: Bonsai 1-bit Smoke

```bash
build-hephaestion-docker/bin/llama-cli \
  --model /workspace/models/registry/PrismML/Bonsai-1.7B-gguf/Bonsai-1.7B.gguf \
  --n-gpu-layers 99 \
  --ctx-size 512 \
  --single-turn \
  -n 24 \
  -p "Write a short Python quicksort function."
```

### Result
- ✅ Success
- The prior tensor-offset failure is gone
- The rebuilt binary generated coherent output on GPU

Log:
- `/home/local/Projects/THOTH/logs/hephaestion/20260401T212541_bonsai1.7b_q1_smoke.log`

---

## Test 2: OpenCoder Q4 Draft-Model Speculation

```bash
build-hephaestion-docker/bin/llama-cli \
  --model /workspace/models/registry/QuantFactory/OpenCoder-8B-Instruct-GGUF/OpenCoder-8B-Instruct.Q4_K_M.gguf \
  --model-draft /workspace/models/registry/QuantFactory/OpenCoder-1.5B-Instruct-GGUF/OpenCoder-1.5B-Instruct.Q4_K_M.gguf \
  --n-gpu-layers 99 \
  --gpu-layers-draft 99 \
  --ctx-size 1024 \
  --single-turn \
  -n 32 \
  -p "Write a Python quicksort function with a short docstring."
```

### Result
- ✅ Success
- Coherent output
- Both models loaded on GPU simultaneously

### Observed Metrics
- Prompt: `390.1 t/s`
- Generation: `50.6 t/s`
- Total wall time: `3.01s`

Log:
- `/home/local/Projects/THOTH/logs/hephaestion/20260401T212631_opencoder_q4_speculative.log`

---

## Test 3: OpenCoder Q4 Draft-Model Speculation + `tq3_0` V-Cache

```bash
build-hephaestion-docker/bin/llama-cli \
  --model /workspace/models/registry/QuantFactory/OpenCoder-8B-Instruct-GGUF/OpenCoder-8B-Instruct.Q4_K_M.gguf \
  --model-draft /workspace/models/registry/QuantFactory/OpenCoder-1.5B-Instruct-GGUF/OpenCoder-1.5B-Instruct.Q4_K_M.gguf \
  --n-gpu-layers 99 \
  --gpu-layers-draft 99 \
  --ctx-size 1024 \
  --flash-attn on \
  --cache-type-v tq3_0 \
  --cache-type-v-draft tq3_0 \
  --single-turn \
  -n 32 \
  -p "Write a Python quicksort function with a short docstring."
```

### Result
- ✅ Success
- Coherent output
- Quantized V-cache path works in speculative mode on RX 6700 XT

### Observed Metrics
- Prompt: `267.9 t/s`
- Generation: `37.9 t/s`
- Total wall time: `3.33s`

Log:
- `/home/local/Projects/THOTH/logs/hephaestion/20260401T212715_opencoder_q4_speculative_tq3v_fa.log`

---

## Failure Mode Captured

This configuration is invalid:

```bash
--cache-type-v tq3_0 --cache-type-v-draft tq3_0
```

without:

```bash
--flash-attn on
```

### Observed Behavior
- The binary emits the correct validation error:
  - `quantized V cache was requested, but this requires Flash Attention`
- Before the fix, `llama-cli` then segfaulted instead of exiting cleanly

Log:
- `/home/local/Projects/THOTH/logs/hephaestion/20260401T212652_opencoder_q4_speculative_tq3v.log`

### Fix Applied

Patched:

- `/home/local/Projects/THOTH/forks/llama-turboquant/tools/server/server-context.cpp`

Change:
- added a null-context guard after `common_init_from_params()` in `server_context::load_model()`
- this prevents dereferencing `ctx` when model load succeeds but context creation fails

Patch artifact:
- `/home/local/Projects/THOTH/patches/hephaestion/20260401T213541_llama-turboquant_null-context-guard.patch`

Validation after fix:
- reran the same invalid config
- result: clean failure with exit status `1`
- no segmentation fault

Log:
- `/home/local/Projects/THOTH/logs/hephaestion/20260401T213541_opencoder_q4_speculative_tq3v_invalid_fixed.log`

---

## Status
- [x] HIP rebuild from live THOTH source succeeds in Docker
- [x] Bonsai 1-bit GGUF works on GPU
- [x] OpenCoder draft-model speculative decoding works on GPU
- [x] OpenCoder draft-model speculative decoding works with `tq3_0` V-cache when Flash Attention is enabled
- [x] `llama-server` serves the same OpenCoder speculative + `tq3_0` V-cache configuration successfully
- [x] Invalid `tq3_0` V-cache path now fails cleanly after emitting the correct error
- [ ] No first-class `EAGLE3` mode exists in this binary
- [ ] Next step is SGLang; llama-side work is complete for proof-of-life but not a true EAGLE target

---

## Server Smoke

Validated server command:

```bash
build-hephaestion-docker/bin/llama-server \
  --host 127.0.0.1 \
  --port 18080 \
  --model /workspace/models/registry/QuantFactory/OpenCoder-8B-Instruct-GGUF/OpenCoder-8B-Instruct.Q4_K_M.gguf \
  --model-draft /workspace/models/registry/QuantFactory/OpenCoder-1.5B-Instruct-GGUF/OpenCoder-1.5B-Instruct.Q4_K_M.gguf \
  --n-gpu-layers 99 \
  --gpu-layers-draft 99 \
  --ctx-size 1024 \
  --flash-attn on \
  --cache-type-v tq3_0 \
  --cache-type-v-draft tq3_0
```

Health check:

```bash
curl http://127.0.0.1:18080/health
```

Response:

```json
{"status":"ok"}
```

Completion smoke:
- POST `/completion` returned HTTP 200
- response included speculative stats:
  - `draft_n: 17`
  - `draft_n_accepted: 10`
- server log reported:
  - `draft acceptance rate = 0.58824`

Server log:
- `/home/local/Projects/THOTH/logs/hephaestion/20260401T212928_opencoder_q4_server_tq3v_fa.log`
