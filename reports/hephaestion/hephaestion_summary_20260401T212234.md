# Hephaestion Run Summary

## THOTH Context
Docker-first validation run inside the existing `thoth` container against the live-mounted THOTH fork. The stale image binary at `/usr/local/bin/llama-cli` was bypassed in favor of a fresh source rebuild from `forks/llama-turboquant`.

## Attack-Order Position
1. `forks/llama-turboquant`

## Target Project
`/home/local/Projects/THOTH/forks/llama-turboquant`

## Donor Repos Consulted
- `forks/llama-turboquant`
- `forks/llama.cpp-1-bit-turbo` as prior 1-bit compatibility context only

## Environment Summary
- Host GPU: RX 6700 XT
- Compatibility mode: `HSA_OVERRIDE_GFX_VERSION=10.3.0`
- Container: `thoth`
- Python: `3.12.3`
- ROCm: `7.2.0`
- Build target: `gfx1030`

## Docker Build Context
- Container mounts expose THOTH at `/workspace/thoth`
- Rebuilt binary path:
  - `/workspace/thoth/forks/llama-turboquant/build-hephaestion-docker/bin/llama-cli`
  - `/workspace/thoth/forks/llama-turboquant/build-hephaestion-docker/bin/llama-server`
- Build log:
  - `/home/local/Projects/THOTH/logs/hephaestion/20260401T212234_llama-turboquant_build.log`

## Architecture Goal
Prove that gfx1031 can run as gfx1030 inside Docker with:
- Bonsai 1-bit GGUF compatibility
- OpenCoder draft-model speculative decoding
- OpenCoder draft-model speculative decoding plus TurboQuant `tq3_0` KV usage

## Selected Improvement
1. Rebuild `llama-turboquant` from live THOTH source with HIP/gfx1030 inside Docker so the runtime includes the PrismML Q1 remap and current speculative-decoding support.
2. Patch `server_context::load_model()` so a null context from `common_init_from_params()` fails cleanly instead of dereferencing `ctx` and segfaulting.

## Files Modified
- `/home/local/Projects/THOTH/forks/llama-turboquant/tools/server/server-context.cpp`

Artifacts added:
- `/home/local/Projects/THOTH/reports/hephaestion/hephaestion_summary_20260401T212234.md`
- `/home/local/Projects/THOTH/manifests/llama-turboquant/20260401T212234.yaml`
- `/home/local/Projects/THOTH/docs/engines/llama-turboquant/eagle-speculative-results-run002-2026-04-01.md`
- `/home/local/Projects/THOTH/patches/hephaestion/20260401T213541_llama-turboquant_null-context-guard.patch`

## Compatibility Strategy Used
- `HSA_OVERRIDE_GFX_VERSION=10.3.0`
- HIP build with `HIPCXX="$(hipconfig -l)/clang"`
- `HIP_PATH="$(hipconfig -R)"`
- `HIP_DEVICE_LIB_PATH` resolved from ROCm bitcode directory
- `-DGGML_HIP=ON`
- `-DGPU_TARGETS=gfx1030`

## Build Iterations Attempted
1. Failed configure using `-G Ninja`
   - blocker: `Ninja` missing, compilers not selected
2. Successful configure/build using documented HIP invocation without Ninja
3. Rebuilt `server-context`, `llama-cli`, and `llama-server` after adding the null-context guard

## Validation Results
### Tier 1-3
- Configure succeeded
- Compile succeeded
- `llama-cli` and `llama-server` artifacts were produced

### Tier 4-6
- Bonsai 1-bit smoke succeeded on GPU
  - model: `PrismML/Bonsai-1.7B.gguf`
  - log: `/home/local/Projects/THOTH/logs/hephaestion/20260401T212541_bonsai1.7b_q1_smoke.log`
  - result: Q1 remap path is live; previous tensor-offset failure is gone
- OpenCoder draft-model speculative smoke succeeded on GPU
  - main: `OpenCoder-8B-Instruct.Q4_K_M.gguf`
  - draft: `OpenCoder-1.5B-Instruct.Q4_K_M.gguf`
  - log: `/home/local/Projects/THOTH/logs/hephaestion/20260401T212631_opencoder_q4_speculative.log`
  - result: coherent output, dual-model speculative path works
- OpenCoder draft-model speculative plus `tq3_0` V-cache succeeded on GPU
  - same main/draft pair
  - required `--flash-attn on`
  - log: `/home/local/Projects/THOTH/logs/hephaestion/20260401T212715_opencoder_q4_speculative_tq3v_fa.log`
  - result: coherent output, quantized V-cache path works in speculative mode
- OpenCoder draft-model speculative plus `tq3_0` V-cache succeeded via `llama-server`
  - `/health` returned `{"status":"ok"}`
  - `/completion` returned HTTP 200 with speculative stats
  - log: `/home/local/Projects/THOTH/logs/hephaestion/20260401T212928_opencoder_q4_server_tq3v_fa.log`
  - result: server path works with the same validated OpenCoder configuration

### Failure Case Captured
- Invalid run:
  - `--cache-type-v tq3_0 --cache-type-v-draft tq3_0` without `--flash-attn on`
  - log: `/home/local/Projects/THOTH/logs/hephaestion/20260401T212652_opencoder_q4_speculative_tq3v.log`
- observed behavior:
  - correct error: `quantized V cache was requested, but this requires Flash Attention`
  - incorrect follow-on behavior: process exited with `Segmentation fault`

### Regression Check After Patch
- Re-ran the same invalid configuration after patching `tools/server/server-context.cpp`
- new log: `/home/local/Projects/THOTH/logs/hephaestion/20260401T213541_opencoder_q4_speculative_tq3v_invalid_fixed.log`
- new behavior:
  - preserves the correct validation error
  - exits cleanly with status `1`
  - no segmentation fault

## Current Status
- `llama-turboquant` HIP Docker build is healthy on gfx1030 compatibility mode
- Bonsai 1-bit support is confirmed working on the rebuilt binary
- OpenCoder speculative decoding is confirmed working
- OpenCoder speculative decoding with quantized `tq3_0` V-cache is confirmed working when Flash Attention is enabled
- The same quantized speculative configuration is confirmed through `llama-server`
- The invalid quantized-V speculative config now fails cleanly instead of crashing

## Remaining Blockers
- No first-class `EAGLE3` mode exists in this binary; this is draft-model speculative decoding via `--model-draft`
- The first malformed `/completion` request in the server log was a client-side shell quoting mistake, not a server bug
- The next substantive step is the planned SGLang pivot; llama-side work should stop at draft-model speculation and 1-bit compatibility

## Next Best Improvement
Move to SGLang and validate true EAGLE-capable speculative decoding there, using the llama-side results from this run only as hardware/backend proof-of-life for gfx1030 compatibility, OpenCoder draft-model speculation, and Bonsai 1-bit support.
